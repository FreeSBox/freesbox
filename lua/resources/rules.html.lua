return [[
<!--Sorry for using HTML-->
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
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
</script>
<style>
:root {
--main-color: rgb(31, 31, 31);
--text-color: white;
--text-darker-color: gray;
--light-color: rgb(50, 50, 50);
}
body {
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
color: var(--text-color);
background-color: var(--main-color);
width: 100%;
padding: 5px;
border: 1px solid #444;
border-radius: 4px;
font-size: 16px;
margin-top: 5px;
box-sizing: border-box;
}
.petition {
color: var(--text-color);
background-color: var(--main-color);
border-radius: 15px;
padding: 10px;
width: 100%;
box-sizing: border-box;
margin-top: 1mm;
font-family: "Inter", Tahoma, Geneva, Verdana, sans-serif;
}
.petition-title {
font-size: 1.2em;
font-weight: 600;
padding-bottom: 10px;
color: white;
margin-top: 0;
margin-bottom: 0;
}
.petition_index {
color: var(--text-darker-color);
}
.petition-meta {
font-size: 0.9em;
color: var(--text-darker-color);
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
height: 2em;
cursor: pointer;
color: white;
font-weight: bolder;
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
.toolbar-button {
color: var(--text-color);
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
.trash_button {
background-color: black;
color: red;
}
.like_button {
background-color: black;
}
.like_button:disabled {
background-color: rgb(62, 62, 62);
}
.like_button:not(.btn_active) {
color: darkgrey;
}
.like_button:disabled.btn_won {
background-color: rgb(69, 85, 56);
}
.like_button:disabled.btn_lost {
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
border: solid gray;
border-radius: 5px;
border-width: 1px;
background-color: var(--light-color);
margin-top: 5px;
}
.comment_content {
background-color: var(--main-color);
}
.comment_header {
border-radius: 5px;
padding: 5px;
}
</style>
</head>
<body>
	<h1>ЗАПОВЕДИ СЕРВЕРА</h1>
	<ol>
		<li>
			Заповеди не могут быть изменены.
			<br>
			<small>
				Исключениями являются:
				<ol>
					<li>Промежуток между 17.10.2025 и 17.11.2025, в который создатель в праве вносить изменения в заповеди.</li>
					<li>
						Изменения в заповеди могут быть внесены всеобщим голосованием сервера.
						<br>
						Голосование должно длиться 1 неделю, все игроки у которых <code>IsFullyAuthenticated() == true</code> должны иметь возможность голоса.
						<br>
						Допускается не более 1 голоса на SteamID полученный через <code>OwnerSteamID64()</code>.
						<br>
						При этом <code>IsFullyAuthenticated</code> и <code>OwnerSteamID64</code> должен иметь свою оригинальную логику прописанную в <code>server.so</code> или <code>server.dll</code> от facepunch.
					</li>
				</ol>
				<br>
				Все изменения можно посмотреть в нашем <a href="#" onclick="gmod.OpenURL('https://github.com/FreeSBox/freesbox/blob/master/lua/resources/rules.html')">git репозитории</a>.
			</small>
		</li>
		<li>Все игроки обязаны соблюдать <a href="#" onclick="gmod.OpenURL('https://wiki.facepunch.com/gmod/Server_Operator_Rules')">Server Operator Rules</a>.</li>
		<li>Петициям и игрокам запрещено мешать другим игрокам пользоваться системой петиций.</li>
		<li>Все результаты любой петиции могут быть отменены другой петицией.</li>
		<li>Все правила и заповеди нужно воспринимать как написано.</li>
		<li>Всё что не запрещено - разрешено.</li>
		<li>Петиции должны быть написаны на Русском или Английском языке.</li>
		<li>Запрещено создавать петицию если схожая петиция доступна для голосования. Такие петиции будут удалены.</li>
		<li>Запрещено создавать петиции без смысла/шуточные/непонятные петиции. Такие петиции будут удалены.</li>
		<li>Запрещено накручивать голоса на петициях.</li>
		<li>Запрещено создавать петиции от лица другого игрока.</li>
		<li>Запрещено удалять петиции не нарушающие заповеди.</li>
		<li>Описание/Название петиций должно быть максимально понятным, с чётким объяснением того что нужно изменить и почему. Петиции с названием/описанием вида "мне лень писать", будут удалены.</li>
		<li>Запрещено писать несколько несвязанных запросов в одну петицию.</li>
		<li>Все игроки обязаны соблюдать правила сервера.</li>
		<li>Все игроки с группой не "user" обязаны соблюдать правила для админов.</li>
		<li>
			Петиции это способ предложения изменений на сервер, предложенные изменения могут быть реализованы разными способами или не реализованы вообще по усмотрению создателя.
			<br>
			Причины не реализации предложений включают, но не ограничиваются:
			<ol>
				<li>Петиция не собрала больше положительных голосов чем отрицательных.</li>
				<li>Предложенные изменения нарушат работу сервера.</li>
				<li>Предложенные изменения требуют грандиозных вмешательств и ресурсов для создания/исправной работы.</li>
				<li>Создатель не понял предложенные изменения.</li>
			</ol>
		</li>
		<li>Запрещено скрывать истинные намеринья петиций.</li>
	</ol>

	<div id="rules_include"></div>
</body>
<style>
	:root {
		--main-color: rgb(31, 31, 31);
		--text-darker-color: gray;
		--text-color: white;
	}

	:link, :visited
	{
		color: #58a6ff;
	}

	body {
		color: var(--text-color);
		font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
	}
</style>
<script>
	var result = marked.parse(`
# Правила сервера

1. **Социальное взаимодействие и чат**
   1. Категорически запрещена целенаправленная травля. Если вы бегаете за одним и тем же игроком по всей карте, методично портите ему игру, организовываете массовый хейт или переходите на угрозы в реальной жизни (деанон).
   2. Запрещено засорять текстовый чат бессмысленными сообщениями и повторяющимися сообщениями. Исключения: использование чата для ввода команд, для своих устройств (sf/e2)
   3. Использование Soundpad и трансляция музыки в войс-чат разрешены, только если это не целенаправленная помеха конкретным игрокам. Включение оглушающих звуков, скримеров или бассбуста в людных местах (на спавне) или намеренное преследование игроков с включенным микрофоном.
   4. Запрещена реклама казино, телеграмм ботов и прочего скама. Все, что не является скамом - разрешено.
2. **Игровой процесс и строительство**
   1. Запрещено намеренно убивать, толкать или сбрасывать игроков с помощью пропов, транспортных средств или иных физических объектов, если игрок находится в режиме строительства. Также как и запрещено находясь в режиме строительства совершать вышеупомянутые действия по отношению к игрокам в PVP. Также категорически запрещено спамить и срать пропами с огромной скоростью и без адекватной на то причины. Уточняю: под понятие проп-спама не подойдет просто быстрый спавн пропов, тут имеется ввиду именно намеренные и бессмысленные попытки тем самым уронить сервер или вызвать лаги.
   2. Запрещено намеренное и систематическое убийство игроков на точках их возрождения. Строго запрещено создание автоматизированных турелей, ловушек или зон смерти (при помощи Expression 2 / StarfallEx), которые убивают игроков сразу после появления. Уточняю: очевидно так или иначе такое может случиться и не преднамеренно. Тут имеется ввиду буквально создание мясокомбината, из-за которого игрок даже не имеет шансов убежать со спавна.
   3. Запрещено застраивать пропами или силовыми полями зону спавна, делая невозможным выход из нее для новых игроков.
   4. Запрещено закрывать небо (скайбокс) гигантскими платформами, растягивать непрозрачные текстуры на весь мир или строить бессмысленные мега-структуры, которые визуально портят карту для всех остальных игроков и не несут функциональной или смысловой нагрузки. Уточняю: именно с целью испортить другим игру, сюда не входят временные испытания устройств и иные увеселительные примочки. К примеру огромное изображение ануса на весь скайбокс - очевидно нарушает другие правила, а просто растянутый черный шар - не несет никакой декоративной функции. Но иные, к примеру звездное небо или изображение пришельцев и так далее - приравнивается к увеселительным примочкам. Но если большинство игроков против - вам придется убрать "это".
   5. Строго запрещено использование любых скриптов (E2, SF), голограмм, партиклов или материалов, которые намеренно перекрывают обзор другим игрокам (ослепляют, вызывают эпилептическое мерцание на весь экран, ломают рендер).  
   **Исключения:**
      - Нету администрации на сервере, но есть нарушитель которого требуется проучить. Молоток вам в руки - бейте от души, но если выяснится что человек невиновен - вы получите сполна.
      - Игрок дал свое добровольное согласие, вошел в вашу "зону строительства" или подключился к худу самостоятельно. По поводу зоны строительства - очевидно она не должна нарушать другие правила сервера.
    6. Запрещено автоматизированно мешать свобному передвижению игрока (wire клетки и т.п.)  
    **Исключения:**
      - Использование клетки против игроков нарушающих правила, при этом необходимо соблюдать правила администрации.
    7. Запрещено создание большого количества огромных и ярких, мигающих голограмм или текстов (Textscreens), которые создают визуальный мусор и мешают ориентироваться на карте. Исключение: создание тех или иных развлекательных систем, на которые другие игроки в целом и не жалуются.
    8. Запрещена намеренная помеха игровому опыту других игроков, если они сидят у себя на базе. А также запрещено напрямую мешать строительству других игроков.
3. **Правила для администрации**
   - Философская преамбула

     Каждый игрок, включая администратора, склонен видеть мир со своей колокольни. То, что одному кажется вопиющим нарушением, другому может казаться безобидной шалостью. Администратор, который берёт на себя роль "тигра" и начинает выслеживать каждое формальное отклонение от правил, сам становится проблемой - ничуть не меньшей, чем тот, на кого он охотится.  

     Настоящая задача администратора - не наказывать, а сохранять здоровую атмосферу. Иногда лучший способ это сделать - не заметить нарушение. Иногда - сказать два слова в чате. Иногда - нажать кнопку бана. Но никогда - превращать администрирование в спорт по отлову нарушителей.  

     Помните: у вас есть право наказывать, но у вас нет обязанности наказывать всё и всех. Ваша главная обязанность - думать своей головой, оценивать контекст и применять правила так, как если бы на одной чаше весов были интересы двух ничем не отличающихся друг от друга игроков.  
   1. Принципы администрирования
      1. Принцип "Игрок прежде всего"
         1. Администратор остаётся игроком и сохраняет право на участие в игровом процессе, строительство, общение и развлечение.
         2. Запрещено использовать административные полномочия для получения игровых преимуществ, за исключением случаев тестирования механик или явного согласия окружающих игроков.
         3. Администратор не обязан находиться в режиме "постоянного патрулирования" и может не замечать нарушения, которые не влияют на его игровой опыт или опыт окружающих критическим образом.
      2. Принцип "Реакция, а не охота"
         1. Администратор не обязан инициировать расследование каждого подозрительного действия. Нарушения обрабатываются по факту очевидности или поступления жалобы.
         2. Запрещено целенаправленно выслеживать незначительные нарушения с целью наказания ("охота на ведьм"), если эти нарушения не носят системный и деструктивный характер.
         3. Администратору рекомендуется в первую очередь использовать предупреждение, устное разбирательство и призыв к осознанности, а не немедленную санкцию.
      3. Принцип "Равенство без фанатизма"
         1. Все игроки равны перед правилами независимо от личных симпатий или антипатий администратора.
         2. дминистратор не должен наказывать друзей менее строго, чем других игроков, при совершении идентичных нарушений.
         3. Администратор не должен наказывать игроков, к которым испытывает личную неприязнь, строже, чем того требует ситуация.
         4. Администратор вправе полностью делегировать наказание и разбор ситуации знакомого игрока другому администратору, если чувствует потенциальный конфликт интересов.
   2. Применение санкций
      1. Уровни вмешательства
         1. **Минимально необходимое вмешательство** - Администратор применяет самую мягкую санкцию, достаточную для прекращения нарушения. Ну или можете потрясти игрока и страшно покричать, иногда помогает и без санкций вообще.
         2. **Эскалация** - При повторных или игнорируемых нарушениях администратор вправе увеличивать строгость мер на свое усмотрение.
         3. **Игровое решение** - Если игроки могут самостоятельно прекратить нарушение (например, построить защиту от ракетных залпов, покинуть зону спавна, обойти турели), администратор не обязан вмешиваться. Не каждая ситуация требует вашего вмешательства, особенно если все игроки веселятся и воюют в своей песочнице.
      2. Виды санкций (рекомендации)  

         | Санкция             | Описание                                                          | Рекомендация                                                                                                                         |
         | ------------------- | ----------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
         | Устное замечание    | Сообщение в чат или голосовой канал о недопустимости действия     | Потрясите игрока как шейкер, напугайте его своим низким голосом (если имеется). Подходит для большинства мелких нарушений или просьб |
         | Gag/mute/slap и т.д | Мелкие, незначительные нарушения                                  |                                                                                                                                      |
         | Jail                | Ограничение передвижения, позорная клетка                         | Клетка позора, пусть посидит и над ним немного посмеются. Либо jailtp чтобы отправить подумать под скайбоксом                        |
         | Kick                | Утилитные (очистка пропов и т.д) / Принудительный выход с сервера | Ситуативные решения                                                                                                                  |
         | Ghostban            | Бан, но игрок может передвигаться по серверу                      | Строгая мера наказания, для тех кто не идет на уступки                                                                               |
         | Ban                 | Бан для совсем отбитых                                            | Высшая мера наказания - для случаев, где ghostban не поможет.                                                                        |
      3. Когда администратор может не наказывать
         1. Нарушение не очевидно - нет чётких доказательств или свидетелей.
         2. Нарушение прекратилось самостоятельно - игрок осознал ошибку и исправился.
         3. Жалоба не поступила - пострадавший игрок не выразил недовольство, а нарушение не носило массовый или демонстративный характер.
         4. Нарушение в ответ - игрок нарушил в ответ на аналогичную провокацию (применено как взаимная ответственность или предупреждение обеим сторонам).
         5. Атмосфера терпимости - большинство присутствующих игроков не возражают или участвуют в происходящем добровольно.
         6. Администратор вправе отказаться от наказания, передав вопрос на рассмотрение старшему по званию администратору или создателю, если ситуация кажется ему неоднозначной, а также если у него нету возможности исполнить приговор в исполнение.
   3. Запрещенные действия администрации
      1. Запрещено наказывать игроков на основании личной неприязни или мести.
      2. Запрещено использовать админ-команды для развлечения за чужой счет (например, подкидывание игроков, ослепление, принудительная телепортация без игровой необходимости).
      3. Запрещено наказывать за нарушения, которые не описаны в правилах сервера или заповедях. (Nulla poena sine lege - нет наказания без закона.)
      4. Запрещено подделывать логи наказаний или скрывать нарушения друзей с помощью технических ухищрений, также как и нельзя подставлять игроков под создание нарушений.
      5. Категорически запрещено брать любые разработки игроков, будь то дубликации или чипы, без согласия игрока.
         <details>
         <summary>Исключение</summary>
         Игрок ниже вас по рангу, а также нарушает заповеди вреда серверу. И даже в таком случае вы можете лишь проверить его разработку на вредность, а не украсть в личных целях.
         </details>
   4. Обработка жалоб
      1. Порядок действий
         1. При поступлении жалобы администратор обязан выслушать все стороны, если ситуация не очевидна с первого взгляда.
         2. Администратор вправе отказать в рассмотрении жалобы, если она не содержит указания на конкретное нарушение и попросту является оффтопом
         3. Администратор вправе отложить разбирательство, если в данный момент занят игровым процессом, который нельзя прервать. Исключение: это критическое нарушение, которое требует срочного вмешательства.
         4. Жалоба на игрока не является обязательством к наказанию. Администратор может ограничиться беседой, если сочтет это достаточным. Как и диаметрально противоположно может знать все предыдущие нарушения игрока и сразу выписать ему соизмеримое наказание.
      2. Приоритеты обработки
         1. **Высокий приоритет** - угрозы в реальной жизни, деанон, DDOS, NSFW-контент с реальными людьми. Рекомендуемая реакция: немедленное отключение игрока, доклад вышке.
         2. **Средний приоритет** - систематический спам, проп-спам, блокировка спавна, блиндеры. Рекомендуемая реакция: предупреждение, jail, ghostban при игнорировании.
         3. **Низкий приоритет** - единичные оскорбления, случайный проп-пуш, незначительный флуд. Рекомендуемая реакция: игнорировать или устное замечание.
         4. **На отложку** - сложные технические нарушения, баги, эсплоиты. Рекомендуемая реакция: передать создателю или старшему администратору, если оно не влияет на работоспособность сервера и игроков. В случае, если оно влияет на работу сервера, нарушает заповеди - можно предпринять необходимые действия и потом доложить.
      3. Отчётность и контроль
         1. Документирование
            1. Администратор не обязан вести детальный лог всех действий, но должен быть готов объяснить любое выданное наказание при запросе создателя или вышестоящего руководства. Не касается совсем мелких нарушений, все запомнить попросту нереально.
         2. Проверки
            1. Создатель или уполномоченное лицо вправе запросить историю наказания администратора с объяснениями.
            2. Систематическое отсутствие реакции на очевидные и повторяющиеся критические и тяжкие нарушения, о которых стало известно высшему руководящему составу, может быть основанием для пересмотра статуса администратора. Иногда админить все-таки нужно, раз вы за это взялись.
            3. Систематическое "охотничье" поведение (частые наказания за формальные нарушения, которые никому не мешали) - также основание для того, чтобы на вас обратили нежелательное внимание.
      4. Рекомендации
         1. Рекомендуется быть вежливым в общении даже с нарушителями - это снижает агрессию и повышает авторитет. Помните - вам не нужно ничего доказывать, но вам следует показать пример ответственного поведения и правильных моральных ценностей.
         2. Рекомендуется давать второй шанс игрокам, которые совершили нарушение впервые или под эмоциями. Врать не буду - даже меня иногда заносит, как и любого другого человека. Смотрите по ситуации, можно и просто отправить ненадолго охладиться, в случае чего.
         3. Рекомендуется привлекать игроков к саморегуляции - напоминать о правилах, достойном поведении а не сразу наказывать.
         4. Рекомендуется помнить: сервер существует ради удовольствия игроков, а не ради идеального соблюдения всех букв правил.
      5. Набор в администрацию
         1. Набор в администрацию проводится путем создания петиции  
            <details>
            <summary>Форма для заполнения</summary>
            В вашей петиции должна присутствовать следующая информация: STEAM ID, количество наигранных часов Garry's mod, количество наигранных часов на сервере, описание вашего опыта и описание того, почему вы считаете необходимым попасть на данную должность. Также рекомендуется рассказать о себе, ведь решать будут игроки сервера. Также ваша петиция должна содержать приятное глазу форматирование, разбивку текста и не нарушать иные правила петиций.
            </details>
         2. Петиция на роль администратора набравшая более 50% положительных голосов, но менее 85% положительных голосов, или набравшая менее 10 голов в сумме, принимается по усмотрению высшего админ состава.
         3. Петиция на роль администратора набравшая более 85% положительных голосов и более 10 голосов в сумме принимается даже при не согласии высшего админ состава.

## Глоссарий и пояснения
<details>
<summary>Оффтоп</summary>
Сообщение не по теме, мусорное сообщение или заявление
</details>

<details>
<summary>База/Зона строительства игрока</summary>
Условное локальное пространство (как правило, замкнутое помещение или ограниченный участок территории), в котором игрок сосредоточил свои строительные и творческие активности. Проект рекомендует воздерживаться от целенаправленного вмешательства в чужие зоны деятельности, включая PvP, проп-пуш и иные деструктивные действия, если иное не обусловлено игровым контекстом или явным согласием владельца зоны. Данное понятие не является юридически защищенной территорией и не влечет автоматических санкций за его нарушение.
</details>

<details>
<summary>DDOS атака</summary>
Намеренная перегрузка серверного оборудования множественными ложными сетевыми запросами с целью выведения сервера из строя.
</details>

<details>
<summary>Блиндер</summary>
Всё, что специально закрывает обзор игроку (текстуры, пропы, эффекты).
</details>

<details>
<summary>Скам (Обман)</summary>
Умышленное неисполнение принятых на себя обязательств в рамках внутриигровой сделки (обмен предметами, дубликатами, валютой), сопровождающееся безвозмездным изъятием активов или сервисов другой стороны. Обещал одно - сделал другое, забрал деньги/вещи и слился.
</details>

<details>
<summary>Спам</summary>
Одно и то же сообщение от трех раз подряд.
</details>

<details>
<summary>Флуд</summary>
Бессмыслица в чате и войсе. «ааааа», «щшгшгшщ», пищание и иной свистопердеж в микрофон. Ничего полезного.
</details>

<details>
<summary>БассБуст</summary>
Намеренное усиление низких частот в передаваемом микрофонном сигнале, приводящее к акустическим искажениям (гул, дребезжание, вибрация), создающее дискомфорт для иных участников коммуникации.
</details>

<details>
<summary>Травля (харассмент)</summary>
Систематическое преследование игрока с целью унизить, напугать или вынудить покинуть сервер. Сюда входят повторяющиеся оскорбления, угрозы, распространение лжи, сталкинг, а также любые другие действия, направленные на причинение психологического дискомфорта одному конкретному человеку. Одиночный конфликт травлей не считается, но если кто-то целенаправленно и долго достаёт одного и того же человека - это нарушение.
</details>

<details>
<summary>Сталкинг</summary>
Преследование в игре и вне игры, психологическое давление на конкретного человека или сбор информации (деанон) с целью навредить
</details>

<details>
<summary>Деанон</summary>
Умышленное распространение, публичное разглашение или передача третьим лицам реальной (персональной) информации об игроке: данные о месте жительства, учёбы, работы, контактные сведения, фотографии и иные сведения, не являющиеся общедоступными или добровольно опубликованными самим игроком. Распространение или слив реальной информации о игроке, даже если эта информация находится в открытом доступе и прийти к ней можно прийти посредствам OSINT или иных инженерно-социальных способов.
</details>

<details>
<summary>Саморегуляция</summary>
Способность игрового сообщества самостоятельно разрешать конфликтные ситуации и пресекать незначительные нарушения без вмешательства администрации, посредством устных замечаний, переговоров, игровых механизмов (например, защиты своей базы) или взаимного игнорирования. Саморегуляция является приоритетным инструментом поддержания порядка, так как сохраняет атмосферу добровольности и снижает нагрузку на административный состав.
</details>

<details>
<summary>Охотничье поведение</summary>
Систематическое и целенаправленное выслеживание администратором незначительных или формальных нарушений правил с целью применения санкций, в отсутствие обоснованных жалоб со стороны игроков и без реального вреда для игрового процесса. Охотничье поведение является злоупотреблением административными полномочиями, так как превращает администрирование из инструмента поддержания атмосферы в самоцель, создавая у игроков ощущение тотального контроля и давления.
</details>

<details>
<summary>Лог (Log)</summary>
Автоматически или вручную создаваемая запись, фиксирующая событие на сервере (выдача наказания, использование команды, подключение игрока, технический сбой и т.п.). Логи используются для контроля действий администрации, разрешения спорных ситуаций и анализа происшествий. Настоящими считаются только логи, сгенерированные серверным программным обеспечением; подделка логов категорически запрещена.
</details>

<details>
<summary>Моральные ценности проекта</summary>
Совокупность этических ориентиров, которыми руководствуется проект FreeSBox при принятии решений, не противоречащих букве правил. К ним относятся: уважение к чужому труду и творчеству, добровольность участия в конфликтах, приоритет созидания над разрушением, недопустимость психологического насилия (травли, сталкинга, деанона), а также презумпция добрых намерений (игрок по умолчанию не желает зла, пока не доказано обратное). Моральные ценности не являются прямым основанием для наказания, но учитываются при трактовке спорных ситуаций.
</details>

<details>
<summary>Атмосфера терпимости</summary>
Состояние игровой среды, при котором большинство присутствующих игроков не возражают против определённого действия, нарушения или явления, либо добровольно участвуют в нём. Наличие атмосферы терпимости является основанием для администратора воздержаться от вмешательства, даже если действие формально подпадает под описание нарушения. Атмосфера терпимости не распространяется на действия, запрещённые Заповедью 4 (Абсолютные запреты), а также на случаи, когда хотя бы один игрок явно выразил несогласие и покинуть зону действия нарушения не имеет возможности.
</details>
`);
	var rules = document.getElementById("rules_include");
	rules.setHTMLUnsafe(result);

	if (IsGMod())
	{
		fixAncherTags();
	}
</script>
</html>

]]