'use strict';

pokerApp.controller('HomeCtrl', ['$scope', '$uibModal', 'apiServices', 'Pusher', function HomeCtrl($scope, $uibModal, apiServices, Pusher){
	$scope.rooms = apiServices.GameService.GetRooms();

	Pusher.subscribe('gamerooms', 'new', function(gameroom){
		$scope.rooms.push(gameroom);
	});

	$scope.open = function (size) {
		var modalInstance = $uibModal.open({
			animation: $scope.animationsEnabled,
			templateUrl: 'modals/CreateGameRoom.html',
			controller: 'ModalInstanceCtrl',
			size: size,
			resolve: {
				items: function () {
					return $scope.items;
				}
			}
		});

		modalInstance.result.then(function (gameRoom) {
			$scope.createRoom(gameRoom)
		}, function () {
			$log.info('Modal dismissed at: ' + new Date());
		});
	};

	$scope.createRoom = function(gameroom){
		apiServices.GameService.Create({
			name: gameroom.name,
			max_players: gameroom.max_players,
			min_bet: gameroom.min_bet,
		});
	}
}]);

pokerApp.controller('ModalInstanceCtrl', ['$scope', '$modalInstance', function ModalInstanceCtrl($scope, $modalInstance){
	$scope.gameroom = {};

	$scope.ok = function () {
		$modalInstance.close($scope.gameroom);
	};

	$scope.dismiss = function () {
		$modalInstance.dismiss('cancel');
	};
}]);