return [[
<!--Sorry for using HTML-->
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
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
<script type="text/javascript" src="https://cdn.jsdelivr.net/npm/dompurify@3.3.1/dist/purify.min.js"></script>
<script type="text/javascript" src="https://cdn.jsdelivr.net/npm/marked@15.0.12/marked.min.js"></script>
</head>
<body ng-controller="petitionViewerController as petitionViewer">
	<label>{{Petition.name}}</label>
	<span style="float: right;">Автор: <a class="clickable" ng-click='authorClicked()'>{{Petition.author_name}}</a></span>
	<br>
	<span style="float: right;">Index: {{Petition.index}}</span>
	<br>

	<span>Добавлено: {{Petition.creation_time*1000 | date:'d.M.yy H:mm'}}</span>
	<br>
	<span>Открыто до: {{Petition.expire_time*1000 | date:'d.M.yy H:mm'}}</span>

	<div id="vote_menu">
		<button ng-disabled="Petition.expired" ng-click="likeClicked()" id="like_button" ng-class="{btn_active: Petition.our_vote_status == 1, btn_won: Petition.expired && Petition.likes > Petition.dislikes}"><i class="fa fa-thumbs-up"></i> {{Petition.likes}}</button>
		<button ng-disabled="Petition.expired" ng-click="dislikeClicked()" id="like_button" ng-class="{btn_active: Petition.our_vote_status == 2, btn_lost: Petition.expired && Petition.dislikes >= Petition.likes}"><i class="fa fa-thumbs-down"></i> {{Petition.dislikes}}</button>
	</div>

	<hr>

	<div id="preview"></div>
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

	blockquote > p {
		margin-left: 1em;
		text-indent: 0;
		color: var(--text-darker-color)
	}

	table, th, td {
		border: 1px solid;
	}
	table {
		border-collapse: collapse;
	}

	#like_button {
		background-color: black;
	}
	#like_button:disabled {
		background-color:rgb(62, 62, 62);
	}
	#like_button:not(.btn_active) {
		color: darkgrey;
	}
	#like_button:disabled.btn_won {
		background-color:rgb(69, 85, 56);
	}
	#like_button:disabled.btn_lost {
		background-color:rgb(85, 56, 56);
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

	const eVoteStatus = Object.freeze({
		NOT_VOTED: 0,
		LIKE: 1,
		DISLIKE: 2
	});

	var gScope = null;

	angular.module("petitionViewer", [])
		.controller('petitionViewerController', function ($scope) {
			gScope = $scope;

			$scope.Petition = {};

			$scope.authorClicked = function () {
				gmod.OpenURL("https://steamcommunity.com/profiles/" + gScope.Petition.author_steamid)
			}

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

	var parseAndRender = function(description) {
		var result = marked.parse(description.replace(/^[\u200B\u200C\u200D\u200E\u200F\uFEFF]/,""));
		var preview = $("#preview");
		preview.get(0).innerHTML = DOMPurify.sanitize(result);

		$('a').click(function(e) {
			// This is not for safety, but so we don't open empty links.
			if (e.currentTarget.href.startsWith("http"))
			{
				e.preventDefault();
				gmod.OpenURL(e.currentTarget.href)
			}
		});
	};

	function addOrUpdatePetition(index, name, description, author_name, author_steamid, likes, dislikes, our_vote_status, creation_time, expire_time) {
		parseAndRender(description);

		var expired = expire_time*1000 <= Date.now();

		gScope.Petition.index = index
		gScope.Petition.name = name;
		gScope.Petition.author_name = author_name;
		gScope.Petition.author_steamid = author_steamid;
		gScope.Petition.likes = likes;
		gScope.Petition.dislikes = dislikes;
		gScope.Petition.our_vote_status = our_vote_status;
		gScope.Petition.creation_time = creation_time;
		gScope.Petition.expire_time = expire_time;
		gScope.Petition.expired = expired;
		UpdateDigest(gScope, 50);
	};

	function updatePetitionVotes(index, likes, dislikes, our_vote_status)
	{
		if (gScope.Petition.index != index)
		{
			return
		}
		gScope.Petition.likes = likes;
		gScope.Petition.dislikes = dislikes;
		gScope.Petition.our_vote_status = our_vote_status;
		UpdateDigest(gScope, 50);
	}

</script>
</html>
]]