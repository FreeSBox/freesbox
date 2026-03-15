AddCSLuaFile("resources/vote/petition_browser.html.lua")
AddCSLuaFile("resources/vote/petition_editor.html.lua")
AddCSLuaFile("resources/vote/petition_viewer.html.lua")

local petition_no_limit = CreateConVar("petition_no_limit", "0", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Remove the limit of petitions per day")

--#region NetMsg declarations

-- `client -> server & server -> client`. Creates new petition on the server, or recieves petition on the client.
util.AddNetworkString("petition_transmit")

-- `server -> client`. Confirm that the petition added with `petition_transmit` was accepted on the server.
util.AddNetworkString("petition_accepted")

-- `server -> client`. Tells the client that it should delete this petition from the cache.
util.AddNetworkString("petition_removed")

-- `client -> server`. The client wants to know the children of this petition.
util.AddNetworkString("petition_children_request")

-- `server -> client`. Petition comment ids.
util.AddNetworkString("petition_children_responce")

-- `client -> server`. The client wants to know what petitions are available.
util.AddNetworkString("petition_list_request")

-- `server -> client`. The petitions that are available.
util.AddNetworkString("petition_list_responce")

-- `client -> server`. The client wants to get `petition_transmit`s with petitions in this array.
util.AddNetworkString("petition_request")

-- `client -> server` The client wants to know how the likes/dislikes of a given petition.
util.AddNetworkString("petition_votes_request")

-- `server -> client` The votes on the requested petition.
util.AddNetworkString("petition_votes_responce")

-- `client -> server` The client is voting on a petition.
util.AddNetworkString("petition_vote_on")

--#endregion NetMsg declarations

--#region SQL

-- SQL Error reporting.
-- https://wiki.facepunch.com/gmod/sql.LastError#example
sql.m_strError = nil -- This is required to invoke __newindex
setmetatable( sql, { __newindex = function( table, k, v )
	if ( k == "m_strError" and v and #v > 0 ) then
		print("[SQL Error] " .. v )
	end
end } )

sql.Query([[CREATE TABLE IF NOT EXISTS fsb_petitions (
	id INTEGER PRIMARY KEY,
	name TEXT,
	description TEXT NOT NULL,
	creation_time BIGINT NOT NULL,
	expire_time BIGINT,
	author_name TEXT NOT NULL,
	author_steamid BIGINT NOT NULL,
	parent INTEGER,
	hidden INTEGER
)]])

sql.Query([[CREATE TABLE IF NOT EXISTS fsb_votes (
	id INTEGER PRIMARY KEY,
	petition_id INTEGER NOT NULL,
	creation_time BIGINT NOT NULL,
	vote_status INTEGER NOT NULL,
	author_steamid BIGINT NOT NULL
)]])

--#endregion SQL

---@param petition_id integer
---@param steamid64 string?
---@return integer num_likes
---@return integer num_dislikes
---@return integer vote_status eVoteStatus for the steamid64 given, will return eVoteStatus.NOT_VOTED if steamid64 is not given
local function getVotesFromIndex(petition_id, steamid64)
	local num_likes = 0
	local num_dislikes = 0

	local results = sql.QueryTyped("SELECT vote_status, author_steamid FROM fsb_votes WHERE petition_id = ?", petition_id)
	assert(results ~= false, "The SQL Query is broken in 'getVotesFromIndex'")

	local our_vote_status = eVoteStatus.NOT_VOTED

	---@diagnostic disable-next-line: param-type-mismatch
	for index, vote in ipairs(results) do
		if vote.vote_status == eVoteStatus.LIKE then
			num_likes = num_likes + 1
		elseif vote.vote_status == eVoteStatus.DISLIKE then
			num_dislikes = num_dislikes + 1
		end

		if steamid64 ~= nil and vote.author_steamid == steamid64 then
			our_vote_status = vote.vote_status
		end
	end

	return num_likes, num_dislikes, our_vote_status
end

---@param petitions table<integer, petition> Array of petitions that will have their vote info updated.
---@param steamid64 string? SteamID is used to set the vote status.
local function addVoteInfoToPetitions(petitions, steamid64)
	local num_petitions = #petitions
	assert(num_petitions <= PETITION_MAX_PETITIONS_PER_REQUEST, "Too many petitions requested")

	local petition_ids = {}
	for _, petition in ipairs(petitions) do
		petition_ids[#petition_ids+1] = petition.index
	end

	local placeholders = string.rep("?,", num_petitions-1) .. "?"
	local query = string.format("SELECT vote_status, author_steamid, petition_id FROM fsb_votes WHERE petition_id IN (%s)", placeholders)
	local results = sql.QueryTyped(query, unpack(petition_ids))
	assert(results ~= false, "The SQL Query is broken in 'addVoteInfoToPetitions'")

	local petition_map = {}
	for _, petition in ipairs(petitions) do
		petition_map[petition.index] = petition

		petition.num_likes = petition.num_likes or 0
		petition.num_dislikes = petition.num_dislikes or 0
		petition.our_vote_status = eVoteStatus.NOT_VOTED
	end
	---@diagnostic disable-next-line: param-type-mismatch
	for _, vote in ipairs(results) do
		local petition =  petition_map[vote.petition_id]

		if vote.vote_status == eVoteStatus.LIKE then
			petition.num_likes = petition.num_likes + 1
		elseif vote.vote_status == eVoteStatus.DISLIKE then
			petition.num_dislikes = petition.num_dislikes + 1
		end

		if steamid64 ~= nil and vote.author_steamid == steamid64 then
			petition.our_vote_status = vote.vote_status
		end
	end
end

---Converts the data you get from sql queries into the petition class
---@param data table
---@return petition
local function sqlDataToPetition(data)
	return {
		index = data.id,
		name = data.name,
		description = data.description,
		author_name = data.author_name,
		author_steamid = data.author_steamid,
		creation_time = data.creation_time,
		expire_time = data.expire_time,
		parent = data.parent,
		hidden = data.hidden
	}
end

---@param petition_ids table Array of petition IDs
---@param ply Player?
---@return table<integer, petition> petitions Will be empty if no petitions were found.
local function getPetitionsFromIndexes(petition_ids, ply)
	local num_ids = #petition_ids
	assert(num_ids <= PETITION_MAX_PETITIONS_PER_REQUEST, "Too many petitions requested")

	local placeholders = string.rep("?,", num_ids-1) .. "?"
	local query = string.format("SELECT * FROM fsb_petitions WHERE id IN (%s)", placeholders)
	local results = sql.QueryTyped(query, unpack(petition_ids))
	assert(results ~= false, "The SQL Query is broken in 'getPetitionsFromIndexes'")

	local result = {}
	---@diagnostic disable-next-line: param-type-mismatch
	for _, sql_petition in ipairs(results) do
		result[#result+1] = sqlDataToPetition(sql_petition)
	end

	addVoteInfoToPetitions(result, ply and ply:OwnerSteamID64())

	return result
end

local words =
{
	"excusable",
	"vibrator",
	"mattocks",
	"tapered",
	"Tolstoy's",
	"bristlier",
	"acrylamide",
	"documents",
	"maisonettes",
	"evergreen's",
	"terrifyingly",
	"inappropriately",
	"enamored",
	"enlargements",
	"unprejudiced",
	"diocesan's",
	"skeleton",
	"dropouts",
	"eugenically",
	"Sylvester's",
	"oxford",
	"misspeaking",
	"pliable",
	"hairdressers",
	"ovule's",
	"epaulet",
	"evaluations",
	"rheostat's",
	"entwined",
	"sectary",
	"dryer",
	"soullessness",
	"rodent",
	"telegrapher",
	"particles",
	"thieves",
	"regexps",
	"titanium's",
	"wiper",
	"sanitarium's",
	"dimensional",
	"etymologist's",
	"Eumenides",
	"roarers",
	"outbidding",
	"stallholders",
	"arose",
	"criers",
	"disproof's",
	"skit's",
	"dawned",
	"serviceability",
	"surfer's",
	"bleats",
	"farmers",
	"modality",
	"jurisdiction's",
	"recessive's",
	"commence",
	"Utica's",
	"radar's",
	"fronds",
	"Shirley",
	"Condorcet",
	"colophon",
	"colliding",
	"subsidy",
	"Cambodia",
	"chairing",
	"evidence's",
	"dyke",
	"punts",
	"duty's",
	"magpie's",
	"stargazer's",
	"kine",
	"piebalds",
	"forevermore",
	"humanities's",
	"turboprop's",
	"tossers",
	"prematurely",
	"Getty",
	"shay's",
	"Susanne",
	"duplicating",
	"calculated",
	"blend",
	"squatter's",
	"fairgrounds",
	"butty",
	"bowlegged",
	"status's",
	"blowy",
	"carpetbagging",
	"bondwoman",
	"enshrouds",
	"runny",
	"gumballs",
	"Katheryn",
	"remain",
	"adrenal's",
	"beryllium",
	"manacled",
	"limit's",
	"doeskins",
	"environmentalist's",
	"participle",
	"whitey",
	"mixing",
	"pimpled",
	"signore",
	"swapped",
	"knottiest",
	"rosaries",
	"cardiogram",
	"principal's",
	"radarscope's",
	"backpackers",
	"Walgreens",
	"floodwater's",
	"pd",
	"harpy",
	"Steuben",
	"spook's",
	"cocoon's",
	"critiques",
	"Silva's",
	"Guallatiri",
	"Midwestern",
	"pageant's",
	"Witwatersrand",
	"purged",
	"crackhead",
	"George",
	"deathlessly",
	"bob",
	"shunning",
	"Onsager's",
	"stormy",
	"Hafiz",
	"join's",
	"Singapore's",
	"hubcap's",
	"myrtle's",
	"fuss",
	"serendipity's",
	"preserving",
	"mistake",
	"cheered",
	"Stoic's",
	"Brunelleschi's",
	"Amherst",
	"whiskery",
	"Owens",
	"payphones",
	"forenames",
	"paralyze",
	"bounteousness's",
	"praetors",
	"lemma",
	"putrefying",
	"microwaveable",
	"fa",
	"repaints",
	"heatstroke",
	"nabbed",
	"iodine",
	"PyTorch's",
	"pinprick",
	"gratis",
	"razes",
	"dissect",
	"lumbering",
	"polygamy",
	"schoolteacher",
	"striding",
	"dongs",
	"evangelical's",
	"representation",
	"melodiously",
	"copperhead",
	"mag's",
	"insulating",
	"pollards",
	"agnosticism",
	"encourage",
	"auxin's",
	"walking",
	"lodger's",
	"instigates",
	"Sigmund",
	"berrylike",
	"antibacterials",
	"quotability's",
	"McLaughlin's",
	"napalm's",
	"asexually",
	"answerable",
	"Scorsese",
	"runoffs",
	"prude's",
	"husker",
	"twins",
	"concertized",
	"catharsis's",
	"Alisha's",
	"digesting",
	"scrummed",
	"Coronado's",
	"Janus",
	"malevolence",
	"luring",
	"oppressor's",
	"schemer's",
	"Min",
	"redecorating",
	"blackball",
	"Indore",
	"reinstall",
	"swoops",
	"pillowslip",
	"interpolating",
	"foxhound's",
	"inhibiting",
	"Ziploc's",
	"furnaces",
	"unsegregated",
	"schnozzle's",
	"O'Rourke",
	"reader's",
	"rooftops",
	"dillydallied",
	"saunter's",
	"jackpot's",
	"invidiousness",
	"hashtag's",
	"candlestick",
	"zigzag",
	"curliness's",
	"ligneous",
	"effendi's",
	"bed",
	"regulars",
	"Cpl",
	"exerciser",
	"snappily",
	"artiest",
	"overcautious",
	"cods",
	"informer's",
	"Yakima's",
	"onset's",
	"immersion's",
	"godly",
	"phrasal",
	"inductively",
	"clothe",
	"Galilean",
	"breakage's",
	"fidgets",
	"outfielder's",
	"fogies",
	"flagellants",
	"fidelity",
	"diktats",
	"backhandedly",
	"Sahara",
	"incandescence",
	"hes",
	"heelless",
	"bypass",
	"demimondaines",
	"preserve's",
	"Donald",
	"underrate",
	"overpaying",
	"Marses",
	"calaboose",
	"torte",
	"cross",
	"anime's",
	"playhouse",
	"carriageway",
	"Gustavo",
	"industrialism's",
	"petrochemical",
	"Snow's",
	"embarrasses",
	"Holly's",
	"huzzahs",
	"NoDoz",
	"Shelia",
	"ammo's",
	"diplopia",
	"questioned",
	"orient's",
	"causality",
	"wackiest",
	"radiators",
	"chief's",
	"Chrysostom",
	"facecloth",
	"dragged",
	"proselytizes",
	"obtrude",
	"rowdiest",
	"elongating",
	"Brenner",
	"Jacob",
	"procession's",
	"prisoner",
	"phototropic",
	"McGovern",
	"dishtowel",
	"beanie's",
	"dyslexic",
	"Tammany",
	"cagiest",
	"pinkness's",
	"liquid",
	"derogates",
	"selector",
	"discredited",
	"shushes",
	"jeroboam",
	"Samuelson's",
	"houris",
	"repeating",
	"inbuilt",
	"dice",
	"godliness",
	"decrees",
	"Arminius",
	"soc",
	"Seagram's",
	"unpredictably",
	"checkoff",
	"teleworking",
	"disown",
	"slayers",
	"fullness's",
	"miscellanies",
	"talkiest",
	"accessioned",
	"Shepard's",
	"polestar's",
	"reforesting",
	"Lyndon",
	"Gentry",
	"cloudburst",
	"introvert's",
	"Mancunians",
	"muumuus",
	"tummies",
	"reinflated",
	"canines",
	"Chesterton's",
	"ague's",
	"Ha",
	"storeroom",
	"dithered",
	"lusciously",
	"Mackinac's",
	"materialization",
	"exceptionable",
	"gentlefolk",
	"threescore's",
	"rare",
	"doorplate",
	"Monteverdi's",
	"preparing",
	"builder",
	"surgeon's",
	"adder",
	"quays",
	"paladin's",
	"disappoint",
	"gangrenes",
	"intertwines",
	"tortes",
	"Ala",
	"Goa",
	"ruddiness",
	"fluoresces",
	"Mohammedanism's",
	"agings",
	"barter",
	"vacate",
	"hassling",
	"Alnilam's",
	"fingerboards",
	"vagaries",
	"candidacies",
	"picketers",
	"speeder's",
	"Poland",
	"psychosis",
	"omnipotent",
	"reefed",
	"woodblock's",
	"closeup's",
	"incoherence's",
	"curtaining",
	"hatting",
	"lollygagged",
	"muscatel",
	"hounds",
	"cockatrice",
	"phylactery's",
	"SF",
	"lengthening",
	"Berlitz's",
	"Siddhartha",
	"wisecracked",
	"customizes",
	"gloried",
	"erect",
	"Zeffirelli",
	"Lora",
	"sycophant",
	"gush",
	"Andrew's",
	"teardrop's",
	"triumphalist",
	"prefect",
	"detrimentally",
	"Haley",
	"collegians",
	"pH",
	"preoccupation",
	"reoccurred",
	"warez",
	"Wilburn's",
	"Cole's",
	"elegance's",
	"ridiculed",
	"colloquies",
	"gripping",
	"Visayans",
	"papa",
	"topflight",
	"disorientated",
	"Muskegon",
	"carouse",
	"prefab",
	"Hutton's",
	"insomnia's",
	"reanalyze",
	"Ephraim",
	"instigate",
	"dolloped",
	"moonshines",
	"Jeannette",
	"Jericho's",
	"crosier's",
	"bewail",
	"cranberries",
	"creationist's",
	"smokestacks",
	"doorkeeper's",
	"maladroitness",
	"Yakima",
	"midfielders",
	"Lupus's",
	"childhood's",
	"foxglove",
	"syllabicated",
	"cryptographers",
	"militarism",
	"headstall",
	"molestation's",
	"counterpoint",
	"starred",
	"prevented",
	"voltmeters",
	"Rafael's",
	"CDs",
	"cubbyholes",
	"flicking",
	"obtainment",
	"blowhard's",
	"drill's",
	"Americans",
	"incursion",
	"marriage's",
	"madman",
	"interning",
	"Sherri",
	"iceboats",
	"remembrance",
	"go",
	"brigadiers",
	"braking",
	"crawl",
	"timetables",
	"modernity",
	"hightailing",
	"paperer",
	"egoistic",
}

local function randomWord()
	return words[math.random(#words)]
end

function FSB.GenerateRandomPetition()
	local name = randomWord() .. "_" .. randomWord() .. "_" .. randomWord()
	local description_length = math.random(1000)
	local description = randomWord()
	for i = 1, description_length do
		description = description .. " " .. randomWord()
	end

	sql.QueryTyped([[INSERT INTO fsb_petitions(
			name,
			description,
			creation_time,
			author_name,
			author_steamid,
			expire_time
		) VALUES (?, ?, ?, ?, ?, ?)
		]],
		name,
		description,
		math.random(1600000000, 1500000000),
		randomWord(),
		math.random(600000000, 999999999999),
		math.random(1600000000, 1500000000)
	)
end

---Removes the petition.
---**There is no way to undo this!**
---@param id integer
function FSB.RemovePetition(id)
	sql.QueryTyped("DELETE FROM fsb_petitions WHERE id = ?", id)
	sql.QueryTyped("DELETE FROM fsb_votes WHERE petition_id = ?", id)

	net.Start("petition_removed")
	net.WriteUInt(id, PETITION_ID_BITS)
	net.Broadcast()
end

--#region NetMsg handling
local ratelimit_table = {}
local RATELIMIT = 5
net.Receive("petition_transmit", function(len, ply)
	if not FSB.Ratelimit(ratelimit_table, ply, RATELIMIT) then
		ply:SendLocalizedMessage("ratelimit", RATELIMIT)
		return
	end

	if not ply:IsFullyAuthenticated() then
		-- We cannot verify this player's identity.
		ply:SendLocalizedMessage("vote.not_fully_authed_p")
		return
	end
	if ply:IsGhostBanned() then
		ply:SendLocalizedMessage("vote.ghostbanned")
		return
	end

	--We only read one petition on the server
	--I don't really see a point in creating MAX_PETITIONS_PER_DAY petitions with one request
	--Why would anyone want to make a script like this?
	if not net.ReadBool() then return end

	---@type petition
	---@diagnostic disable-next-line: missing-fields
	local petition = FSB.ReadOnePetition()

	local name_length = #petition.name
	if name_length > PETITION_NAME_MAX_LENGTH then
		ply:SendLocalizedMessage("vote.name_too_long", name_length, PETITION_NAME_MAX_LENGTH)
		return
	end
	if string.IsOnlyWhiteSpace(petition.name) then
		ply:SendLocalizedMessage("vote.name_cant_be_empty")
		return
	end
	if petition.description == nil or string.IsOnlyWhiteSpace(petition.description) then
		ply:SendLocalizedMessage("vote.description_cant_be_empty")
		return
	end
	local max_length = petition.parent == nil and PETITION_DESCRIPTION_MAX_LENGTH or PETITION_COMMENT_MAX_LENGTH
	if #petition.description > max_length then
		ply:SendLocalizedMessage("vote.description_too_long", #petition.description, max_length)
		return
	end

	petition.author_steamid = ply:OwnerSteamID64()

	--TODO: Add automatic calculation of how long the petition should last.
	--Or maybe not, we seem fine with 2 days of vote time.
	--Changining it now would cause more problems then it would solve.
	--While there was a petition #333 that wants petitions to pass if they reach game.MaxPlayers() likes
	--Again this would probably couse more problems then it would solve.
	local petition_expire_time

	if petition.parent == nil then
		petition_expire_time = os.time() + 60*60*24*2
		local one_day_ago = os.time() - 60*60*24
		local results = sql.QueryTyped("SELECT * FROM fsb_petitions WHERE creation_time > ? AND author_steamid = ? AND parent IS NULL", one_day_ago, petition.author_steamid)
		if #results >= MAX_PETITIONS_PER_DAY and not petition_no_limit:GetBool() then
			ply:SendLocalizedMessage("vote.too_many_created", MAX_PETITIONS_PER_DAY)
			return
		end
	end

	sql.QueryTyped([[INSERT INTO fsb_petitions(
			name,
			description,
			creation_time,
			author_name,
			author_steamid,
			expire_time,
			parent
		) VALUES (?, ?, ?, ?, ?, ?, ?)
		]],
		petition.name,
		petition.description,
		os.time(),
		ply:GetName(),
		petition.author_steamid,
		petition_expire_time,
		petition.parent
	)

	local result = sql.QueryTyped("SELECT last_insert_rowid() AS id")

	net.Start("petition_accepted")
		net.WriteUInt(result[1].id, PETITION_ID_BITS)
	net.Send(ply)

	if petition.parent == nil then
		FSB.SendLocalizedMessage("vote.new_petitions", ply:Nick(), petition.name)
	end
end)

net.Receive("petition_request", function(len, ply)
	local num_petitions = net.ReadUInt(8)
	if num_petitions > PETITION_MAX_PETITIONS_PER_REQUEST then
		ply:SendLocalizedMessage("vote.too_many_requested")
		return
	end

	local petition_ids = {}
	for i = 1, num_petitions do
		local petition_id = net.ReadUInt(PETITION_ID_BITS)
		petition_ids[i] = petition_id
	end

	local petitions = getPetitionsFromIndexes(petition_ids, ply)
	FSB.SendPetitions(petitions, ply)
end)

net.Receive("petition_children_request", function(len, ply)
	local parent_id = net.ReadUInt(PETITION_ID_BITS)
	local results = sql.QueryTyped("SELECT id FROM fsb_petitions WHERE parent = ? AND (hidden IS NULL OR hidden = 0) ORDER BY creation_time", parent_id)
	assert(results ~= false, "The SQL Query is broken in 'petition_children_request' handler")

	net.Start("petition_children_responce")
		net.WriteUInt(parent_id, PETITION_ID_BITS)
		net.WriteUInt(#results, PETITION_ID_BITS)
		---@diagnostic disable-next-line: param-type-mismatch
		for _, sql_petition in ipairs(results) do
			net.WriteUInt(sql_petition["id"], PETITION_ID_BITS)
		end
	net.Send(ply)
end)

net.Receive("petition_list_request", function(len, ply)
	local results = sql.QueryTyped("SELECT id FROM fsb_petitions WHERE parent IS NULL AND (hidden IS NULL OR hidden = 0) ORDER BY creation_time")
	assert(results ~= false, "The SQL Query is broken in 'petition_list_request' handler")

	net.Start("petition_list_responce")
		---@diagnostic disable-next-line: param-type-mismatch
		local num_results = #results
		net.WriteUInt(num_results, PETITION_ID_BITS)
		for i = 1, num_results do
			net.WriteUInt(results[i].id, PETITION_ID_BITS)
		end
	net.Send(ply)
end)

local function sendVoteResponce(petition_id, ply)
	local num_likes, num_dislikes = getVotesFromIndex(petition_id)

	local players = ply and {ply} or player.GetAll()
	for index, ply in ipairs(players) do
		local results = sql.QueryTyped("SELECT vote_status FROM fsb_votes WHERE petition_id = ? AND author_steamid = ?", petition_id, ply:OwnerSteamID64())
		assert(results ~= false, "The SQL Query is broken in 'sendVoteResponce'")
		local vote_status = eVoteStatus.NOT_VOTED
		if #results == 1 then
			vote_status = results[1].vote_status
		end

		net.Start("petition_votes_responce")
			net.WriteUInt(petition_id, PETITION_ID_BITS)
			net.WriteUInt(num_likes, PETITION_VOTE_BITS)
			net.WriteUInt(num_dislikes, PETITION_VOTE_BITS)
			net.WriteUInt(vote_status, 2)
		net.Send(ply)
	end
end

net.Receive("petition_votes_request", function(len, ply)
	local petition_id = net.ReadUInt(PETITION_ID_BITS)
	sendVoteResponce(petition_id, ply)
end)

net.Receive("petition_vote_on", function(len, ply)
	if not ply:IsFullyAuthenticated() then
		-- We cannot verify this players' identity.
		ply:SendLocalizedMessage("vote.not_fully_authed_v")
		return
	end
	if ply:IsGhostBanned() then
		ply:SendLocalizedMessage("vote.ghostbanned")
		return
	end

	local player_id = ply:OwnerSteamID64()
	local petition_id = net.ReadUInt(PETITION_ID_BITS)
	local dislike = net.ReadBool()

	local vote_status_ = dislike and eVoteStatus.DISLIKE or eVoteStatus.LIKE

	local results = sql.QueryTyped("SELECT id FROM fsb_petitions WHERE id = ? AND author_steamid = ?", petition_id, player_id)
	if results == false then return end
	if #results > 0 then
		ply:SendLocalizedMessage("vote.vote_on_self")
		return
	end

	local results = sql.QueryTyped("SELECT expire_time FROM fsb_petitions WHERE id = ?", petition_id)
	if results == false then return end
	if #results == 0 then
		ply:SendLocalizedMessage("vote.invalid_vote", petition_id)
		return
	end
	if results[1].expire_time < os.time() then
		ply:SendLocalizedMessage("vote.expired_vote")
		return
	end

	local results = sql.QueryTyped("SELECT vote_status FROM fsb_votes WHERE petition_id = ? AND author_steamid = ?", petition_id, player_id)
	if results == false then return end
	if #results >= 1 then
		if results[1].vote_status == vote_status_ then
			sql.QueryTyped("DELETE FROM fsb_votes WHERE petition_id = ? AND author_steamid = ?", petition_id, player_id)
		else
			sql.QueryTyped("UPDATE fsb_votes SET vote_status = ? WHERE petition_id = ? AND author_steamid = ?", vote_status_, petition_id, player_id)
		end

		sendVoteResponce(petition_id, nil)
		return
	end

	sql.QueryTyped([[INSERT INTO fsb_votes(
			petition_id,
			creation_time,
			vote_status,
			author_steamid
		) VALUES (?, ?, ?, ?)]],
		petition_id,
		os.time(),
		vote_status_,
		player_id
	)

	sendVoteResponce(petition_id, nil)
end)

--#endregion
