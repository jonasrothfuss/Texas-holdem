pokerApp.factory('apiServices', ['$http', '$rootScope', function($http, $rootScope){
		function buildUrl(controller, param, action){
			var url = '/api/' + controller + '/';
			if(param != null){
				url += param + '/';
			}
			if(action != null){
				url += action + '/';
			}

			return url;
		}

		function call(controller, action, param, post, loadingToast){
			$rootScope.error = false;
			if(loadingToast == null || loadingToast == true){
				$rootScope.loading = true;
			}

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
					return call('gameroom', null, 'create', post);
				},
				Join: function(gameId, post){
					return call('gameroom', gameId, 'join', post);
				},
				Players: function(gameId){
					return call('gameroom', gameId, 'players');
				},
				Start: function(gameId, post){
					return call('gameroom', gameId, 'start', post)
				},
				Leave: function(gameId, post){
					return call('gameroom', gameId, 'leave', post);
				},
				SendMessage: function(gameId, post){
					return call('gameroom', gameId, 'message', post, false);
				}
			}
		}
	}]);