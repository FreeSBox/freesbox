---@diagnostic disable: inject-field

---@type table<integer, petition>
local petitions_cache = {}

--- index, true or nil
---@type table<integer, boolean?>
local petitions_available = {}

--- index, true or nil
---@type table<integer, boolean?>
local petitions_requested = {}

--#region HTML Window

local eWindowMode = {
	Closed = 0,
	Browse = 1,
	Edit = 2,
	View = 3,
}

---@param window Panel
---@return DHTML?
local function getHTMLFromWindow(window)
	for _, v in ipairs( window:GetChildren() ) do
		if  v:GetClassName() == "HtmlPanel" then
			return v
		end
	end
	return nil
end

local function updatePetitionVotesHTML(html, petition)
	html:QueueJavascript(
		string.format(
			"updatePetitionVotes(%u, %u, %u, %u)",
			petition.index,
			petition.num_likes,
			petition.num_dislikes,
			petition.our_vote_status
		)
	)
end

---@param html DHTML
---@param petition petition
local function addPetitionToHTML(html, petition)
	html:QueueJavascript(string.format(
			"addOrUpdatePetition(%u, '%s', '%s', '%s', %u, %u, %u, %u, %u)",
			petition.index,
			string.JavascriptSafe(petition.name),
			string.JavascriptSafe(petition.description),
			string.JavascriptSafe(petition.author_name),
			petition.num_likes,
			petition.num_dislikes,
			petition.our_vote_status,
			petition.creation_time,
			petition.expire_time
		)
	)
end

local draft_name = ""
local draft_desc = ""
local function setDraftText(name, desc)
	draft_name = name
	draft_desc = desc
end
local function getDraftText()
	return draft_name, draft_desc
end

local function createPetition(name, description)
	FSB.SendPetition({
		name=name,
		description=description
	})
	setDraftText("", "")
	print("Sent new petition to server")
end

---@param petition_id integer
---@param dislike boolean
local function voteOnPetition(petition_id, dislike)
	net.Start("petition_vote_on")
		net.WriteUInt(petition_id, PETITION_ID_BITS)
		net.WriteBool(dislike)
	net.SendToServer()
end

---@param petitions table<integer, integer> Array of petition ids
local function requestPetitions(petitions)
	assert(#petitions <= PETITION_MAX_PETITIONS_PER_REQUEST, "Too many petitions requested.")

	local request = {}

	-- This is not optimal, but should be fine.
	for _, index in pairs(petitions) do
		if not petitions_requested[index] then
			request[#request+1] = index
		end
	end

	if #request == 0 then
		return
	end

	net.Start("petition_request")
		net.WriteUInt(#request, 8)
		for i = 1, #request do
			petitions_requested[request[i]] = true
			net.WriteUInt(request[i], PETITION_ID_BITS)
		end
	net.SendToServer()
end

local function requestMorePetitions()
	local tmp_available = {}
	local i = 1
	for index, _ in pairs(petitions_available) do
		tmp_available[i] = index
		i = i + 1
	end

	table.sort(tmp_available, function (a, b)
		return a > b
	end)

	local request = {}
	for i = 1, #tmp_available do
		local index = tmp_available[i]
		if petitions_cache[index] ~= nil then goto CONTITNUE end
		if #request >= PETITION_MAX_PETITIONS_PER_REQUEST then break end

		request[#request+1] = index
		::CONTITNUE::
	end

	if #request == 0 then return end

	requestPetitions(request)
end

local function closeWindow()
	VoteWindow:Remove();
	VoteWindow=nil
end

VoteWindow = VoteWindow or nil
VoteWindowState = VoteWindowState or eWindowMode.Closed

---@return DButton?
local function getCornerButton()
	if VoteWindowState == eWindowMode.Closed or VoteWindow == nil then 
		return nil
	end

	for _, value in pairs(VoteWindow:GetChildren()) do
		if value:GetName() == "corner_button" then return value end
	end

	return nil
end

---Sets the icon for the curner button.
---
---**Must be called after VoteWindowState has been set.**
local function setAppropriateCurnerIcon()
	local button = getCornerButton()
	if button == nil then return end

	if VoteWindowState == eWindowMode.Browse then
		button:SetIcon("icon16/add.png")
	else
		button:SetIcon("icon16/arrow_undo.png")
	end
end

local function loadPetitionBrowserPage(html)
	html:SetHTML(FSB.GetResource("vote/petition_browser.html"))
	html.OnFinishLoadingDocument = function(self, url)
		if VoteWindowState ~= eWindowMode.Browse then return end

		for index, petition in pairs(petitions_cache) do
			addPetitionToHTML(html, petition)
		end
	end
	VoteWindowState = eWindowMode.Browse

	setAppropriateCurnerIcon()

	net.Start("petition_list_request")
	net.SendToServer()
end

local function loadPetitionEditorPage(html)
	html:SetHTML(FSB.GetResource("vote/petition_editor.html"))
	VoteWindowState = eWindowMode.Edit

	setAppropriateCurnerIcon()
end

local function loadPetitionViewPage(html, petition_id)
	html:SetHTML(FSB.GetResource("vote/petition_viewer.html"))
	html.OnFinishLoadingDocument = function(self, url)
		if VoteWindowState ~= eWindowMode.View then return end

		addPetitionToHTML(html, petitions_cache[petition_id])
	end
	VoteWindowState = eWindowMode.View
	setAppropriateCurnerIcon()
end

local function openPetition(petition_id)
	if VoteWindow == nil then return end
	if VoteWindowState ~= eWindowMode.Browse then return end

	local html = getHTMLFromWindow(VoteWindow)
	loadPetitionViewPage(html, petition_id)
end

---Opens the for petitions, you must call loadPetition*Page(html) after this.
---@return DHTML?
local function openPetitionWindow()
	if VoteWindowState ~= eWindowMode.Closed then return end
	VoteWindowState = eWindowMode.Browse

	VoteWindow = FSB.CreateWindow(FSB.Translate("vote.petitions"), 800, 600, true)

	local html = VoteWindow:Add("DHTML")
	html:Dock(FILL)
	--html:SetAllowLua(false) -- Not needed, we can register the functions we need with AddFunction
	--html:OpenURL("https://dvcs.w3.org/hg/d4e/raw-file/tip/key-event-test.html")
	html.OnDocumentReady = function (self, url)
		html:AddFunction("gmod", "CloseWindow", closeWindow)
		html:AddFunction("gmod", "CreatePetition", createPetition)
		html:AddFunction("gmod", "VoteOnPetition", voteOnPetition)
		html:AddFunction("gmod", "OpenPetition", openPetition)
		html:AddFunction("gmod", "RequestMorePetitions", requestMorePetitions)
		html:AddFunction("gmod", "SetDraftText", setDraftText)
		html:AddFunction("gmod", "GetDraftText", getDraftText)
		html:AddFunction("gmod", "OpenURL", gui.OpenURL)
		html:AddFunction("language", "Update", FSB.Translate)
	end

	VoteWindow.OnClose = function (self)
		gui.EnableScreenClicker(false)
		VoteWindowState = eWindowMode.Closed
	end

	local new_button = VoteWindow:Add("DButton")
	new_button:SetPos(5,5)
	new_button:SetSize(20, 20)
	new_button:SetIcon("icon16/add.png")
	new_button:SetText("")
	new_button:SetName("corner_button")
	new_button.Paint = nil
	new_button.DoClick = function()
		if VoteWindowState == eWindowMode.Browse then
			loadPetitionEditorPage(html)
		else
			loadPetitionBrowserPage(html)
		end
	end

	return html
end

concommand.Add("vote", function()
	local html = openPetitionWindow()
	if html then
		loadPetitionBrowserPage(html)
	end
end)

--#endregion HTML Window

--#region Networking

net.Receive("petition_transmit", function(len, ply)
	---@type petition
	---@diagnostic disable-next-line: missing-fields
	local petition = {}
	assert(net.ReadBool(), "Server sent us a petition without an ID. What the fuck am I supposed to do with it?")

	petition.index = net.ReadUInt(PETITION_ID_BITS)
	petition.name = net.ReadString()
	if net.ReadBool() then -- include_votes
		petition.num_likes       = net.ReadUInt(PETITION_VOTE_BITS)
		petition.num_dislikes    = net.ReadUInt(PETITION_VOTE_BITS)
		petition.our_vote_status = net.ReadUInt(2)
	else
		-- This must exist on the client, if it wasn't transmitted, fill it with default values.
		petition.num_likes = 0
		petition.num_dislikes = 0
		petition.our_vote_status = eVoteStatus.NOT_VOTED
	end
	if net.ReadBool() then -- include_author_info
		petition.author_name    = net.ReadString()
		petition.author_steamid = net.ReadString()
	end
	if net.ReadBool() then -- include_time_info
		petition.creation_time = net.ReadUInt(32)
		petition.expire_time = net.ReadUInt(32)
	end

	local description_length = net.ReadUInt(19)
	local description_compressed = net.ReadData(description_length)
	---@diagnostic disable-next-line: assign-type-mismatch
	petition.description = util.Decompress(description_compressed)

	petitions_cache[petition.index] = petition
	petitions_available[petition.index] = true

	if VoteWindowState == eWindowMode.Browse and VoteWindow ~= nil then
		local html = getHTMLFromWindow(VoteWindow)
		---@diagnostic disable-next-line: param-type-mismatch
		addPetitionToHTML(html, petition)
	end
end)

net.Receive("petition_removed", function (len, ply)
	local index = net.ReadUInt(PETITION_ID_BITS)
	petitions_available[index] = nil
	petitions_cache[index] = nil
	print("Server removed petition", index)
end)

net.Receive("petition_list_responce", function(len, ply)
	local num_petitions = net.ReadUInt(PETITION_ID_BITS)
	local petitions_added = false
	for i = 1, num_petitions do
		local petition_id = net.ReadUInt(PETITION_ID_BITS)
		if not petitions_available[petition_id] then
			petitions_added = true
		end

		petitions_available[petition_id] = true
	end

	if petitions_added then
		requestMorePetitions()
	end
end)


net.Receive("petition_votes_responce", function(len, ply)
	local petition_id = net.ReadUInt(PETITION_ID_BITS)
	local num_likes = net.ReadUInt(PETITION_VOTE_BITS)
	local num_dislikes = net.ReadUInt(PETITION_VOTE_BITS)
	local our_vote_status = net.ReadUInt(2)

	if petitions_cache[petition_id] == nil then return end

	petitions_cache[petition_id].num_likes = num_likes
	petitions_cache[petition_id].num_dislikes = num_dislikes
	petitions_cache[petition_id].our_vote_status = our_vote_status

	if (VoteWindowState == eWindowMode.Browse or VoteWindowState == eWindowMode.View) and VoteWindow ~= nil then
		local html = getHTMLFromWindow(VoteWindow)
		updatePetitionVotesHTML(html, petitions_cache[petition_id])
	end
end)

net.Receive("petition_accepted", function(len, ply)
	local petition_id = net.ReadUInt(PETITION_ID_BITS)

	if VoteWindowState == eWindowMode.Edit and VoteWindow ~= nil then
		local html = getHTMLFromWindow(VoteWindow)
		loadPetitionBrowserPage(html)
	end

	requestPetitions{petition_id}
end)

--#endregion Networking


--#region Public functions

---Checks if a petition with this index exists, it will return false if you don't have the petition list loaded
---@param index integer
---@return boolean
function FSB.IsPetitionValid(index)
	return petitions_available[index] and true or false
end

---Gets a petition if it's cached, if the petition isn't cached it will request it and return nil.
---You can keep calling this until the petition is recieved.
---@param index integer petition index
---@return petition? | petition or nil if we are waiting for it to arrive to the client.
function FSB.GetPetition(index)
	if table.IsEmpty(petitions_available) then
		net.Start("petition_list_request")
		net.SendToServer()
		return
	end
	if not petitions_available[index] then
		return FSB.GetInvalidPetition(index)
	end

	local cached_petition = petitions_cache[index]
	if cached_petition then
		return cached_petition
	end

	requestPetitions{index}
end

---Returns the petition with the highest index.
---Doesn't have to be the latest petition, but I don't see a situation when it wouldn't be.
---@return integer petition_index
function FSB.GetLastPetition()
	local largest_index = 0
	for index, _ in pairs(petitions_available) do
		if largest_index < index then
			largest_index = index
		end
	end
	return largest_index
end

---Opens the petition view window.
---The petition must be loaded when you call this function.
---@param petition_id integer petition index
function FSB.OpenPetition(petition_id)
	local html = openPetitionWindow()
	if html then
		loadPetitionViewPage(html, petition_id)
	end
end
--#endregion
