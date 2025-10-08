---@diagnostic disable: inject-field

---@type table<integer, petition>
local petitions_cache = {}

--#region vgui2

-- Maybe use an existing font.
surface.CreateFont("vote_menu_title", {font="Roboto", size=18, antialias=true, extended=true})

---@return DFrame
local function createWindow(name, size_x, size_y, is_popup, class)
	local menu = vgui.Create("DFrame")
	menu:SetSize(size_x, size_y)
	menu:SetSizable(true)
	menu:SetTitle("")
	menu:SetKeyboardInputEnabled(true)
	menu:MakePopup()
	menu:ShowCloseButton(true)
	menu:Center()
	if is_popup then menu:MakePopup() end
	function menu:Paint(w,h)
		--draw.RoundedBox(4, 2, 3, w - 2, h -2, Color(180,177,177,150))
		draw.RoundedBox(4, 0, 0, w - 2, h - 2, Color(26, 26, 26))
		draw.DrawText(name, "vote_menu_title", size_x/2, 5, Color(219, 219, 219), TEXT_ALIGN_CENTER)
	end

	return menu
end


---@param petition petition
local function createVotePanel(petition)
	local frame = vgui.Create("DPanel")

	frame:SetSize(96, 20)
	frame.Paint = function (self, w, h)
		draw.RoundedBox(4, 0,0, w,h, Color(20, 20, 20, 255))
	end

	local function paint_button(self, w,h)
		draw.DrawText(self.m_customText, "DermaDefault", w/2+8, h/2-7, color_white, TEXT_ALIGN_CENTER)
	end


	local petition_like = frame:Add("DButton")
	petition_like:SetIcon("icon16/thumb_up.png")
	petition_like:SetSize(frame:GetWide()/2, 16)
	petition_like:Dock(LEFT)
	petition_like:SetText("")
	petition_like.Paint = paint_button
	petition_like.m_customText = tostring(petition.num_likes)
	petition_like.DoClick = function ()
		petition.num_likes = petition.num_likes + 1
		voteOnPetition(petition, false)
	end

	local petition_dislike = frame:Add("DButton")
	petition_dislike:SetIcon("icon16/thumb_down.png")
	petition_dislike:SetSize(frame:GetWide()/2, 16)
	petition_dislike:Dock(RIGHT)
	petition_dislike:SetText("")
	petition_dislike.Paint = paint_button
	petition_dislike.m_customText = tostring(petition.num_dislikes)
	petition_dislike.DoClick = function ()
		petition.num_dislikes = petition.num_dislikes + 1
		voteOnPetition(petition, true)
	end
	return frame
end

---@param window DFrame
---@return DScrollPanel
local function createBrowsingPanel(window)
	local button_rounding = 16
	local button_height = 60
	local button_color = Color(41, 41, 41, 255)

	local scroll_area = window:Add("DScrollPanel")

	scroll_area:Dock(FILL)
	scroll_area:InvalidateParent(true)

--#region Remove visual scroll bar
	--local sbar = scroll_area:GetVBar()
	--function sbar:Paint(w, h)end
	--function sbar.btnUp:Paint(w, h) end
	--function sbar.btnDown:Paint(w, h) end
	--function sbar.btnGrip:Paint(w, h) end
--#endregion

	for index, petition in pairs(petitions_cache) do
		local petition_button = scroll_area:Add("DButton")
		petition_button:SetText("")
		petition_button:SetSize(scroll_area:GetWide(), button_height)
		petition_button.Paint = function(self, w, h)
			draw.RoundedBox( button_rounding, 0, 0, w, h, button_color )
		end
		petition_button:DockMargin(0,5,0,0)
		petition_button:Dock(TOP)


		local petition_name = petition_button:Add("DLabel")
		petition_name:SetText(petition.name)
		petition_name:SetSize(petition_button:GetWide()-button_rounding*2, 18)
		petition_name:SetPos(button_rounding/2, button_rounding/2)
		petition_name:SetFont("vote_menu_title")

		local vote_panel = createVotePanel(petition)
		vote_panel:SetParent(petition_button)
		local vote_width, vote_height = vote_panel:GetSize()
		vote_panel:SetPos(petition_button:GetWide()-vote_width-button_rounding/2, button_height-vote_height-button_rounding/2)

		local author_name = petition_button:Add("DLabel")
		author_name:SetText("Author: " .. petition.author_name)
		author_name:SizeToContents()
		local author_width, author_height = author_name:GetSize()
		author_name:SetPos(petition_button:GetWide()-author_width-button_rounding/2, author_height-button_rounding/2)
	end

	local new_button = window:Add("DButton")
	new_button:SetPos(5,5)
	new_button:SetSize(20, 20)
	new_button:SetIcon("icon16/add.png")
	new_button:SetText("")
	new_button.Paint = nil
--	new_button.DoClick = function()
--		local description_text =
--[[This is our long description
--In this long description we talk about what this petition is about,
--how it solves an issue and something else, it's not that long to be honest.
--]]
--		local description_compressed = util.Compress(description_text)
--		local description_compressed_len = #description_compressed
--		net.Start("create_petition")
--			net.WriteString("Petition name")
--			net.WriteUInt(description_compressed_len, 19)
--			net.WriteData(description_compressed, description_compressed_len)
--		net.SendToServer()
--		print("Sent new petition to server")
--	end
	new_button.DoClick = function()
		window:Close()
	end

	return scroll_area
end

local function createNewPetitionPanel(window)
	
end

--#endregion vgui2

-- Global so it's not reset by script reloads
---@type DFrame
PetitionWindow = PetitionWindow or nil
PetitionWindowOpen = PetitionWindowOpen or false

concommand.Add("vote", function()
	if PetitionWindowOpen then return end
	PetitionWindowOpen = true

	local window_width = 800
	local window_hight = 600
	PetitionWindow = createWindow("Voting", window_width, window_hight, false)
	createBrowsingPanel(PetitionWindow)

	gui.EnableScreenClicker(true)
	PetitionWindow.OnClose = function (self)
		gui.EnableScreenClicker(false)
		PetitionWindowOpen = false
	end
end)

--#region Networking
net.Receive("receive_patition_list", function(len, ply)
	local array = net.ReadTable()
	for index, value in ipairs(array) do
		if petitions_cache[value.id] == nil then
			petitions_cache[value.id] = {
				index = value.id,
				name = value.name,
				description = nil,
				num_likes = nil,
				num_dislikes = nil,
				author_name = nil,
				loaded = false
			}
		end
	end

	for key, value in pairs(petitions_cache) do
		if not value.loaded then
			net.Start("request_petition")
				net.WriteUInt(value.index, PETITION_ID_BITS)
			net.SendToServer()
		end
	end
end)

net.Receive("receive_petition", function(len, ply)
	local petition_id = net.ReadUInt(PETITION_ID_BITS)
	local name = net.ReadString()
	local num_agreed = net.ReadUInt(16)
	local num_disagreed = net.ReadUInt(16)

	local description_length = net.ReadUInt(19)
	local description_compressed = net.ReadData(description_length)
	local description_text = util.Decompress(description_compressed)
	if description_text == nil then description_text = "" end

	local author_name = net.ReadString()
	local author_id = net.ReadString() -- SteamID64, not used, but feel free to use this.

	petitions_cache[petition_id] = {
		index = petition_id,
		name = name,
		description = description_text,
		num_likes = num_agreed,
		num_dislikes = num_disagreed,
		author_name = author_name,
		loaded = true
	}

	print("Petition recieved", name)
end)

net.Receive("vote_on", function (len, ply)
	local petition_id = net.ReadUInt(PETITION_ID_BITS)
	local dislike = net.ReadBool()

	petitions_cache[petition_id].num_likes = 0
end)
--#endregion Networking

--#region HTML Window

local browser_html =
[[
<!--Sorry for using HTML-->

<!DOCTYPE html>
<html>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">

<script type="text/javascript" src="asset://garrysmod/html/js/thirdparty/jquery.js"></script>
<script type="text/javascript" src="asset://garrysmod/html/js/thirdparty/angular.js"></script>
<script type="text/javascript" src="asset://garrysmod/html/js/thirdparty/angular-route.js"></script>
<script type="text/javascript" src="asset://garrysmod/html/js/lua.js"></script>
<!--
		<script type="text/javascript" src="/home/tupoy/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/html/js/thirdparty/jquery.js"></script>
		<script type="text/javascript" src="/home/tupoy/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/html/js/thirdparty/angular.js"></script>
		<script type="text/javascript" src="/home/tupoy/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/html/js/thirdparty/angular-route.js"></script>
		<script type="text/javascript" src="/home/tupoy/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/html/js/lua.js"></script>
	-->

<style>
	:root {
		--main-color: rgb(31, 31, 31);
		--text-color: white
	}

	.petition {
		color: var(--text-color);
		background-color: var(--main-color);
		border-radius: 25px;
		padding: 15px;
		width: 100%;
		box-sizing: border-box;
		margin-top: 1mm;
		font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
	}

	#like_button {
		color: var(--text-color);
		background-color: black;
	}

	#vote_menu {
		float: right;
	}
</style>
<script>
	// Sorry for using javascript.
	// Sorry for using angular.

	function UpdateDigest(scope, timeout) {
		if (!scope) return;
		if (scope.DigestUpdate) return;

		scope.DigestUpdate = setTimeout(function () {
			scope.DigestUpdate = 0;
			scope.$digest();

		}, timeout);
	}

	var gScope = null;

	angular.module("petitionBrowser", [])
		.controller('petitionBrowserController', function ($scope) {
			gScope = $scope;

			var petitionList = this;
			$scope.Petitions = [];

			$scope.petitionClicked = function (petition) {
				console.log("clicked", petition.index)
			}

			$scope.likePressed = function (petition) {
				console.log("like clicked", petition.index)
			}
			$scope.dislikePressed = function (petition) {
				console.log("dislike clicked", petition.index)
			}
		});
	// Manually bootstrap angularjs because otherwise it will complain about document.location.origin
	angular.element(document).ready(function () {
		angular.bootstrap(document.body, ['petitionBrowser']);
	});

	function addPetition(index, name, author, likes, dislikes) {
		gScope.Petitions.push({ index: index, name: name, author: author, likes: likes, dislikes: dislikes });
		UpdateDigest(gScope, 50);
	};
	function updatePetition(index, name, author, likes, dislikes) {
		var petitions = gScope.Petitions;
		var petitions_length = petitions.length;
		for (var i = 0; i < petitions_length; i++) {
			if (petitions[i].index == index) {
				petitions[i].name = name;
				petitions[i].author = author;
				petitions[i].likes = likes;
				petitions[i].dislikes = dislikes;
				UpdateDigest(gScope, 50);
				return true;
			}
		}
		return false;
	};
	function addOrUpdatePetition(index, name, author, likes, dislikes) {
		if (!updatePetition(index, name, author, likes, dislikes)) {
			addPetition(index, name, author, likes, dislikes);
		}
	};

	function clearPetitions() {
		gScope.Petitions = [];
		UpdateDigest(gScope, 50);
	};
</script>

<body>
	<div id="petition_list" ng-controller="petitionBrowserController as petitionList">
		<div class="petition" ng-repeat="petition in Petitions">
			<a ng-click='petitionClicked(petition)'>{{petition.name}}</a>

			<a style="float: right;">Author: {{petition.author}}</a>
			<br>
			<br>
			<div id="vote_menu">
				<button ng-click="likeClicked(petition)" id="like_button"><i class="fa fa-thumbs-up"></i> {{petition.likes}}</button>
				<button ng-click="dislikeClicked(petition)" id="like_button"><i class="fa fa-thumbs-down"></i> {{petition.dislikes}}</button>
			</div>
			<br>
		</div>
	</div>
</body>

</html>
]]

local editor_html =
[[
<!--Sorry for using HTML-->

<!DOCTYPE html>
<html>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">

<script type="text/javascript" src="asset://garrysmod/html/js/thirdparty/jquery.js"></script>
<script type="text/javascript" src="asset://garrysmod/html/js/thirdparty/angular.js"></script>
<script type="text/javascript" src="asset://garrysmod/html/js/thirdparty/angular-route.js"></script>
<script type="text/javascript" src="asset://garrysmod/html/js/lua.js"></script>

<script type="text/javascript" src="https://spec.commonmark.org/js/commonmark.js"></script>

<script type="text/javascript"
	src="/home/tupoy/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/html/js/thirdparty/jquery.js"></script>
<script type="text/javascript"
	src="/home/tupoy/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/html/js/thirdparty/angular.js"></script>
<script type="text/javascript"
	src="/home/tupoy/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/html/js/thirdparty/angular-route.js"></script>
<script type="text/javascript"
	src="/home/tupoy/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/html/js/lua.js"></script>

<style>
	:root {
		--main-color: rgb(31, 31, 31);
		--text-color: white;
		--text-darker-color: gray;
		--light-color: rgb(50, 50, 50);
	}

	html {
		font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
		background-color: rgb(21, 21, 21);
		tab-size: 4;
	}

	#nameInput {
		color: var(--text-color);
		background-color: var(--main-color);
	}
	label {
		color: var(--text-color);
	}

	textarea {
		width: 100%;
		height: 100%;
		min-height: 30em;
		resize: vertical;
		box-sizing: border-box;
		color: var(--text-color);
		background-color: var(--main-color);

		border-bottom-left-radius: 4px;
		border-bottom-right-radius: 4px;
		border-top: none;
	}

	#preview {
		width: 100%;
		max-width: fit-content;
		margin: 0;
		color: var(--text-color);
		box-sizing:border-box;
		word-wrap: break-word;
	}

	code {
		background-color: var(--main-color);
		color: var(--text-color);
		border-radius: 0.3rem;
		padding: 4px 5px 5px;
		white-space: nowrap;
	}

	pre code {
		white-space: inherit;
	}

	pre {
		background-color: var(--main-color);
		padding: 5px;
		border-radius: 0.3em;
	}

	blockquote {
		margin-left: 2em;
		border-left: 4px var(--light-color) solid;
		background-color: var(--main-color);
	}

	blockquote > p {
		margin-left: 1em;
		text-indent: 0;
		color: var(--text-darker-color)
	}

	#create_button {
		background-color:green;
		border-radius: 5px;
		float: right;
		width: 8em;
		height: 2em;
	}

	/*Tabs*/

	a, a:visited, a:hover, a:active {
		color: inherit;
	}

	.nav > li > a {
		text-decoration: none;
		color: var(--text-color);
	}

	.nav-tabs {
		overflow: hidden;
		background-color: var(--light-color);
		padding-left: 10px;
		margin-top: 0;
		margin-bottom: -1px;
		list-style: none;
		
		border-top-left-radius: 4px;
		border-top-right-radius: 4px;
		border-top:   1px solid #ddd;
		border-right: 1px solid #ddd;
		border-left:  1px solid #ddd;
		border-bottom: none;
	}

	.nav-tabs > li {
		float: left;
		margin-right: 2px;
		padding: 8px;
		border-top-left-radius: 4px;
		border-top-right-radius: 4px;
	}

	.nav-tabs > li.active {
		cursor: default;
		background-color: var(--main-color);
		border-top:   1px solid #ddd;
		border-right: 1px solid #ddd;
		border-left:  1px solid #ddd;
	}
	.nav-tabs > li:not(.active) {
		cursor: pointer;
	}

	.nav-tabs > .active > a {
		cursor: default;
	}

	.tab-pane:not(.active) {
		display: none;
	}

	.notification {
		display: block;
		position: absolute;
		width: 290px;
		height: 90px;
		padding: 10px;
		border-radius: 5px;
		border: 1px solid black;
		right: 10px;
		bottom: 10px;
		background-color: brown;
	}

	.notification .notificationCloseButton{
		position: absolute;
		top: 0;
		right: 0;
		padding: 5px;
	}
	.notification .notificationCloseButton:hover{
		color: white;
		cursor: pointer;
	}
</style>
<script>
	// Sorry for using javascript.
	// Sorry for using angular.

	function UpdateDigest(scope, timeout) {
		if (!scope) return;
		if (scope.DigestUpdate) return;

		scope.DigestUpdate = setTimeout(function () {
			scope.DigestUpdate = 0;
			scope.$digest();

		}, timeout);
	}

	var gScope = null;

	angular.module('components', [])
		.directive('tabs', function () {
			return {
				restrict: 'E',
				transclude: true,
				scope: {},
				controller: function ($scope, $element) {
					var panes = $scope.panes = [];

					$scope.select = function (pane) {
						angular.forEach(panes, function (pane) {
							pane.selected = false;
						});
						pane.selected = true;
					}

					this.addPane = function (pane) {
						if (panes.length == 0) $scope.select(pane);
						panes.push(pane);
					}
				},
				template:
					'<div class="tabbable">' +
						'<ul class="nav nav-tabs">' +
							'<li ng-repeat="pane in panes" ng-click="select(pane)" ng-class="{active:pane.selected}">' +
								'<a href="">{{pane.title}}</a>' +
							'</li>' +
						'</ul>' +
						'<div class="tab-content" ng-transclude></div>' +
					'</div>',
				replace: true
			};
		})

		.directive('pane', function () {
			return {
				require: '^tabs',
				restrict: 'E',
				transclude: true,
				scope: { title: '@' },
				link: function (scope, element, attrs, tabsController) {
					tabsController.addPane(scope);
				},
				template:
					'<div class="tab-pane" ng-class="{active: selected}" ng-transclude>' +
					'</div>',
				replace: true
			};
		})

	angular.module("petitionCreator", ['components'])
		.controller('petitionCreatorController', function ($scope) {
			gScope = $scope;

			var notificationList = this;
			$scope.Notifications = [];
		});

	var commonmark = window.commonmark;
	var writer = new commonmark.HtmlRenderer({ sourcepos: true, safe: true });
	var reader = new commonmark.Parser();

	var render = function(parsed) {
		if (parsed === undefined) {
			return;
		}
		var result = writer.render(parsed);
		var preview = $("#preview");
		preview.get(0).innerHTML = result;

		$('a').click(function(e) {
			// This is not for safety, but so we don't open empty links.
			if (e.currentTarget.href.startsWith("http"))
			{
				e.preventDefault();
				gmod.OpenURL(e.currentTarget.href)
			}
		});
	};

	var parseAndRender = function() {
		var textarea = $("#descriptionInput");
		var parsed = reader.parse(textarea.val());
		render(parsed);
	};

	// https://stackoverflow.com/a/75988895
	const debounce = (callback, wait) => {
		let timeoutId = null;
		return (...args) => {
			window.clearTimeout(timeoutId);
			timeoutId = window.setTimeout(() => {
			callback(...args);
			}, wait);
		};
	}

	angular.element(document).ready(function () {
		// Manually bootstrap angularjs because otherwise it will complain about document.location.origin
		angular.bootstrap(document.body, ['petitionCreator']);

		var textarea = $("#descriptionInput");
		textarea.bind(
			"input propertychange",
			debounce(parseAndRender, 50)
		);
	});

	function submit_petition()
	{
		name = ($("#nameInput").val());

		if (name.length == 0)
		{
			gScope.Notifications.push({text: "Name must not be empty"})
			UpdateDigest(gScope, 50);
			return;
		}
		
		var description_text = $("#descriptionInput").val();
		if (description_text.length == 0)
		{
			gScope.Notifications.push({text: "Description must not be empty"})
			UpdateDigest(gScope, 50);
			return;
		}

		gmod.CreatePetition(name, description_text);
	}

</script>

<body>
	<label>Name: <input id="nameInput" type="text"></label>

	<hr>

	<tabs>
		<pane title="Write">
			<textarea id="descriptionInput" placeholder="Describe your petition here.
Markdown is supported.
If enter doesn't work, you have to copy some new lines from another text editor..."></textarea>
		</pane>
		<pane title="Preview">
			<div id="preview"></div>
		</pane>

		<input id="create_button" type="submit" value="Create" onclick="submit_petition()">
	</tabs>

	<div id="notification_list" ng-controller="petitionCreatorController as notificationList">
		<div class="notification" ng-repeat="notification in Notifications">
			<span>{{notification.text}}</span>
			<div class="notificationCloseButton" onclick="gScope.Notifications = []; UpdateDigest(gScope, 50)">X</div>
		</div>
	</div>
</body>

</html>
]]

local function addPetitionToHTML(html, petition)
	html:QueueJavascript(
		"addOrUpdatePetition("
		.. tostring(petition.index)
		.. ", '"
		.. string.JavascriptSafe(petition.name)
		.. "', '"
		.. string.JavascriptSafe(petition.author_name)
		.. "', "
		.. tostring(petition.num_agreed)
		.. ", "
		.. tostring(petition.num_disagreed)
		.. ")"
	)
end

local function createPetition(name, description)
	local description_compressed = util.Compress(description)
	local description_compressed_len = #description_compressed
	net.Start("create_petition")
		net.WriteString(name)
		net.WriteUInt(description_compressed_len, 19)
		net.WriteData(description_compressed, description_compressed_len)
	net.SendToServer()
	print("Sent new petition to server")
end

---@param petition petition
---@param dislike boolean
local function voteOnPetition(petition, dislike)
	net.Start("vote_on")
		net.WriteInt(petition.index, PETITION_ID_BITS)
		net.WriteBool(dislike)
	net.SendToServer()
end


local function closeWindow()
	ChromeWindow:Remove();
	ChromeWindow=nil
end

local eWindowMode = {
	Closed = 0,
	Browse = 1,
	Edit = 2,
	View = 3,
}

ChromeWindow = ChromeWindow or nil
ChromeWindowState = ChromeWindowState or eWindowMode.Closed

local function loadPetitionBrowserPage(html)
	html:SetHTML(browser_html)
	html.OnFinishLoadingDocument = function(self, url) 
		for index, petition in pairs(petitions_cache) do
			if petition.loaded then
				addPetitionToHTML(html, petition)
			end
		end
	end
	ChromeWindowState = eWindowMode.Browse
end

local function loadPetitionEditorPage(html)
	html:SetHTML(editor_html)
	ChromeWindowState = eWindowMode.Edit
end


concommand.Add("chrome", function()
	if ChromeWindowState ~= eWindowMode.Closed then return end
	ChromeWindowState = eWindowMode.Browse

	ChromeWindow = createWindow("Voting", 800, 600, false)

	local html = ChromeWindow:Add("DHTML")
	html:Dock(FILL)
	--html:SetAllowLua(false) -- Not needed, we can register the functions we need with AddFunction
	html:SetHTML(browser_html)
	--html:OpenURL("https://dvcs.w3.org/hg/d4e/raw-file/tip/key-event-test.html")
	html.OnDocumentReady = function (self, url)
		html:AddFunction("gmod", "CloseWindow", closeWindow)
		html:AddFunction("gmod", "CreatePetition", createPetition)
		html:AddFunction("gmod", "OpenURL", gui.OpenURL)
	end

	loadPetitionBrowserPage(html)

	ChromeWindow.OnClose = function (self)
		gui.EnableScreenClicker(false)
		ChromeWindowState = eWindowMode.Closed
	end

	local new_button = ChromeWindow:Add("DButton")
	new_button:SetPos(5,5)
	new_button:SetSize(20, 20)
	new_button:SetIcon("icon16/add.png")
	new_button:SetText("")
	new_button.Paint = nil
	new_button.DoClick = function()
		if ChromeWindowState == eWindowMode.Browse then
			loadPetitionEditorPage(html)
			new_button:SetIcon("icon16/arrow_undo.png")
		else
			loadPetitionBrowserPage(html)
			new_button:SetIcon("icon16/add.png")
		end
	end

	
end)

--#endregion HTML Window