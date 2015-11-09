'use strict';

pokerApp.controller('HomeCtrl', [
	'$scope',
	'$rootScope',
	'$uibModal',
	'apiServices',
	'Pusher',
	function ($scope, $rootScope, $uibModal, apiServices, Pusher) {
		$scope.rooms = [];

		loadRooms();

		$scope.open = function (size) {
			var modalInstance = $uibModal.open({
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

		$scope.createRoom = function (gameroom) {
			apiServices.GameService.Create({
				name: gameroom.name,
				max_players: gameroom.max_players,
				min_bet: gameroom.min_bet
			});
		};

		//--Pusher Subscriptions--
		Pusher.subscribe('gamerooms', 'new', function (gameroom) {
			$scope.rooms.push(gameroom);
		});

		//--Private funcs--
		function loadRooms() {
			apiServices.GameService.GetRooms().success(function (data) {
				angular.copy(data, $scope.rooms);
			});
		}

	}]);

pokerApp.controller('ModalInstanceCtrl', ['$scope', '$modalInstance', function ($scope, $modalInstance) {
	$scope.gameroom = {};

	$scope.ok = function () {
		$modalInstance.close($scope.gameroom);
	};

	$scope.dismiss = function () {
		$modalInstance.dismiss('cancel');
	};
}]);