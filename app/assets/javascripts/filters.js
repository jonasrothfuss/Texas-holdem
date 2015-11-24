pokerApp
	.filter('isEmpty', function () {
		var bar;
		return function (obj) {
			for (bar in obj) {
				if (obj.hasOwnProperty(bar)) {
					return false;
				}
			}
			return true;
		};
	})
	.filter('trusted', ['$sce', function($sce){
		return function(text) {
			return $sce.trustAsHtml(text);
		};
	}])
	});