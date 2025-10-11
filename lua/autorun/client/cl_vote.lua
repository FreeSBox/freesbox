---@diagnostic disable: inject-field

---@type table<integer, petition>
local petitions_cache = {}

--- index, true or nil
---@type table<integer, boolean?>
local petitions_available = {}

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
		draw.RoundedBox(4, 0, 0, w - 2, h - 2, Color(26, 26, 26))
		draw.DrawText(name, "vote_menu_title", size_x/2, 5, Color(219, 219, 219), TEXT_ALIGN_CENTER)
	end

	return menu
end

--#endregion vgui2

--#region HTML Window

local browser_html =
[[
<!--Sorry for using HTML-->

<!DOCTYPE html>
<html lang="ru-RU">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">

<script type="text/javascript" src="asset://garrysmod/html/js/thirdparty/jquery.js"></script>
<script type="text/javascript" src="asset://garrysmod/html/js/thirdparty/angular.js"></script>
<script type="text/javascript" src="asset://garrysmod/html/js/thirdparty/angular-route.js"></script>
<script type="text/javascript" src="asset://garrysmod/html/js/lua.js"></script>
		<script type="text/javascript" src="/home/tupoy/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/html/js/thirdparty/jquery.js"></script>
		<script type="text/javascript" src="/home/tupoy/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/html/js/thirdparty/angular.js"></script>
		<script type="text/javascript" src="/home/tupoy/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/html/js/thirdparty/angular-route.js"></script>
		<script type="text/javascript" src="/home/tupoy/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/html/js/lua.js"></script>

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
	#like_button:disabled {
		color: var(--text-color);
		background-color:rgb(62, 62, 62);
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
				gmod.OpenPetition(petition.index)
			}

			$scope.likeClicked = function (petition) {
				gmod.VoteOnPetition(petition.index, false)
			}
			$scope.dislikeClicked = function (petition) {
				gmod.VoteOnPetition(petition.index, true)
			}
		});
	// Manually bootstrap angularjs because otherwise it will complain about document.location.origin
	angular.element(document).ready(function () {
		angular.bootstrap(document.body, ['petitionBrowser']);
	});

	function addPetition(index, name, author, likes, dislikes, creation_time, expire_time) {
		var expired = expire_time*1000 <= Date.now()
		gScope.Petitions.push({ index: index, name: name, author: author, likes: likes, dislikes: dislikes, creation_time: creation_time, expire_time: expire_time, expired: expired });
		UpdateDigest(gScope, 50);
	};
	function updatePetition(index, name, author, likes, dislikes, creation_time, expire_time) {
		var petitions = gScope.Petitions;
		var petitions_length = petitions.length;
		var expired = expire_time*1000 <= Date.now()
		for (var i = 0; i < petitions_length; i++) {
			if (petitions[i].index == index) {
				petitions[i].name = name;
				petitions[i].author = author;
				petitions[i].likes = likes;
				petitions[i].dislikes = dislikes;
				petitions[i].creation_time = creation_time;
				petitions[i].expire_time = expire_time;
				petitions[i].expired = expired;
				UpdateDigest(gScope, 50);
				return true;
			}
		}
		return false;
	};
	function addOrUpdatePetition(index, name, description, author, likes, dislikes, creation_time, expire_time) {
		if (!updatePetition(index, name, author, likes, dislikes, creation_time, expire_time)) {
			addPetition(index, name, author, likes, dislikes, creation_time, expire_time);
		}
	};
	function updatePetitionVotes(index, likes, dislikes) {
		var petitions = gScope.Petitions;
		var petitions_length = petitions.length;
		for (var i = 0; i < petitions_length; i++) {
			if (petitions[i].index == index) {
				petitions[i].likes = likes;
				petitions[i].dislikes = dislikes;
				UpdateDigest(gScope, 50);
				return true;
			}
		}
		return false;
	};

	function clearPetitions() {
		gScope.Petitions = [];
		UpdateDigest(gScope, 50);
	};
</script>

<body>
	<div id="petition_list" ng-controller="petitionBrowserController as petitionList">
		<div class="petition" ng-repeat="petition in Petitions | orderBy:'-creation_time'">
			<a ng-click='petitionClicked(petition)'>{{petition.name}}</a>

			<span style="float: right;">Author: {{petition.author}}</span>
			<br>
			<br>
			<span>Added on: {{petition.creation_time*1000 | date:'d.M.yy H:mm'}}</span>
			<br>
			<span>Expires on: {{petition.expire_time*1000 | date:'d.M.yy H:mm'}}</span>
			<div id="vote_menu">
				<button ng-disabled="petition.expired" ng-click="likeClicked(petition)" id="like_button"><i class="fa fa-thumbs-up"></i> {{petition.likes}}</button>
				<button ng-disabled="petition.expired" ng-click="dislikeClicked(petition)" id="like_button"><i class="fa fa-thumbs-down"></i> {{petition.dislikes}}</button>
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

	#createButton {
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

	// https://stackoverflow.com/a/10262019
	const isWhitespaceString = str => !str.replace(/\s/g, '').length

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

		if (isWhitespaceString(name))
		{
			gScope.Notifications.push({text: "Name must not be empty"})
			UpdateDigest(gScope, 50);
			return;
		}
		
		var description_text = $("#descriptionInput").val();
		if (isWhitespaceString(description_text))
		{
			gScope.Notifications.push({text: "Description must not be empty"})
			UpdateDigest(gScope, 50);
			return;
		}

		$('#createButton').attr('disabled','disabled');
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

		<input id="createButton" type="submit" value="Create" onclick="submit_petition()">
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

local viewer_html =
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

	label {
		color: var(--text-color);
	}

	span {
		color: var(--text-color);
	}

	#preview {
		width: 100%;
		max-width: fit-content;
		margin: 0;
		color: var(--text-color);
		box-sizing:border-box;
		word-wrap: break-word;
	}

	#like_button {
		color: var(--text-color);
		background-color: black;
	}
	#like_button:disabled {
		color: var(--text-color);
		background-color:rgb(62, 62, 62);
	}

	#vote_menu {
		float: right;
	}
</style>
<script>
	function UpdateDigest(scope, timeout) {
		if (!scope) return;
		if (scope.DigestUpdate) return;

		scope.DigestUpdate = setTimeout(function () {
			scope.DigestUpdate = 0;
			scope.$digest();

		}, timeout);
	}


	var gScope = null;

	angular.module("petitionViewer", [])
		.controller('petitionViewerController', function ($scope) {
			gScope = $scope;

			$scope.Petition = {};

			$scope.likeClicked = function () {
				gmod.VoteOnPetition(gScope.Petition.index, false)
			}
			$scope.dislikeClicked = function () {
				gmod.VoteOnPetition(gScope.Petition.index, true)
			}
		});
	// Manually bootstrap angularjs because otherwise it will complain about document.location.origin
	angular.element(document).ready(function () {
		angular.bootstrap(document.body, ['petitionViewer']);
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

	function addOrUpdatePetition(index, name, description, author, likes, dislikes, creation_time, expire_time) {
		var parsed = reader.parse(description);
		render(parsed);

		var expired = expire_time*1000 <= Date.now()

		gScope.Petition.index = index
		gScope.Petition.name = name;
		gScope.Petition.author = author;
		gScope.Petition.likes = likes;
		gScope.Petition.dislikes = dislikes;
		gScope.Petition.creation_time = creation_time;
		gScope.Petition.expire_time = expire_time;
		gScope.Petition.expired = expired;
		UpdateDigest(gScope, 50);
	};

	function updatePetitionVotes(index, likes, dislikes)
	{
		gScope.Petition.likes = likes;
		gScope.Petition.dislikes = dislikes;
		UpdateDigest(gScope, 50);
	}

</script>

<body ng-controller="petitionViewerController as petitionViewer">
	<label>{{Petition.name}}</label>

	<span style="float: right;">Author: {{Petition.author}}</span>
	<br>
	<br>

	<span>Added on: {{Petition.creation_time*1000 | date:'d.M.yy H:mm'}}</span>
	<br>
	<span>Expires on: {{Petition.expire_time*1000 | date:'d.M.yy H:mm'}}</span>

	<div id="vote_menu">
		<button ng-disabled="Petition.expired" ng-click="likeClicked()" id="like_button"><i class="fa fa-thumbs-up"></i> {{Petition.likes}}</button>
		<button ng-disabled="Petition.expired" ng-click="dislikeClicked()" id="like_button"><i class="fa fa-thumbs-down"></i> {{Petition.dislikes}}</button>
	</div>

	<hr>

	<div id="preview"></div>
</body>

</html>
]]

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
			"updatePetitionVotes(%u, %u, %u)",
			petition.index,
			petition.num_likes,
			petition.num_dislikes
		)
	)
end

---@param html DHTML
---@param petition petition
local function addPetitionToHTML(html, petition)
	html:QueueJavascript(string.format(
			"addOrUpdatePetition(%u, '%s', '%s', '%s', %u, %u, %u, %u)",
			petition.index,
			string.JavascriptSafe(petition.name),
			string.JavascriptSafe(petition.description),
			string.JavascriptSafe(petition.author_name),
			petition.num_likes,
			petition.num_dislikes,
			petition.creation_time,
			petition.expire_time
		)
	)
end

local function createPetition(name, description)
	SendPetition({
		name=name,
		description=description
	})
	print("Sent new petition to server")
end

---@param petition_id integer
---@param dislike boolean
local function voteOnPetition(petition_id, dislike)
	net.Start("petition_vote_on")
		net.WriteInt(petition_id, PETITION_ID_BITS)
		net.WriteBool(dislike)
	net.SendToServer()
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
	html:SetHTML(browser_html)
	html.OnFinishLoadingDocument = function(self, url)
		if VoteWindowState ~= eWindowMode.Browse then return end

		for index, petition in pairs(petitions_cache) do
			print("Added", petition.name)
			addPetitionToHTML(html, petition)
		end
	end
	VoteWindowState = eWindowMode.Browse

	setAppropriateCurnerIcon()

	if #petitions_available == 0 then
		net.Start("petition_list_request")
		net.SendToServer()
	end

end

local function loadPetitionEditorPage(html)
	html:SetHTML(editor_html)
	VoteWindowState = eWindowMode.Edit

	setAppropriateCurnerIcon()
end

local function loadPetitionViewPage(html, petition_id)
	html:SetHTML(viewer_html)
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

concommand.Add("vote", function()
	if VoteWindowState ~= eWindowMode.Closed then return end
	VoteWindowState = eWindowMode.Browse

	VoteWindow = createWindow("Voting", 800, 600, false)

	local html = VoteWindow:Add("DHTML")
	html:Dock(FILL)
	--html:SetAllowLua(false) -- Not needed, we can register the functions we need with AddFunction
	--html:OpenURL("https://dvcs.w3.org/hg/d4e/raw-file/tip/key-event-test.html")
	html.OnDocumentReady = function (self, url)
		html:AddFunction("gmod", "CloseWindow", closeWindow)
		html:AddFunction("gmod", "CreatePetition", createPetition)
		html:AddFunction("gmod", "VoteOnPetition", voteOnPetition)
		html:AddFunction("gmod", "OpenPetition", openPetition)
		html:AddFunction("gmod", "OpenURL", gui.OpenURL)
	end

	loadPetitionBrowserPage(html)

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
		petition.num_likes    = net.ReadUInt(PETITION_VOTE_BITS)
		petition.num_dislikes = net.ReadUInt(PETITION_VOTE_BITS)
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

	print("Recieved: " .. petition.index)
end)

net.Receive("petition_list_responce", function(len, ply)
	local num_petitions = net.ReadUInt(PETITION_ID_BITS)
	for i = 1, num_petitions do
		petitions_available[net.ReadUInt(PETITION_ID_BITS)] = true
	end

	local request = {}
	local i = 1
	for key, value in pairs(petitions_available) do
		request[i] = key
		i = i + 1
	end

	PrintTable(request)

	net.Start("petition_request")
		net.WriteUInt(math.Clamp(#request, 0, PETITION_MAX_PETITIONS_PER_REQUEST), 8)
		for index, value in ipairs(request) do
			if index > PETITION_MAX_PETITIONS_PER_REQUEST then break end
			net.WriteUInt(value, PETITION_ID_BITS)
		end
	net.SendToServer()
end)


net.Receive("petition_votes_responce", function(len, ply)
	local petition_id = net.ReadUInt(PETITION_ID_BITS)
	local num_likes = net.ReadUInt(PETITION_VOTE_BITS)
	local num_dislikes = net.ReadUInt(PETITION_VOTE_BITS)

	assert(petitions_cache[petition_id], "Received votes for petition that wasn't cached")
	petitions_cache[petition_id].num_likes = num_likes
	petitions_cache[petition_id].num_dislikes = num_dislikes

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

	net.Start("petition_request")
	net.WriteUInt(1, 8)
	net.WriteUInt(petition_id, PETITION_ID_BITS)
	net.SendToServer()
end)

--#endregion Networking
