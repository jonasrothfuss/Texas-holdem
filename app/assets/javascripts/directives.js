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
	.directive("fileread", function () {
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
					};
					reader.readAsDataURL(changeEvent.target.files[0]);
				});
			}
		}
	})
	.directive("flipper", function() {
		return {
			restrict: "E",
			template: "<div class='flipper' ng-transclude ng-class='{flipped : flipped}'></div>",
			transclude: true,
			scope: {
				flipped: "="
			}
		};
	})
	.directive("front", function() {
		return {
			restrict: "E",
			template: "<div class='front tile' ng-transclude></div>",
			transclude: true
		};
	})
	.directive("back", function() {
		return {
			restrict: "E",
			template: "<div class='back tile' ng-transclude></div>",
			transclude: true
		}
	});