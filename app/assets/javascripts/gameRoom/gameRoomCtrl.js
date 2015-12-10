pokerApp.controller('gameRoomCtrl', [
	'$scope',
	'$filter',
	'$rootScope',
	'$state',
	'$stateParams',
	'apiServices',
	'Pusher',
	'ngAudio',
	function ($scope, $filter, $rootScope, $state, $stateParams, apiServices, Pusher, ngAudio) {

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

		//--Sounds--
		var messageSound = ngAudio.load("audio/message.mp3");
		var newroundSound = ngAudio.load("audio/newround.mp3");
		var cardSound = ngAudio.load("audio/card.mp3");
		var checkSound = ngAudio.load("audio/check.mp3");
		var foldSound = ngAudio.load("audio/fold.mp3");
		var betSound = ngAudio.load("audio/bet.mp3");
		var winSound = ngAudio.load("audio/win.mp3");

		joinAndLoad();

		$scope.eventHandlers = {
			update: function(values, handle, unencoded) {
				$('#slider-val').text(values[0][0]);
				$scope.round.raise_bet = parseInt(values[0][0].replace('$ ', ''));
			},
			change: function(values, handle, unencoded) {
				$('#slider')[0].noUiSlider.set(values[0][0]);
			}
		};

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

		$scope.checkCardStatus = function (card) {
			return (card != null) ? !(card.indexOf("x") > -1) : false;
		};

		//--Pusher Subscriptions--
		Pusher.subscribe('gameroom-' + $stateParams.gameId, 'newplayer', function (response) {
			console.log("newplayer");
			console.log(response);
			$scope.gameRoom.players.push(response.player);
			$scope.feed.push(response.status);
		});

		Pusher.subscribe('gameroom-' + $stateParams.gameId, 'playerleft', function (response) {
			console.log("playerleft");
			console.log(response);
			var i = $scope.gameRoom.players.map(function (x) {
				return x._id;
			}).indexOf(response.player._id);

			if(i > -1){
				$scope.gameRoom.players.splice(i, 1);
				$scope.feed.push(response.status);
			}
		});

		Pusher.subscribe('gameroom-' + $stateParams.gameId, 'status', function (status) {
			console.log(status);
			$scope.gameRoom.active = status;
			$scope.round.cards = [];
			$scope.feed.push("Waiting for players");
			$scope.startDisabled = false;
		});

		Pusher.subscribe('gameroom-' + $stateParams.gameId, 'newround', function (response) {
			console.log("new round");
			console.log(response);
			newroundSound.play();
			$scope.gameRoom.active = true;
			$scope.gameRoom.players = response.players;
			$scope.round = response.newround.round;
			$scope.round.cards = response.newround.cards;
			$scope.feed.push(response.status);
			getHands();
		});

		Pusher.subscribe('gameroom-' + $stateParams.gameId, 'turn', function (response) {
			console.log("new turn");
			console.log(response);
			renderHands(response.hands, response.players);
			setBets();
			$scope.feed.push(response.status);

			switch(response.sound){
				case 0:
					foldSound.play();
					break;
				case 1:
					checkSound.play();
					break;
				case 2:
					betSound.play();
					break;
			}
		});

		Pusher.subscribe('gameroom-' + $stateParams.gameId, 'stage', function (response) {
			console.log("new stage");
			console.log(response);
			$scope.round.cards = response.cards;
			$scope.round.pot = response.pot;
			$scope.round.stage = response.stage;
			renderHands(response.hands.state, response.players);
			if (response.hands.cards != null) {
				renderCards(response.hands.cards);
			}
			$scope.feed.push(response.status);

			if ($scope.round.stage == 5 || response.finished){
				$scope.round.result = response.status;
				$scope.turn = false;

				var i = response.winners.map(function (w) {
					return w.owner._id;
				}).indexOf($rootScope.user._id);

				if(i > -1){
					winSound.play();
				}
			}else{
				if($scope.round.stage == 2){
					cardSound.loop = 2;
					cardSound.play();
				}else{
					cardSound.loop = 0;
					cardSound.play();
				}
			}
		});

		Pusher.subscribe('gameroom-' + $stateParams.gameId, 'chat', function (message) {
			$scope.messages.push(message);
			if(message.user._id != $rootScope.user._id){
				messageSound.play();
			}
		});

		//--Private Funcs--
		function joinAndLoad() {
			apiServices.GameService.Join($stateParams.gameId, parseInt($state.params.bIn)).success(function (result) {
				$scope.gameRoom = result;

				apiServices.GameService.Players($stateParams.gameId).success(function (result) {
					$scope.gameRoom.players = result;
				});

				if ($scope.gameRoom.active) {
					apiServices.GameService.GetRound($stateParams.gameId).success(function (result) {
						$scope.round = result.round;
						$scope.round.cards = result.cards;

						getHands();
					}).error(function (error){
						$rootScope.error = false;
					});
				}
			});
		}

		function start() {
			$scope.startDisabled = true;
			apiServices.GameService.Start($stateParams.gameId);
		}

		function getHands() {
			apiServices.RoundService.GetHand($scope.round._id).success(function (result) {
				renderHands(result.state);
				renderCards(result.cards, result.default_card);
				setBets();
				$scope.feed.push(result.status)
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

			if(!$filter('isEmpty')(player[0].hand)){
				chips = player[0].chips + player[0].hand.bet;

				$scope.betMatches = (player[0].hand.bet == $scope.round.call_bet);
				$scope.allInRaise = ($scope.round.raise_bet >= chips);
				$scope.allInCall = ($scope.round.call_bet >= chips);
			}

			$scope.sliderOptions = {
				start: $scope.round.call_bet,
				connect: 'lower',
				step: $scope.round.big_blind,
				range: {min: $scope.round.call_bet,	max: chips},
				format: {
					to: function ( value ) {
						return '$ ' + Math.round(value);
					},
					from: function ( value ) {
						return Math.round(value.replace('$ ', ''));
					}
				}
			};
		}

		function sendTurn(bet) {
			apiServices.RoundService.SendTurn($scope.round._id, {bet: bet});
		}

		function renderHands(hands, players) {
			$scope.turn = false;

			angular.forEach($scope.gameRoom.players, function (p) {
				if (players != null) {
					var player = players.filter(function (newplayer) {
						return newplayer._id == p._id;
					});

					if(!$filter('isEmpty')(player)){
						p.chips = player[0].chips;
					}
				}

				var hand = hands.filter(function (h) {
					return h.player_id == p._id;
				});

				if (!$filter('isEmpty')(hand) && $scope.round.player_ids.indexOf(p._id) > -1) {
					keepCards = (p.hand != null && p.hand.cards != null);

					if (keepCards){
						c = p.hand.cards;
					}

					p.hand = hand[0];

					if (keepCards){
						p.hand.cards = c;
					}
				}

				if (p.hand != null && p.hand.current) {
					if(checkIfTurn(p.owner._id)){
						if(p.chips == 0){
							sendTurn(0);
						}else{
							$scope.turn = true;
						}
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