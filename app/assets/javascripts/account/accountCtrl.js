'use strict';

pokerApp.controller('accountCtrl', ['$scope', '$rootScope', '$state', 'apiServices', 'Auth', function($scope, $rootScope, $state, $stateParams){
  
 $(document).ready(function(){
    refresh_cropit()
    
    $('#save_picture_button').click(function() {
      var imageData = $('.image-editor').cropit('export');
      $.post( "api/account/new_picture", imageData, function(data) {
        var d = new Date()
        $("#user-image").attr("src", "api/account/picture.png" + "?"+Math.random())
        $('.image-editor').hide()
        $('#user-image-container').show()
        refresh_cropit()
      })
      }).error(function(){
        $('.image-editor').hide()
        $('#user-image-container').show()
        $("#save_picture_error_dialog").show()
      })
    
    $('#add_picture_button').click(function(){
      $('.image-editor').show()
      $('#user-image-container').hide()
      
    })
    
    $('#cancel_picture_button').click(function(){
      $('.image-editor').hide()
      $('#user-image-container').show()
    })
    
    $('#save_picture_error_dialog_ok_button').click(function(){
      $("#save_picture_error_dialog").hide()
    })
  })
  
  function refresh_cropit(){
    $('.image-editor').cropit({
      exportZoom: 1.25,
      imageBackground: true,
      imageBackgroundBorderWidth: 30,
      smallImage: 'allow',
      allowDragNDrop: true,
      imageState: {
        src: 'api/account/picture.png'
      }
    })}

}])

