return [[
<!--Sorry for using HTML-->
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
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
<script type="text/javascript" src="https://cdn.jsdelivr.net/npm/dompurify@3.3.1/dist/purify.min.js"></script>
<script type="text/javascript" src="https://cdn.jsdelivr.net/npm/marked@15.0.12/marked.min.js"></script>

<script>
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
'<button onclick="InsertHeading()" class="fa fa-header"></button>' +
'<div class="tooltip-text">Заголовок</div>' +
'</div>' +
'<div class="tooltip-container">' +
'<button onclick="InsertTagsAroundText(\'**\')" class="fa fa-bold"></button>' +
'<div class="tooltip-text">Жирный</div>' +
'</div>' +
'<div class="tooltip-container">' +
'<button onclick="InsertTagsAroundText(\'_\')" class="fa fa-italic"></button>' +
'<div class="tooltip-text">Курсив</div>' +
'</div>' +
'<div class="tooltip-container">' +
'<button onclick="InsertLinePrefix(\'> \')" class="fa fa-quote-left"></button>' +
'<div class="tooltip-text">Цитата</div>' +
'</div>' +
'<div class="tooltip-container">' +
'<button onclick="InsertCodeBlock()" class="fa fa-code"></button>' +
'<div class="tooltip-text">Код</div>' +
'</div>' +
'<div class="tooltip-container">' +
'<button onclick="InsertLinePrefix(\'- \')" class="fa fa-list-ul"></button>' +
'<div class="tooltip-text">Неупорядоченный список</div>' +
'</div>' +
'<div class="tooltip-container">' +
'<button onclick="InsertOList()" class="fa fa-list-ol"></button>' +
'<div class="tooltip-text">Упорядоченный список</div>' +
'</div>' +
'<div class="tooltip-container">' +
'<button onclick="InsertLinePrefix(\'- [x] \')" class="fa fa-check"></button>' +
'<div class="tooltip-text">Флажок, чекбокс, галочка</div>' +
'</div>' +
'<div class="tooltip-container">' +
'<button onclick="InsertLink()" class="fa fa-link"></button>' +
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
</script>
<style>
:root {
--main-color: rgb(31, 31, 31);
--text-color: white;
--text-darker-color: gray;
--light-color: rgb(50, 50, 50);
}
* {
color: var(--text-color);
}
:link,
:visited {
color: #58a6ff;
}
html {
font-family: "Inter", Tahoma, Geneva, Verdana, sans-serif;
background-color: rgb(21, 21, 21);
tab-size: 4;
}
#nameInput {
background-color: var(--main-color);
}
.petition {
color: var(--text-color);
background-color: var(--main-color);
border-radius: 25px;
padding: 15px;
width: 100%;
box-sizing: border-box;
margin-top: 1mm;
font-family: "Inter", Tahoma, Geneva, Verdana, sans-serif;
}
.markdown_input {
border: 1px solid gray;
border-bottom-left-radius: 4px;
border-bottom-right-radius: 4px;
border-top: none;
}
textarea {
width: 100%;
height: 100%;
min-height: 15em;
resize: vertical;
box-sizing: border-box;
color: var(--text-color);
background-color: var(--main-color);
}
button {
background-color: var(--main-color);
}
.markdown_input {
min-height: 12em;
}
.markdown_rendered {
overflow: hidden;
width: 100%;
margin: 0;
padding-left: 8px;
color: var(--text-color);
box-sizing: border-box;
word-wrap: break-word;
}
textarea.petition_input {
min-height: 30em;
}
#preview {
min-height: 25em;
}
#comment_preview {
min-height: 10em;
}
img {
max-width: 75%;
height: auto;
}
code {
background-color: var(--main-color);
color: var(--text-color);
border-radius: 0.3rem;
padding: 4px 5px 5px;
white-space: nowrap;
font-family: monospace;
}
pre code {
white-space: pre;
display: block;
overflow-x: auto;
padding: 0;
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
blockquote>p {
margin-left: 1em;
text-indent: 0;
color: var(--text-darker-color)
}
table,
th,
td {
border: 1px solid;
}
table {
border-collapse: collapse;
}
#createButton {
background-color: green;
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
a,
a:visited,
a:hover,
a:active {
color: inherit;
}
.nav>li>a {
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
border-top: 1px solid #ddd;
border-right: 1px solid #ddd;
border-left: 1px solid #ddd;
border-bottom: none;
}
.nav-tabs>li {
float: left;
margin-right: 2px;
padding: 8px;
border-top-left-radius: 4px;
border-top-right-radius: 4px;
}
.nav-tabs>li.active {
cursor: default;
background-color: var(--main-color);
border-top: 1px solid #ddd;
border-right: 1px solid #ddd;
border-left: 1px solid #ddd;
}
.nav-tabs>li:not(.active) {
cursor: pointer;
}
.nav-tabs>.active>a {
cursor: default;
}
.tab-pane:not(.active) {
display: none;
}
.toolbar {
justify-content: right;
padding: 8px;
display: flex;
}
.hide {
display: none;
}
.notification {
display: block;
position: fixed;
width: 290px;
height: 90px;
padding: 10px;
border-radius: 5px;
border: 1px solid black;
right: 10px;
bottom: 10px;
background-color: brown;
}
.notification .notificationCloseButton {
position: absolute;
top: 0;
right: 0;
padding: 5px;
}
.notification .notificationCloseButton:hover {
color: white;
cursor: pointer;
}
/*
Source - https://stackoverflow.com/questions/45456543/make-text-show-up-on-hover-over-button
Posted by null
Retrieved 2026-03-03, License - null
*/
.tooltip-text {
background-color: gray;
border-radius: 5px;
visibility: hidden;
text-align: center;
padding: 5px;
position: absolute;
pointer-events: none;
transform: translateX(-50%);
}
.tooltip-container:hover .tooltip-text {
visibility: visible;
opacity: 1;
}
#like_button {
background-color: black;
}
#like_button:disabled {
background-color: rgb(62, 62, 62);
}
#like_button:not(.btn_active) {
color: darkgrey;
}
#like_button:disabled.btn_won {
background-color: rgb(69, 85, 56);
}
#like_button:disabled.btn_lost {
background-color: rgb(85, 56, 56);
}
.btn_active {
color: var(--text-color);
}
.clickable {
cursor: pointer;
}
#vote_menu {
float: right;
}
.comment {
border: gray;
border-radius: 5px;
border-width: 5px;
background-color: var(--main-color);
padding: 5px;
margin-top: 5px;
}
</style>

</head>
<body>
	<label>Название: <input id="nameInput" type="text"></label>

	<hr>

	<tabs>
		<pane title="Писать">
			<textarea class="markdown_input petition_input" id="descriptionInput" placeholder="Опишите здесь свою петицию.
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

---

"></textarea>
		</pane>
		<pane title="Предпросмотр">
			<div class="markdown_input petition_input markdown_rendered" id="preview"></div>
		</pane>

		<input id="createButton" type="submit" value="Создать" onclick="submitPetition()">

		<details>
			<summary>Как писать петиции</summary>
			<div id="petition_writing_wiki"></div>
		</details>
	</tabs>

	<div id="notification_list" ng-controller="petitionCreatorController as notificationList">
		<div class="notification" ng-repeat="notification in Notifications">
			<span>{{notification.text}}</span>
			<div class="notificationCloseButton" onclick="gScope.Notifications = []; UpdateDigest(gScope, 50)">X</div>
		</div>
	</div>
</body>
<script>
	// Sorry for using javascript.
	// Sorry for using angular.

	var gScope = null;

	angular.module("petitionCreator", ['components'])
		.controller('petitionCreatorController', function ($scope) {
			gScope = $scope;

			var notificationList = this;
			$scope.Notifications = [];
		});


	function parseAndRender()
	{
		var textarea = $("#descriptionInput");
		var result = marked.parse(textarea.val().replace(/^[\u200B\u200C\u200D\u200E\u200F\uFEFF]/,""));
		var preview = $("#preview");
		preview.get(0).innerHTML = DOMPurify.sanitize(result);
		
		if (IsGMod())
		{
			var nameinput = $("#nameInput")
			gmod.SetDraftText(nameinput.val(), textarea.val());

			fixAncherTags();
		}
	};


	function submitPetition()
	{
		var name = ($("#nameInput").val());

		if (isWhitespaceString(name))
		{
			gScope.Notifications.push({text: "Название не может быть пустым"});
			UpdateDigest(gScope, 50);
			return;
		}
		
		var description_text = $("#descriptionInput").val();
		if (isWhitespaceString(description_text))
		{
			gScope.Notifications.push({text: "Описание не может быть пустым"});
			UpdateDigest(gScope, 50);
			return;
		}

		if (name == description_text || getWordCount(description_text) < 10)
		{
			gScope.Notifications.push({text: "Читай \"Как писать петиции\""});
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
			console.log("Imagine that a new petition was created", name, description_text);
		}

		setTimeout(() => {
			$('#createButton').removeAttr("disabled");
			gScope.Notifications.push({text: "Сервер не согласен, читай чат"});
			UpdateDigest(gScope, 50);
		}, 5000);
	}

	// Dirty hack for text input ignoring enter on linux.
	function keydown(event)
	{
		if (event.keyCode === 13 && IsGMod() && IsLinux())
		{
			document.execCommand('insertText', false /*no UI*/, "\n");
		}
		
		if(event.ctrlKey && event.code == "KeyB")
		{
			InsertTagsAroundText("**");
			event.preventDefault();
		}
		if(event.ctrlKey && event.code == "KeyI")
		{
			InsertTagsAroundText("_");
			event.preventDefault();
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

		textarea.keydown(keydown);

		if (IsGMod())
		{
			gmod.GetDraftText(function(name, desc)
			{
				$("#descriptionInput").val(desc);
				$("#nameInput").val(name);

				if (!isWhitespaceString(desc))
				{
					parseAndRender();
				}
			});
		}

		// This is awful but it's better the copypasting the wiki and maintaining it in two places.
		// This is also better then the user not reading it at all.
		fetch("https://raw.githubusercontent.com/FreeSBox/freesbox.github.io/refs/heads/master/content/docs/writing_petitions.md")
		.then(res => res.text())
		.then(text => {
			// regex magic to remove hugo header
			text = text.replace(/---(.|\n)*?---/, "");
			// regex magic to redirect the links to the public wiki
			text = text.replace(/\/docs\//, "https://freesbox.github.io/docs/");

			var result = marked.parse(text);
			var wiki = $("#petition_writing_wiki");
			wiki.get(0).innerHTML = result;

			if (IsGMod())
			{
				fixAncherTags();
			}
		})
		.catch(err => console.log(err));
	});
</script>
</html>
]]