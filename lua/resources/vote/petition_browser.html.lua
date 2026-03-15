return [[
<!--SorryforusingHTML--><!DOCTYPEhtml><html><head><metahttp-equiv="Content-Type"content="text/html;charset=UTF-8"/><linkrel="stylesheet"href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css"><linkrel="preconnect"href="https://fonts.googleapis.com"><linkrel="preconnect"href="https://fonts.gstatic.com"crossorigin><linkhref="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap"rel="stylesheet"><scripttype="text/javascript"src="asset://garrysmod/html/js/thirdparty/jquery.js"></script><scripttype="text/javascript"src="asset://garrysmod/html/js/thirdparty/angular.js"></script><scripttype="text/javascript"src="asset://garrysmod/html/js/thirdparty/angular-route.js"></script><script>
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
.petition_input {
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
#preview {
overflow: hidden;
width: 100%;
min-height: 10em;
margin: 0;
padding-left: 8px;
color: var(--text-color);
box-sizing: border-box;
word-wrap: break-word;
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
</head><body><divid="petition_list"ng-controller="petitionBrowserControlleraspetitionList"><!--Ifthereisabugwheretherearen'tenoughpetitionstofillthescreen,soweneverrequestmore-removeinfinite-scroll-immediate-checkButthisshouldneverhappen,sinceweareusinga800x600windowforpetitionswith16petitionsperrequest.--><divinfinite-scroll='loadMore()'infinite-scroll-distance='1'infinite-scroll-immediate-check="false"><divclass="petition"ng-repeat="petitioninPetitions|orderBy:'-creation_time'"><aclass="clickable"ng-click='petitionClicked(petition)'>{{petition.name}}</a><spanstyle="float:right;">Автор:<aclass="clickable"ng-click='authorClicked(petition)'>{{petition.author_name}}</a></span><br><br><span>Добавлено:{{petition.creation_time*1000|date:'d.M.yyH:mm'}}</span><br><span>Открытодо:{{petition.expire_time*1000|date:'d.M.yyH:mm'}}</span><divid="vote_menu"><buttonng-disabled="petition.expired"ng-click="likeClicked(petition)"id="like_button"ng-class="{btn_active:petition.our_vote_status==1,btn_won:petition.expired&&petition.likes>petition.dislikes}"><iclass="fafa-thumbs-up"></i>{{petition.likes}}</button><buttonng-disabled="petition.expired"ng-click="dislikeClicked(petition)"id="like_button"ng-class="{btn_active:petition.our_vote_status==2,btn_lost:petition.expired&&petition.dislikes>=petition.likes}"><iclass="fafa-thumbs-down"></i>{{petition.dislikes}}</button></div><br></div></div></div></body><script>/*ng-infinite-scroll-v1.0.0-2013-02-23*/varmod;mod=angular.module("infinite-scroll",[]),mod.directive("infiniteScroll",["$rootScope","$window","$timeout",function(i,n,e){return{link:function(t,l,o){varr,c,f,a;returnn=angular.element(n),f=0,null!=o.infiniteScrollDistance&&t.$watch(o.infiniteScrollDistance,function(i){returnf=parseInt(i,10)}),a=!0,r=!1,null!=o.infiniteScrollDisabled&&t.$watch(o.infiniteScrollDisabled,function(i){returna=!i,a&&r?(r=!1,c()):void0}),c=function(){vare,c,u,d;returnd=n.height()+n.scrollTop(),e=l.offset().top+l.height(),c=e-d,u=n.height()*f>=c,u&&a?i.$$phase?t.$eval(o.infiniteScroll):t.$apply(o.infiniteScroll):u?r=!0:void0},n.on("scroll",c),t.$on("$destroy",function(){returnn.off("scroll",c)}),e(function(){returno.infiniteScrollImmediateCheck?t.$eval(o.infiniteScrollImmediateCheck)?c():void0:c()},0)}}}]);</script><script>//Sorryforusingjavascript.consteVoteStatus=Object.freeze({NOT_VOTED:0,LIKE:1,DISLIKE:2});vargScope=null;angular.module("petitionBrowser",["infinite-scroll"]).controller('petitionBrowserController',function($scope){gScope=$scope;varpetitionList=this;$scope.Petitions=[];$scope.loadMore=debounce(()=>{gmod.RequestMorePetitions()},300);$scope.petitionClicked=function(petition){gmod.OpenPetition(petition.index)}$scope.authorClicked=function(petition){gmod.OpenURL("https://steamcommunity.com/profiles/"+petition.author_steamid)}$scope.likeClicked=function(petition){gmod.VoteOnPetition(petition.index,false)}$scope.dislikeClicked=function(petition){gmod.VoteOnPetition(petition.index,true)}});//Manuallybootstrapangularjsbecauseotherwiseitwillcomplainaboutdocument.location.originangular.element(document).ready(function(){angular.bootstrap(document.body,['petitionBrowser']);});functionaddPetition(index,name,author_name,author_steamid,likes,dislikes,our_vote_status,creation_time,expire_time){varexpired=expire_time*1000<=Date.now()gScope.Petitions.push({index:index,name:name,author_name:author_name,author_steamid:author_steamid,likes:likes,dislikes:dislikes,our_vote_status:our_vote_status,creation_time:creation_time,expire_time:expire_time,expired:expired});UpdateDigest(gScope,50);};functionupdatePetition(index,name,author_name,author_steamid,likes,dislikes,our_vote_status,creation_time,expire_time){varpetitions=gScope.Petitions;varpetitions_length=petitions.length;varexpired=expire_time*1000<=Date.now()for(vari=0;i<petitions_length;i++){if(petitions[i].index==index){petitions[i].name=name;petitions[i].author_name=author_name;petitions[i].author_steamid=author_steamid;petitions[i].likes=likes;petitions[i].dislikes=dislikes;petitions[i].our_vote_status=our_vote_status;petitions[i].creation_time=creation_time;petitions[i].expire_time=expire_time;petitions[i].expired=expired;UpdateDigest(gScope,50);returntrue;}}returnfalse;};functionaddOrUpdatePetition(index,name,description,author_name,author_steamid,likes,dislikes,our_vote_status,creation_time,expire_time){if(!updatePetition(index,name,author_name,author_steamid,likes,dislikes,our_vote_status,creation_time,expire_time)){addPetition(index,name,author_name,author_steamid,likes,dislikes,our_vote_status,creation_time,expire_time);}};functionupdatePetitionVotes(index,likes,dislikes,our_vote_status){varpetitions=gScope.Petitions;varpetitions_length=petitions.length;for(vari=0;i<petitions_length;i++){if(petitions[i].index==index){petitions[i].likes=likes;petitions[i].dislikes=dislikes;petitions[i].our_vote_status=our_vote_status;UpdateDigest(gScope,50);returntrue;}}returnfalse;};functionclearPetitions(){gScope.Petitions=[];UpdateDigest(gScope,50);};</script></html>
]]