// Sorry for using javascript.
// Sorry for using angular.

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

function IsGMod()
{
	return typeof gmod !== "undefined";
}

function IsLinux()
{
	return navigator.appVersion.indexOf("Linux") != -1;
}

function UpdateDigest(scope, timeout)
{
	if (!scope) return;
	if (scope.DigestUpdate) return;

	scope.DigestUpdate = setTimeout(function () {
		scope.DigestUpdate = 0;
		scope.$digest();

	}, timeout);
}

function FindLastNewLineFromPos(text, pos)
{
	var last_new_line = text.lastIndexOf("\n", pos);
	const is_at_end_of_line = text.charAt(pos) == "\n";
	if (!is_at_end_of_line)
	{
		last_new_line++;
	}
	else
	{
		last_new_line = text.lastIndexOf("\n", pos-1)+1;
	}
	if (last_new_line == -1)
	{
		last_new_line = 0;
	}

	return last_new_line;
}

// I hate this web dev shit.
// This is depricated, but of course there is no other way of doing this.
// https://stackoverflow.com/a/56509046
function ReplaceText(new_text)
{
	document.execCommand("selectAll", false);
	var el = document.createElement("p");
	el.innerHTML = new_text;

	document.execCommand('insertHTML', false, el.innerHTML);
	el.remove();
}


function InsertHeading()
{
	var input = document.getElementById("descriptionInput");
	var text = input.value;
	const start = input.selectionStart;
	var last_new_line = FindLastNewLineFromPos(text, start);

	var pre_text = text.substring(0, last_new_line);
	var post_text = text.substring(last_new_line);

	input.focus();
	ReplaceText(pre_text + "### " + post_text);
}

function InsertTagsAroundText(tag)
{
	var input = document.getElementById("descriptionInput");
	var text = input.value;
	const start = input.selectionStart;
	const end = input.selectionEnd;

	var pre_text = text.substring(0, start);
	var selected_text = text.substring(start, end);
	var post_text = text.substring(end);

	input.focus();
	ReplaceText(pre_text + tag + selected_text + tag + post_text);
}

function InsertLinePrefix(prefix)
{
	var input = document.getElementById("descriptionInput");
	var text = input.value;
	const start = input.selectionStart;
	const end = input.selectionEnd;
	var last_new_line = FindLastNewLineFromPos(text, start);

	var pre_text = text.substring(0, last_new_line);
	var selected_text = text.substring(last_new_line, end);
	var post_text = text.substring(end);

	selected_text = selected_text.replace(/\r?\n/g, "\n"+prefix);

	input.focus();
	ReplaceText(pre_text + prefix + selected_text + post_text);
}

function InsertCodeBlock()
{
	var input = document.getElementById("descriptionInput");
	var text = input.value;
	const start = input.selectionStart;
	const end = input.selectionEnd;

	var pre_text = text.substring(0, start);
	var selected_text = text.substring(start, end);
	var post_text = text.substring(end);

	input.focus();
	if (selected_text.includes("\n"))
	{
		ReplaceText(pre_text + "```\n" + selected_text +"\n```" + post_text);
	}
	else
	{
		ReplaceText(pre_text + "`" + selected_text +"`" + post_text);
	}
}

function InsertOList()
{
	var input = document.getElementById("descriptionInput");
	var text = input.value;
	const start = input.selectionStart;
	const end = input.selectionEnd;
	var last_new_line = FindLastNewLineFromPos(text, start);

	var pre_text = text.substring(0, last_new_line);
	var selected_text = text.substring(last_new_line, end);
	var post_text = text.substring(end);

	input.focus();
	if (selected_text.includes("\n"))
	{
		var list_items = selected_text.split("\n");
		var new_text = "";
		console.log(list_items);
		for(var i = 0; i < list_items.length; i++)
		{
			new_text = new_text + (i+1) + ". " + list_items[i];
			if (i < list_items.length-1)
			{
				new_text = new_text + "\n";
			}
		}
		ReplaceText(pre_text + new_text + post_text);
	}
	else
	{
		ReplaceText(pre_text + "1. " + selected_text + post_text);
	}
}

function InsertLink()
{
	var input = document.getElementById("descriptionInput");
	var text = input.value;
	const start = input.selectionStart;
	const end = input.selectionEnd;

	var pre_text = text.substring(0, start);
	var selected_text = text.substring(start, end);
	var post_text = text.substring(end);

	if (selected_text === "")
	{
		selected_text = "text";
	}

	input.focus();
	ReplaceText(pre_text + "[" + selected_text + "](https://)" + post_text);
}


// https://stackoverflow.com/a/10262019
const isWhitespaceString = str => !str.replace(/\s/g, '').length

// https://stackoverflow.com/a/37493957
function getWordCount(str)
{
	var match = str.match(/[^\s]+/g);
	return match ? match.length : 0;
}

// In GMod, we don't want to open links directly, instead, open the steam overlay and open the link there.
function fixAncherTags()
{
	$('a').click(function(e) {
		// This is not for safety, but so we don't open empty links.
		if (e.currentTarget.href.startsWith("http"))
		{
			e.preventDefault();
			gmod.OpenURL(e.currentTarget.href);
		}
	});
}

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
						// Yeah, I'd rather hardcode this here then learn this stupid js framework nonsense.
						// Also I hardcoded the first pane to be the code editor, the edit buttons are hidden otherwise.
						'<div class="toolbar" ng-class="{hide:!panes[0].selected}">' +
							'<div class="tooltip-container">' +
								'<button onclick="InsertHeading()" class="fa fa-header toolbar-button"></button>' +
								'<div class="tooltip-text">Заголовок</div>' +
							'</div>' +
							'<div class="tooltip-container">' +
								'<button onclick="InsertTagsAroundText(\'**\')" class="fa fa-bold toolbar-button"></button>' +
								'<div class="tooltip-text">Жирный</div>' +
							'</div>' +
							'<div class="tooltip-container">' +
								'<button onclick="InsertTagsAroundText(\'_\')" class="fa fa-italic toolbar-button"></button>' +
								'<div class="tooltip-text">Курсив</div>' +
							'</div>' +
							'<div class="tooltip-container">' +
								'<button onclick="InsertLinePrefix(\'> \')" class="fa fa-quote-left toolbar-button"></button>' +
								'<div class="tooltip-text">Цитата</div>' +
							'</div>' +
							'<div class="tooltip-container">' +
								'<button onclick="InsertCodeBlock()" class="fa fa-code toolbar-button"></button>' +
								'<div class="tooltip-text">Код</div>' +
							'</div>' +
							'<div class="tooltip-container">' +
								'<button onclick="InsertLinePrefix(\'- \')" class="fa fa-list-ul toolbar-button"></button>' +
								'<div class="tooltip-text">Неупорядоченный список</div>' +
							'</div>' +
							'<div class="tooltip-container">' +
								'<button onclick="InsertOList()" class="fa fa-list-ol toolbar-button"></button>' +
								'<div class="tooltip-text">Упорядоченный список</div>' +
							'</div>' +
							'<div class="tooltip-container">' +
								'<button onclick="InsertLinePrefix(\'- [x] \')" class="fa fa-check toolbar-button"></button>' +
								'<div class="tooltip-text">Флажок, чекбокс, галочка</div>' +
							'</div>' +
							'<div class="tooltip-container">' +
								'<button onclick="InsertLink()" class="fa fa-link toolbar-button"></button>' +
								'<div class="tooltip-text">Ссылка</div>' +
							'</div>' +
						'</div>' +
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
	});
