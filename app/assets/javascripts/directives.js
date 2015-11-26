pokerApp
	.directive('scrollBottom', function () {
		return {
			scope: {
				scrollBottom: "="
			},
			link: function (scope, element) {
				scope.$watchCollection('scrollBottom', function (newValue) {
					if (newValue){
						$(element).scrollTop($(element)[0].scrollHeight);
					}
				});
			}
		}
	})
	.directive("fileread", [function () {
		return {
			scope: {
				fileread: "="
			},
			link: function (scope, element, attributes) {
				element.bind("change", function (changeEvent) {
					var reader = new FileReader();
					reader.onload = function (loadEvent) {
						scope.$apply(function () {
							scope.fileread = loadEvent.target.result;
						});
					}
					reader.readAsDataURL(changeEvent.target.files[0]);
				});
			}
		}
	}]);