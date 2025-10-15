return [[
<!--Sorry for using HTML-->

<!DOCTYPE html>
<html>
<script type="text/javascript" src="asset://garrysmod/html/js/thirdparty/jquery.js"></script>
<script type="text/javascript" src="asset://garrysmod/html/js/thirdparty/angular.js"></script>
<script type="text/javascript" src="asset://garrysmod/html/js/thirdparty/angular-route.js"></script>
<script type="text/javascript" src="asset://garrysmod/html/js/lua.js"></script>

<script type="text/javascript" src="https://spec.commonmark.org/js/commonmark.js"></script>

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