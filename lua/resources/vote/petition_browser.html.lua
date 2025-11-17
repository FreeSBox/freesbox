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
</head>
<body>
	<div id="petition_list" ng-controller="petitionBrowserController as petitionList">
		<!--
			If there is a bug where there aren't enough petitions to fill the screen, so we never request more - remove infinite-scroll-immediate-check
			But this should never happen, since we are using a 800x600 window for petitions with 16 petitions per request.
		-->
		<div infinite-scroll='loadMore()' infinite-scroll-distance='1' infinite-scroll-immediate-check="false">
			<div class="petition" ng-repeat="petition in Petitions | orderBy:'-creation_time'">
				<a id="petitionName" ng-click='petitionClicked(petition)'>{{petition.name}}</a>
				<span style="float: right;">Автор: {{petition.author}}</span>
				<br>
				<br>
				<span>Добавлено: {{petition.creation_time*1000 | date:'d.M.yy H:mm'}}</span>
				<br>
				<span>Открыто до: {{petition.expire_time*1000 | date:'d.M.yy H:mm'}}</span>
				<div id="vote_menu">
					<button ng-disabled="petition.expired" ng-click="likeClicked(petition)" id="like_button" ng-class="{btn_active: petition.our_vote_status == 1, btn_won: petition.expired && petition.likes > petition.dislikes}"><i class="fa fa-thumbs-up"></i> {{petition.likes}}</button>
					<button ng-disabled="petition.expired" ng-click="dislikeClicked(petition)" id="like_button" ng-class="{btn_active: petition.our_vote_status == 2, btn_lost: petition.expired && petition.dislikes >= petition.likes}"><i class="fa fa-thumbs-down"></i> {{petition.dislikes}}</button>
				</div>
				<br>
			</div>
		</div>
	</div>
</body>
<style>
	:root {
		--main-color: rgb(31, 31, 31);
		--text-darker-color: gray;
		--text-color: white
	}

	:link, :visited
	{
		color: #58a6ff;
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

	#petitionName {
		cursor: pointer;
	}

	#vote_menu {
		float: right;
	}
</style>
<script>
	/* ng-infinite-scroll - v1.0.0 - 2013-02-23 */
	var mod;mod=angular.module("infinite-scroll",[]),mod.directive("infiniteScroll",["$rootScope","$window","$timeout",function(i,n,e){return{link:function(t,l,o){var r,c,f,a;return n=angular.element(n),f=0,null!=o.infiniteScrollDistance&&t.$watch(o.infiniteScrollDistance,function(i){return f=parseInt(i,10)}),a=!0,r=!1,null!=o.infiniteScrollDisabled&&t.$watch(o.infiniteScrollDisabled,function(i){return a=!i,a&&r?(r=!1,c()):void 0}),c=function(){var e,c,u,d;return d=n.height()+n.scrollTop(),e=l.offset().top+l.height(),c=e-d,u=n.height()*f>=c,u&&a?i.$$phase?t.$eval(o.infiniteScroll):t.$apply(o.infiniteScroll):u?r=!0:void 0},n.on("scroll",c),t.$on("$destroy",function(){return n.off("scroll",c)}),e(function(){return o.infiniteScrollImmediateCheck?t.$eval(o.infiniteScrollImmediateCheck)?c():void 0:c()},0)}}}]);
</script>
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

	angular.module("petitionBrowser", ["infinite-scroll"])
		.controller('petitionBrowserController', function ($scope) {
			gScope = $scope;

			var petitionList = this;
			$scope.Petitions = [];


			$scope.loadMore = debounce(() => {
				gmod.RequestMorePetitions()
			}, 300);

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

	function addPetition(index, name, author, likes, dislikes, our_vote_status, creation_time, expire_time) {
		var expired = expire_time*1000 <= Date.now()
		gScope.Petitions.push({ index: index, name: name, author: author, likes: likes, dislikes: dislikes, our_vote_status: our_vote_status, creation_time: creation_time, expire_time: expire_time, expired: expired });
		UpdateDigest(gScope, 50);
	};
	function updatePetition(index, name, author, likes, dislikes, our_vote_status, creation_time, expire_time) {
		var petitions = gScope.Petitions;
		var petitions_length = petitions.length;
		var expired = expire_time*1000 <= Date.now()
		for (var i = 0; i < petitions_length; i++) {
			if (petitions[i].index == index) {
				petitions[i].name = name;
				petitions[i].author = author;
				petitions[i].likes = likes;
				petitions[i].dislikes = dislikes;
				petitions[i].our_vote_status = our_vote_status;
				petitions[i].creation_time = creation_time;
				petitions[i].expire_time = expire_time;
				petitions[i].expired = expired;
				UpdateDigest(gScope, 50);
				return true;
			}
		}
		return false;
	};
	function addOrUpdatePetition(index, name, description, author, likes, dislikes, our_vote_status, creation_time, expire_time) {
		if (!updatePetition(index, name, author, likes, dislikes, our_vote_status, creation_time, expire_time)) {
			addPetition(index, name, author, likes, dislikes, our_vote_status, creation_time, expire_time);
		}
	};
	function updatePetitionVotes(index, likes, dislikes, our_vote_status) {
		var petitions = gScope.Petitions;
		var petitions_length = petitions.length;
		for (var i = 0; i < petitions_length; i++) {
			if (petitions[i].index == index) {
				petitions[i].likes = likes;
				petitions[i].dislikes = dislikes;
				petitions[i].our_vote_status = our_vote_status;
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

</html>
]]