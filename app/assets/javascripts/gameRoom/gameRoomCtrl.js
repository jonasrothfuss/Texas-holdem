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
		$scope.betMatches = false;
		$scope.allInCall = false;
		$scope.allInRaise = false;
		$scope.sending = false;
		$scope.feed = [];
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
					message: {content: $scope.message}
				}).success(function () {
					$scope.sending = false;
				});

				$scope.message = '';
			}
		};

		//--Pusher Subscriptions--
		Pusher.subscribe('gameroom-' + $stateParams.gameId, 'newplayer', function (response) {
			$scope.gameRoom.players.push(response.player);
			$scope.feed.push(response.status);
		});

		Pusher.subscribe('gameroom-' + $stateParams.gameId, 'playerleft', function (response) {
			var i = $scope.gameRoom.players.map(function (x) {
				return x._id;
			}).indexOf(response.player._id);
			$scope.gameRoom.players.splice(i, 1);
			$scope.feed.push(response.status);
		});

		Pusher.subscribe('gameroom-' + $stateParams.gameId, 'newround', function (response) {
			$scope.gameRoom.active = true;
			$scope.gameRoom.players = response.players;
			$scope.round = response.newround.round;
			$scope.round.cards = response.newround.cards;
			$scope.feed.push(response.status);
			getHands();
		});

		Pusher.subscribe('gameroom-' + $stateParams.gameId, 'turn', function (response) {
			renderHands(response.hands, response.players);
			setBets();
		});

		Pusher.subscribe('gameroom-' + $stateParams.gameId, 'stage', function (response) {
			$scope.round.cards = response.cards;
			$scope.round.pot = response.pot;
			renderHands(response.hands.state, response.players);
			if (response.hands.cards != null) {
				renderCards(response.hands.cards);
			}
		});

		Pusher.subscribe('gameroom-' + $stateParams.gameId, 'chat', function (message) {
			$scope.messages.push(message);
		});

		//--Private Funcs--
		function joinAndLoad() {
			apiServices.GameService.Join($stateParams.gameId).success(function (result) {
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
			apiServices.GameService.Start($stateParams.gameId);
		}

		function getHands() {
			apiServices.RoundService.GetHand($scope.round._id).success(function (result) {
				renderHands(result.state);
				renderCards(result.cards, result.default_card);
				setBets();
			});
		}

		function setBets() {
			var call_bet = 0;

			angular.forEach($scope.gameRoom.players, function (p) {
				if (p.hand != null && p.hand.bet > call_bet) {
					call_bet = p.hand.bet;
				}
			});

			$scope.round.raise_bet = (call_bet == 0) ? $scope.round.big_blind : call_bet * 2;
			$scope.round.call_bet = call_bet;

			player = $scope.gameRoom.players.filter(function (p) {
				return p.owner._id == $rootScope.user._id;
			});

			$scope.betMatches = (player[0].hand.bet == $scope.round.call_bet);
			$scope.allInRaise = ($scope.round.raise_bet >= player[0].chips);
			$scope.allInCall = ($scope.round.call_bet >= player[0].chips);
		}

		function sendTurn(bet) {
			apiServices.RoundService.SendTurn($scope.round._id, {bet: bet});
		}

		function renderHands(hands, players) {
			angular.forEach($scope.gameRoom.players, function (p) {
				if (players != null) {
					var player = players.filter(function (newplayer) {
						return newplayer._id == p._id;
					});

					p.chips = player[0].chips;
				}

				var hand = hands.filter(function (h) {
					return h.player_id == p._id;
				});

				if (!$filter('isEmpty')(hand) && $scope.round.player_ids.indexOf(p._id) > -1) {
					p.hand = hand[0];
				}

				if (p.hand != null && p.hand.current) {
					if(checkIfTurn(p.owner._id)){
						if(p.chips == 0){
							sendTurn(0);
						}else{
							$scope.turn = true;
						}
					}else{
						$scope.turn = false;
					}
				}
			});
		}

		function renderCards(gamecards, default_card) {
			angular.forEach($scope.gameRoom.players, function (p) {
				var cards = gamecards.filter(function (c) {
					return c.player_id == p._id
				});

				if(p.hand != null){
					if (!$filter('isEmpty')(cards)) {
						p.hand.cards = cards[0].gamecards;
						console.log(p.hand.cards);
					} else {
						p.hand.cards = [];
						for (var i = 0; i < 2; i++) {
							p.hand.cards[i] = default_card;
						}
					}
				}
			});
		}

		function checkIfTurn(id) {
			return (id == $rootScope.user._id);
		}

		function leave() {
			apiServices.GameService.Leave($stateParams.gameId).success(function () {
				$state.go('home');
			});
		}

	}]);