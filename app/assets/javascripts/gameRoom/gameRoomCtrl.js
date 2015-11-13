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

		$scope.bet = function (bet) {
			$scope.turn = false;
			sendTurn(bet);
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

		Pusher.subscribe('gameroom-' + $stateParams.gameId, 'newround', function (response) {
			$scope.gameRoom.active = true;
			$scope.gameRoom.players = response.players;
			$scope.round = response.newround.round;
			$scope.round.cards = response.newround.cards;
			getHands();
			setBets();
		});

		Pusher.subscribe('gameroom-' + $stateParams.gameId, 'turn', function (hands) {
			renderHands(hands);
			setBets();
		});

		Pusher.subscribe('gameroom-' + $stateParams.gameId, 'stage', function (response) {
			$scope.round.cards = response.cards;
			$scope.round.pot = response.pot;
			renderHands(response.hands);
			if (response.cards != null) {
				renderCards(response.cards);
			}
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
				renderHands(result.hands);
				renderCards(result.cards, result.default_card);
				setBets();
			});
		}

		function setBets() {
			var call_bet = 0;

			angular.forEach($scope.gameRoom.players, function (p) {
				console.log(p.hand);
				if (p.hand.bet > call_bet) {
					call_bet = p.hand.bet;
				}
			});

			$scope.round.raise_bet = (call_bet == 0) ? $scope.round.big_blind : call_bet * 2;
			$scope.round.call_bet = call_bet;
		}

		function sendTurn(bet) {
			apiServices.RoundService.SendTurn($scope.round._id, {bet: bet, user: $rootScope.user});
		}

		function renderHands(hands) {
			angular.forEach($scope.gameRoom.players, function (p) {
				var hand = hands.filter(function (h) {
					return h.player_id == p._id;
				});

				if (!$filter('isEmpty')(hand) && $scope.round.player_ids.indexOf(p._id) > -1) {
					p.hand = hand[0];
				}

				if (p.hand.current) {
					checkIfTurn(p.owner._id);
				}
			});
		}

		function renderCards(gamecards, default_card) {
			angular.forEach($scope.gameRoom.players, function (p) {
				var cards = gamecards.filter(function (c) {
					return c.player_id == p._id
				});

				if (!$filter('isEmpty')(cards)) {
					p.hand.cards = cards[0].gamecards;
				} else {
					p.hand.cards = [];
					for (var i = 0; i < 2; i++) {
						p.hand.cards[i] = default_card;
					}
				}
			});
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