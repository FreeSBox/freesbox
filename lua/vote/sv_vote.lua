AddCSLuaFile("resources/vote/petition_browser.html.lua")
AddCSLuaFile("resources/vote/petition_editor.html.lua")
AddCSLuaFile("resources/vote/petition_viewer.html.lua")

local petition_no_limit = CreateConVar("petition_no_limit", "0", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Remove the limit of petitions per day")

--#region NetMsg declarations

-- `client -> server & server -> client`. Creates new petition on the server, or recieves petition on the client.
util.AddNetworkString("petition_transmit")

-- `server -> client`. Confirm that the petition added with `petition_transmit` was accepted on the server.
util.AddNetworkString("petition_accepted")

-- `client -> server`. The client whats to know what petitions are available.
util.AddNetworkString("petition_list_request")

-- `server -> client`. The petitions that are available.
util.AddNetworkString("petition_list_responce")

-- `client -> server`. The client whats to get `petition_transmit`s with petitions in this array.
util.AddNetworkString("petition_request")

-- `client -> server` The client whats to know how the likes/dislikes of a given petition.
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

sql.Query([[CREATE TABLE IF NOT EXISTS petitions (
	id INTEGER PRIMARY KEY,
	name TEXT,
	description TEXT,
	creation_time BIGINT,
	expire_time BIGINT,
	author_name TEXT,
	author_steamid BIGINT
)]])

sql.Query([[CREATE TABLE IF NOT EXISTS votes (
	id INTEGER PRIMARY KEY,
	petition_id INTEGER,
	creation_time BIGINT,
	vote_status INTEGER,
	author_steamid BIGINT
)]])

--#endregion SQL

---@param petition_id integer
---@return integer num_likes
---@return integer num_dislikes
local function getVotesFromIndex(petition_id)
	local num_likes = 0
	local num_dislikes = 0

	local results = sql.QueryTyped("SELECT * FROM votes WHERE petition_id = ?", petition_id)
	assert(results ~= false, "The SQL Query is broken in 'countSQLVotes'")

	---@diagnostic disable-next-line: param-type-mismatch
	for index, value in ipairs(results) do
		if value.vote_status == eVoteStatus.LIKE then
			num_likes = num_likes + 1
		elseif value.vote_status == eVoteStatus.DISLIKE then
			num_dislikes = num_dislikes + 1
		end
	end

	return num_likes, num_dislikes
end

---@param petition_id integer
---@param ply Player?
---@return petition? -- nil if the petiotion doesn't exist.
local function getPetitionFromIndex(petition_id, ply)
	local results = sql.QueryTyped("SELECT * FROM petitions WHERE id = ?", petition_id)
	assert(results ~= false, "The SQL Query is broken in 'getPetitionFromIndex'")
	if #results ~= 1 then return nil end
	local result = results[1]

	local num_likes, num_dislikes = getVotesFromIndex(petition_id)

	local vote_status = eVoteStatus.NOT_VOTED
	if ply then
		local results = sql.QueryTyped("SELECT vote_status FROM votes WHERE petition_id = ? AND author_steamid = ?", petition_id, ply:OwnerSteamID64())
		assert(results ~= false, "The SQL Query is broken in 'getPetitionFromIndex'")
		if #results == 1 then
			vote_status = results[1].vote_status
		end
	end

	return {
		index = petition_id,
		name = result.name,
		description = result.description,
		num_likes = num_likes,
		num_dislikes = num_dislikes,
		author_name = result.author_name,
		author_steamid = result.author_steamid,
		creation_time = result.creation_time,
		expire_time = result.expire_time,
		our_vote_status = vote_status
	}
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

	sql.QueryTyped([[INSERT INTO petitions(
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

--#region NetMsg handling
net.Receive("petition_transmit", function(len, ply)
	if not ply:IsFullyAuthenticated() then
		-- We cannot verify this player's identity.
		ply:PrintMessage(HUD_PRINTTALK, "You are not fully authenticated, petition discarded.")
		return
	end
	---@type petition
	---@diagnostic disable-next-line: missing-fields
	local petition = {}

	if net.ReadBool() then -- include_petition_id
		net.ReadUInt(PETITION_ID_BITS) -- index
	end
	petition.name = net.ReadString()
	local name_length = #petition.name
	if name_length > PETITION_NAME_MAX_LENGTH then
		ply:PrintMessage(HUD_PRINTTALK, "Your name is longer then the maximum allowed length (" .. tostring(name_length) .. "/" .. tostring(PETITION_NAME_MAX_LENGTH) .. ").")
		return
	end
	if string.IsOnlyWhiteSpace(petition.name) then
		ply:PrintMessage(HUD_PRINTTALK, "Name cannot be empty.")
		return
	end

	if net.ReadBool() then -- include_votes
		net.ReadUInt(PETITION_VOTE_BITS) -- num_likes
		net.ReadUInt(PETITION_VOTE_BITS) -- num_dislikes
		net.ReadUInt(2) -- vote_status
	end

	if net.ReadBool() then -- include_author_info
		net.ReadString() -- author_name
		net.ReadString() -- author_steamid
	end

	if net.ReadBool() then -- include_time_info
		net.ReadUInt(32) -- creation_time
		net.ReadUInt(32) -- expire_time
	end

	local description_length = net.ReadUInt(19)
	local description_compressed = net.ReadData(description_length)
	---@diagnostic disable-next-line: assign-type-mismatch
	petition.description = util.Decompress(description_compressed)
	if petition.description == nil or #petition.description > PETITION_DESCRIPTION_MAX_LENGTH then
		ply:PrintMessage(HUD_PRINTTALK, "Your description is longer then the maximum allowed length (" .. tostring(description_length) .. "/" .. tostring(PETITION_DESCRIPTION_MAX_LENGTH) .. ").")
		return
	end
	if string.IsOnlyWhiteSpace(petition.description) then
		ply:PrintMessage(HUD_PRINTTALK, "Description cannot be empty.")
		return
	end

	petition.author_steamid = ply:OwnerSteamID64()

	--TODO: Add automatic calculation of how long the petition should last.
	local petition_expire_time = os.time() + 60*60*24*2

	local one_day_ago = os.time() - 60*60*24
	local results = sql.QueryTyped("SELECT * FROM petitions WHERE creation_time > ? AND author_steamid = ?", one_day_ago, petition.author_steamid)
	if #results >= MAX_PETITIONS_PER_DAY and not petition_no_limit:GetBool() then
		ply:PrintMessage(HUD_PRINTTALK, "You can only create " .. MAX_PETITIONS_PER_DAY .. " petitions per day.")
		return
	end

	sql.QueryTyped([[INSERT INTO petitions(
			name,
			description,
			creation_time,
			author_name,
			author_steamid,
			expire_time
		) VALUES (?, ?, ?, ?, ?, ?)
		]],
		petition.name,
		petition.description,
		os.time(),
		ply:GetName(),
		petition.author_steamid,
		petition_expire_time
	)

	local result = sql.QueryTyped("SELECT last_insert_rowid() AS id")

	net.Start("petition_accepted")
		net.WriteUInt(result[1].id, PETITION_ID_BITS)
	net.Send(ply)
end)

net.Receive("petition_request", function(len, ply)
	local num_petitions = net.ReadUInt(8)
	if num_petitions > PETITION_MAX_PETITIONS_PER_REQUEST then
		ply:PrintMessage(HUD_PRINTCONSOLE, "Too many petitions requested.")
		return
	end

	for i = 1, num_petitions do
		local petition_id = net.ReadUInt(PETITION_ID_BITS)
		local petition = getPetitionFromIndex(petition_id, ply)
		if petition == nil then
			ply:PrintMessage(HUD_PRINTCONSOLE, "Invalid petition '".. petition_id .. "' requested.")
			goto CONTINUE
		end
		FSB.SendPetition(petition, ply)

		::CONTINUE::
	end
end)

net.Receive("petition_list_request", function(len, ply)
	local results = sql.QueryTyped("SELECT id FROM petitions ORDER BY creation_time")
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
		local results = sql.QueryTyped("SELECT vote_status FROM votes WHERE petition_id = ? AND author_steamid = ?", petition_id, ply:OwnerSteamID64())
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
		ply:PrintMessage(HUD_PRINTTALK, "You are not fully authenticated, vote discarded.")
		return
	end

	local player_id = ply:OwnerSteamID64()
	local petition_id = net.ReadUInt(PETITION_ID_BITS)
	local dislike = net.ReadBool()

	local vote_status_ = dislike and eVoteStatus.DISLIKE or eVoteStatus.LIKE

	local results = sql.QueryTyped("SELECT id FROM petitions WHERE id = ? AND author_steamid = ?", petition_id, player_id)
	if results == false then return end
	if #results > 0 then
		ply:PrintMessage(HUD_PRINTTALK, "You cannot vote on your own petitions.")
		return
	end

	local results = sql.QueryTyped("SELECT expire_time FROM petitions WHERE id = ?", petition_id)
	if results == false then return end
	if #results == 0 then
		ply:PrintMessage(HUD_PRINTTALK, "The petition you are voting for does not exist.")
		return
	end
	if results[1].expire_time < os.time() then
		ply:PrintMessage(HUD_PRINTTALK, "You can no longer vote on this petition.")
		return
	end

	local results = sql.QueryTyped("SELECT vote_status FROM votes WHERE petition_id = ? AND author_steamid = ?", petition_id, player_id)
	if results == false then return end
	if #results >= 1 then
		if results[1].vote_status == vote_status_ then
			sql.QueryTyped("DELETE FROM votes WHERE petition_id = ? AND author_steamid = ?", petition_id, player_id)
		else
			sql.QueryTyped("UPDATE votes SET vote_status = ? WHERE petition_id = ? AND author_steamid = ?", vote_status_, petition_id, player_id)
		end

		sendVoteResponce(petition_id, nil)
		return
	end

	sql.QueryTyped([[INSERT INTO votes(
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
