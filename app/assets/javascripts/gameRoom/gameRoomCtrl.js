pokerApp.controller('gameRoomCtrl', ['$scope', '$rootScope', '$stateParams', 'apiServices', 'Pusher', function ($scope, $rootScope, $stateParams, apiServices, Pusher){
	$scope.gameRoom = {};
	$scope.sending = false;
	$scope.messages = [];
	$scope.message = '';

	joinAndLoad();

	$scope.sendMessage = function(){
		if($scope.message){
			$scope.sending = true;

			apiServices.GameService.SendMessage($stateParams.gameId, {
				message: { user: $rootScope.user,	content: $scope.message }
			}).success(function(){
				$scope.sending = false;
			});

			$scope.message = '';
		}
	};

	//--Pusher Subscriptions--
	Pusher.subscribe('gameroom-' + $stateParams.gameId, 'newplayer', function(player){
		console.log("new player");
		$scope.gameRoom.players.push(player);
	});

	Pusher.subscribe('gameroom-' + $stateParams.gameId, 'chat', function(message){
		$scope.messages.push(message);
	});

	//--Private Funcs--
	function joinAndLoad(){
		apiServices.GameService.Join($stateParams.gameId, {user: $rootScope.user}).success(function (result){
			$scope.gameRoom = result;
		});
	}

}]);