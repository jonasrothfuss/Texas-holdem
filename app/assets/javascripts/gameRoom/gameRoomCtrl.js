pokerApp.controller('gameRoomCtrl', [
	'$scope',
	'$filter',
	'$rootScope',
	'$state',
	'$stateParams',
	'apiServices',
	'Pusher',
	function ($scope, $filter, $rootScope, $state, $stateParams, apiServices, Pusher) {

		$scope.gameRoom = {};
		$scope.round = {};
		$scope.turn = false;
		$scope.sending = false;
		$scope.messages = [];
		$scope.message = '';

		joinAndLoad();

		$scope.start = function () {
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
			var i = $scope.gameRoom.players.map(function (x) {
				return x._id;
			}).indexOf(player._id);
			$scope.gameRoom.players.splice(i, 1);
		});

		Pusher.subscribe('gameroom-' + $stateParams.gameId, 'newround', function (result) {
			$scope.gameRoom.active = true;
			$scope.gameRoom.players = result.players;
			$scope.round = result.newround.round;
			$scope.round.cards = result.newround.cards;
			getHands();
		});

		Pusher.subscribe('gameroom-' + $stateParams.gameId, 'turn', function (player) {
			renderTurn(player);
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

				if ($scope.gameRoom.active) {
					apiServices.GameService.GetRound($stateParams.gameId).success(function (result) {
						$scope.round = result.round;
						$scope.round.cards = result.cards;

						getHands();
					});
				}
			});
		}

		function start() {
			apiServices.GameService.Start($stateParams.gameId, {user: $rootScope.user});
		}

		function getHands() {
			apiServices.RoundService.GetHand($scope.round._id, {user: $rootScope.user}).success(function (result) {
				angular.forEach($scope.gameRoom.players, function (k) {
					var hand = result.hands.filter(function (h) {
						return h.player_id == k._id;
					});

					if (!$filter('isEmpty')(hand) && $scope.round.player_ids.indexOf(k._id) > -1) {
						k.hand = hand[0];
					}

					if(k.hand.current){
						checkIfTurn(k.owner._id);
					}

					var cards = result.cards.filter(function (c) {
						return c.player_id == k._id
					});

					if (!$filter('isEmpty')(cards)) {
						k.hand.cards = cards[0].gamecards;
					} else {
						k.hand.cards = [];
						for (var i = 0; i < 2; i++) {
							k.hand.cards[i] = result.default_card;
						}
					}
				});
			});
		}

		function renderTurn(player) {
			var res = $scope.gameRoom.players.filter(function (p) {
				return p._id == player.player_id
			});

			res.hand = true;

			checkIfTurn(res.owner._id)
		}

		function checkIfTurn(playerId) {
			$scope.turn = (playerId == $rootScope.user._id);
		}

		function leave() {
			apiServices.GameService.Leave($stateParams.gameId, {user: $rootScope.user}).success(function () {
				$state.go('home');
			});
		}

	}]);