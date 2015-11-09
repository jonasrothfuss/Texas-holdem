pokerApp.controller('gameRoomCtrl', ['$scope', '$rootScope', '$stateParams', 'apiServices', 'Pusher', function ($scope, $rootScope, $stateParams, apiServices, Pusher){
	$scope.gameRoom = {};
	$scope.sending = false;
	$scope.messages = [];
	$scope.message = '';

	joinAndLoad();

	//--Pusher Subscriptions--
	Pusher.subscribe('gameroom-' + $stateParams.gameId, 'newplayer', function(player){
		console.log("new player");
		$scope.gameRoom.players.push(player);
	});

	//--Private Funcs--
	function joinAndLoad(){
		apiServices.GameService.Join($stateParams.gameId, {user: $rootScope.user}).success(function (result){
			$scope.gameRoom = result;
		});
	}

}]);