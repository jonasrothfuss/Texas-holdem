'use strict';

pokerApp.controller('accountCtrl', ['$scope', '$rootScope', '$state', '$http', function ($scope, $rootScope, $state, $http) {
	$scope.success = false;
	$scope.showEditor = false;
	
	/*
	$(document).ready(function(){
	  
	  //hide passowrd filds for users logged in with fb
	  if ($scope.user.uid.length > 4){
      $("#new_password_input").hide()
    $("#email_input").prop("disabled", true)
    }
	   
	 })
	 */

	$scope.save = function() {
		$scope.error = {};
		$scope.success = false;
		$rootScope.loading = true;

		$http.put('users.json', {user: $scope.user}).then(function(){
			$rootScope.loading = false;
			$scope.success = true;

			$scope.user.password = '';
			$scope.user.password_confirmation = '';
			$scope.user.current_password = '';
		}, function(error){
			$rootScope.loading = false;
			$rootScope.error = true;

			$scope.error = error.data.errors;
		});
	};

	$scope.delete = function() {
		$http.delete('users.json', {user: $scope.user}).then(function(){
			$rootScope.user = {};
			$state.go('login');
		}, function(error){
			$scope.error = error.data.errors;
		});
	};

	refresh_cropit();

	$scope.savePicture = function(){
		$rootScope.user.image = $('.image-editor').cropit('export');
		$rootScope.user.image_url = $rootScope.user.image;
		$scope.showEditor = false;
	};

	$('#save_picture_error_dialog_ok_button').click(function () {
		$("#save_picture_error_dialog").hide();
	});

	function refresh_cropit() {
		$('.image-editor').cropit({
			exportZoom: 1.25,
			imageBackground: true,
			imageBackgroundBorderWidth: 30,
			smallImage: 'allow',
			allowDragNDrop: true,
			imageState: {
				src: $rootScope.user.image_url
			}
		})
	}

}]);

