return [[
<!--Sorry for using HTML-->
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<script type="text/javascript" src="asset://garrysmod/html/js/thirdparty/jquery.js"></script>
<script type="text/javascript" src="asset://garrysmod/html/js/thirdparty/angular.js"></script>
<script type="text/javascript" src="asset://garrysmod/html/js/thirdparty/angular-route.js"></script>
<script type="text/javascript" src="asset://garrysmod/html/js/lua.js"></script>
<script>
	// https://javascript.plainenglish.io/how-this-simple-method-turned-my-array-code-from-messy-to-neat-3bba8f25e991
	// Seems AI generated, but who cares, I'm not implementing this in javascript myself.
	if (!Array.prototype.at) {
		Array.prototype.at = function (n) {
			if (this == null) throw new TypeError("Called on null or undefined");
			const len = this.length >>> 0;
			n = Number(n);
			if (isNaN(n)) n = 0;
			n = n < 0 ? Math.ceil(n) : Math.floor(n); // manual truncation
			if (n < 0) n += len;
			if (n < 0 || n >= len) return undefined;
			return this[n];
		};
	}
</script>
<script type="text/javascript" src="https://cdn.jsdelivr.net/npm/dompurify@0.6.6/purify.min.js"></script>
<script type="text/javascript" src="https://cdn.jsdelivr.net/npm/marked@15.0.12/marked.min.js"></script>
</head>
<body>
	<label>Название: <input id="nameInput" type="text"></label>

	<hr>

	<tabs>
		<pane title="Писать">
			<textarea id="descriptionInput" placeholder="Опишите здесь свою петицию.
Прочтите заповеди перед написанием петиции.
Если вам лень писать описание - создателю лень реализовывать вашу петицию.

Петиции нельзя удалить или редактировать - думайте перед тем как создавать.

# Заголовок
## Заголовок но меньше

*курсив*
**жирный**
`код`

[гипер ссылка](https://example.com)
![картинка или GIF'ка](https://imgur.com/TxuGT4W.gif)

> Цитата

1. Упорядоченный
2. Список

- Неупорядоченный
- Список

"></textarea>
		</pane>
		<pane title="Предпросмотр">
			<div id="preview"></div>
		</pane>

		<input id="createButton" type="submit" value="Создать" onclick="submit_petition()">
	</tabs>

	<div id="notification_list" ng-controller="petitionCreatorController as notificationList">
		<div class="notification" ng-repeat="notification in Notifications">
			<span>{{notification.text}}</span>
			<div class="notificationCloseButton" onclick="gScope.Notifications = []; UpdateDigest(gScope, 50)">X</div>
		</div>
	</div>
</body>
<style>
	:root {
		--main-color: rgb(31, 31, 31);
		--text-color: white;
		--text-darker-color: gray;
		--light-color: rgb(50, 50, 50);
	}

	:link, :visited
	{
		color: #58a6ff;
	}

	html {
		font-family: "Inter", Tahoma, Geneva, Verdana, sans-serif;
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
		cursor: pointer;
	}

	#createButton:disabled {
		cursor: not-allowed;
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

	function IsGMod()
	{
		return typeof gmod !== "undefined"
	}

	function IsLinux()
	{
		return navigator.appVersion.indexOf("Linux") != -1
	}

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

	var parseAndRender = function() {
		var textarea = $("#descriptionInput");
		var result = marked.parse(textarea.val().replace(/^[\u200B\u200C\u200D\u200E\u200F\uFEFF]/,""));
		var preview = $("#preview");
		preview.get(0).innerHTML = DOMPurify.sanitize(result);
		
		if (IsGMod())
		{
			var nameinput = $("#nameInput")
			gmod.SetDraftText(nameinput.val(), textarea.val())

			// In GMod, we don't want to open links directly, instead, open the steam overlay and open the link there.
			$('a').click(function(e) {
				// This is not for safety, but so we don't open empty links.
				if (e.currentTarget.href.startsWith("http"))
				{
					e.preventDefault();
					gmod.OpenURL(e.currentTarget.href)
				}
			});
		}
	};


	function submit_petition()
	{
		var name = ($("#nameInput").val());

		if (isWhitespaceString(name))
		{
			gScope.Notifications.push({text: "Название не может быть пустым"})
			UpdateDigest(gScope, 50);
			return;
		}
		
		var description_text = $("#descriptionInput").val();
		if (isWhitespaceString(description_text))
		{
			gScope.Notifications.push({text: "Описание не может быть пустым"})
			UpdateDigest(gScope, 50);
			return;
		}

		$('#createButton').attr('disabled','disabled');
		if (IsGMod())
		{
			gmod.CreatePetition(name, description_text);
		}
		else
		{
			console.log("Imagine that a new petition was created", name, description_text)
		}
	}


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

	// Dirty hack for text input ignoring enter on linux.
	function keydown(event)
	{
		if (event.keyCode === 13 && IsGMod() && IsLinux())
		{
			document.execCommand('insertText', false /*no UI*/, "\n");
		}
	}

	angular.element(document).ready(function () {
		// Manually bootstrap angularjs because otherwise it will complain about document.location.origin
		angular.bootstrap(document.body, ['petitionCreator']);

		var textarea = $("#descriptionInput");
		textarea.bind(
			"input propertychange",
			debounce(parseAndRender, 200)
		);

		textarea.keydown(keydown)

		if (IsGMod())
		{
			gmod.GetDraftText(function(name, desc)
			{
				$("#descriptionInput").val(desc);
				$("#nameInput").val(name);

				if (!isWhitespaceString(desc))
				{
					parseAndRender()
				}
			});
		}
	});


</script>
</html>
]]