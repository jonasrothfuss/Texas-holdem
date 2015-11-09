pokerApp.factory('apiServices', ['$http', '$rootScope', function($http, $rootScope){
		function buildUrl(controller, action, param){
			var url = '/api/' + controller + '/';
			if(action != null){
				url += action + '/';
			}
			if(param != null){
				url += param + '/';
			}

			return url;
		}

		function call(controller, action, param, post){
			$rootScope.error = false;
			$rootScope.loading = true;

			var url = buildUrl(controller, action, param);

			if(post != null){
				return $http.post(url, post).success(function(result){
					$rootScope.loading = false;
				}).error(function(error){
					$rootScope.loading = false;
					$rootScope.error = true;
				});
			}else{
				return $http.get(url).success(function(result){
					$rootScope.loading = false;
				}).error(function(error){
					$rootScope.loading = false;
					$rootScope.error = true;
				});
			}
		};

		return {
			GameService:{
				GetRooms: function(){
					return call('gameroom');
				},
				Create: function(post){
					return call('gameroom', 'create', '', post);
				},
				Join: function(gameId, post){
					return call('gameroom', 'join', gameId, post);
				}
			}
		}
	}]);