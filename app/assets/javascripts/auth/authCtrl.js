'use strict';

pokerApp.controller('AuthCtrl', ['$scope', '$rootScope', '$state', '$timeout', 'Auth', function AuthCtrl($scope, $rootScope, $state, $timeout, Auth){
	$rootScope.pageLoaded = true;
	$timeout(function(){$rootScope.pageLoaded = true}, 3000);

	$scope.pageClass = 'page-login';

	$scope.login = function() {
		Auth.login($scope.user).then(function(){
			$state.go('home');
		}, function(error){
			$scope.loggingIn = false;
			$scope.error = error.data.error;
		});
	};

	$scope.register = function() {
		Auth.register($scope.user).then(function(){
			$state.go('login');
		}, function(error){
			$scope.registering = false;
			$scope.error = error.data.errors;
		})
	};
}]);