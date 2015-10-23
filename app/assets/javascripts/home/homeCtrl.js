'use strict';

pokerApp.controller('HomeCtrl', ['$scope', function HomeCtrl($scope){
	$scope.test = "test";
	
	
	//player doubles for game room implementation --> DELETE LATER
	$scope.players = [
	    {
	        id: 1,
	        user_id: 5,
	        buy_in: 50,
	        timestamp: Date.now(),
	        chip_amount: 400
	    },
	    {
	        id: 2,
	        user_id: 22,
	        buy_in: 40,
	        timestamp: Date.now(),
	        chip_amount: 400
	    },
	    {
	        id: 3,
	        user_id: 23,
	        buy_in: 55,
	        timestamp: Date.now(),
	        chip_amount: 800
	    }
	    ]
	
	//Game  doubles for game room implementation --> DELETE LATER
	$scope.gameRooms = [
	    {
	        id: 1,
	        name: 'BestRoom',
	        max_players: 8,
	        limit: 100,
	        active: true,
	        private_room: false,
	        players: $scope.players,
	        rounds: null,
	        current_round_id: 8,
	    },
	    {
	        id: 2,
	        name: 'BestRoom',
	        max_players: 7,
	        limit: 100,
	        active: true,
	        private_room: true,
	        players: $scope.players,
	        rounds: null,
	        current_round_id: 2,
	    },
	    {
	        id: 3,
	        name: 'BestRoom',
	        max_players: 5,
	        limit: 100,
	        active: true,
	        private_room: false,
	        players: $scope.players,
	        rounds: null,
	        current_round_id: 8,
	    },
	    {
	        id: 3,
	        name: 'BestRoom',
	        max_players: 5,
	        limit: 100,
	        active: false,
	        private_room: false,
	        players: $scope.players,
	        rounds: null,
	        current_round_id: 8,
	    }
	    
	    ]
}]);