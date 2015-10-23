'use strict';

var pokerApp = angular.module('poker', ['ui.router', 'templates', 'Devise', 'ngAnimate'])

	// AngularJS States => Routes
	.config(['$stateProvider', '$urlRouterProvider', function ($stateProvider, $urlRouterProvider){
		$stateProvider
		
			.state('login', {
				url: '/login', templateUrl: 'login.html',	controller: 'AuthCtrl',
				onEnter: ['$state', 'Auth', function ($state, Auth){
					Auth.currentUser().then(function (user){
						$state.go('home');
						console.log(user);
					}, function(error){
						console.log("Not Authenticated");
					});
				}]
			})
			
			.state('register', {
				url: '/register', templateUrl: 'register.html',	controller: 'AuthCtrl',
				onEnter: ['$state', 'Auth', function ($state, Auth){
					Auth.currentUser().then(function (user){
						$state.go('home');
						console.log(user);
					}, function(error){
						console.log("Not Authenticated");
					});
				}]
			})
			
			.state('home', {
				url: '/home', templateUrl: 'home.html',	controller: 'HomeCtrl',
				onEnter: ['$state', 'Auth', function ($state, Auth){
					Auth.currentUser().then(function(user) {
						// User was logged in, or Devise returned
						// previously authenticated session.
						console.log("authenticated");
					}, function(error) {
						$state.go('login');
					});
				}]
			})
			
			.state('gameRoom', {
				url: '/gameRoom', templateUrl: 'gameRoom.html',	controller: 'GameRoomCtrl',
				onEnter: ['$state', 'Auth', function ($state, Auth){
					Auth.currentUser().then(function(user) {
						// User was logged in, or Devise returned
						// previously authenticated session.
						console.log("authenticated");
					}, function(error) {
						$state.go('login');
					});
				}]
			});


		$urlRouterProvider.otherwise('login');
	}]);