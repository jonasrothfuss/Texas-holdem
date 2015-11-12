pokerApp.controller('gameRoomCtrl', [
	'$scope',
	'$rootScope',
	'$state',
	'$stateParams',
	'apiServices',
	'Pusher',
	function ($scope, $rootScope, $state, $stateParams, apiServices, Pusher) {

		$scope.gameRoom = {};
		$scope.sending = false;
		$scope.messages = [];
		$scope.message = '';

		joinAndLoad();

		$scope.start = function(){
			start();
		};

		$scope.leaveRoom = function () {
			leave();
		};

		$scope.sendMessage = function () {
			if ($scope.message) {
				$scope.sending = true;

				apiServices.GameService.SendMessage($stateParams.gameId, {
					message: {user: $rootScope.user, content: $scope.message}
				}).success(function () {
					$scope.sending = false;
				});

				$scope.message = '';
			}
		};

		//--Pusher Subscriptions--
		Pusher.subscribe('gameroom-' + $stateParams.gameId, 'newplayer', function (player) {
			$scope.gameRoom.players.push(player);
		});

		Pusher.subscribe('gameroom-' + $stateParams.gameId, 'playerleft', function (player) {
			var i = $scope.gameRoom.players.map(function(x) {return x._id; }).indexOf(player._id);
			$scope.gameRoom.players.splice(i, 1);
		});

		Pusher.subscribe('gameroom-' + $stateParams.gameId, 'newround', function (round) {
			console.log("game has started");
			$scope.round = round;
		});

		Pusher.subscribe('gameroom-' + $stateParams.gameId, 'chat', function (message) {
			$scope.messages.push(message);
		});

		//--Private Funcs--
		function joinAndLoad() {
			apiServices.GameService.Join($stateParams.gameId, {user: $rootScope.user}).success(function (result) {
				$scope.gameRoom = result;

				apiServices.GameService.Players($stateParams.gameId).success(function (result) {
					$scope.gameRoom.players = result;
				});
			});
		}

		function start(){
			apiServices.GameService.Start($stateParams.gameId, {user: $rootScope.user}).success(function(result){
				$scope.gameRoom.active = true;
			});
		}

		function leave() {
			apiServices.GameService.Leave($stateParams.gameId, {user: $rootScope.user}).success(function () {
				$state.go('home');
			});
		}

	}]);