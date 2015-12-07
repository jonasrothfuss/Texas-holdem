pokerApp.factory('apiServices', ['$http', '$q', '$rootScope', function($http, $q, $rootScope){
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

		function call(controller, param, action, post, loadingToast){
			var deferred = $q.defer();

			$rootScope.error = false;
			if(loadingToast == null || loadingToast == true){
				$rootScope.loading = true;
			}

			var url = buildUrl(controller, param, action);

			if(post != null){
				return $http.post(url, post).success(function(result){
					$rootScope.loading = false;
					deferred.resolve(result);
				}).error(function(error){
					$rootScope.loading = false;
					$rootScope.error = true;
					deferred.reject(error);
				});
			}else{
				return $http.get(url).success(function(result){
					$rootScope.loading = false;
					deferred.resolve(result);
				}).error(function(error){
					$rootScope.loading = false;
					$rootScope.error = true;
					deferred.reject(error);
				});
			}

			return deferred.promise;
		}

		return {
			GameService:{
				GetRooms: function(){
					return call('gameroom');
				},
				Create: function(post){
					return call('gameroom', null, 'create', post);
				},
				Join: function(gameId, buy_in){
					return call('gameroom', gameId, 'join', {"buyIn": buy_in});
				},
				Players: function(gameId){
					return call('gameroom', gameId, 'players');
				},
				Start: function(gameId, post){
					return call('gameroom', gameId, 'start', true)
				},
				GetRound: function(gameId){
					return call('gameroom', gameId, 'round');
				},
				Leave: function(gameId){
					return call('gameroom', gameId, 'leave', true);
				},
				SendMessage: function(gameId, post){
					return call('gameroom', gameId, 'message', post, false);
				}
			},
			
			RoundService:{
				GetHand: function(roundId){
					return call('round', roundId, 'hand', true);
				},
				SendTurn: function(roundId, post){
					return call('round', roundId, 'turn', post);
				}
			},

			AccountService: {
				GetPicture: function(userId){
					return call('account', userId, 'picture');
				}
			}
		};
	}]);