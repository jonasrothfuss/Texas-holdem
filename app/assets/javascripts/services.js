pokerApp.factory('apiServices', ['$http', function($http){
		return {
			GameService:{
				GetRooms: function(){
					var rooms = [];

					$http.get('/game_room.json').success(function(data) {
						angular.copy(data, rooms);
					});

					return rooms;
				},
				Create: function(post){
					return $http.post('/game_room.json', post);
				}
			}
		}
	}]);