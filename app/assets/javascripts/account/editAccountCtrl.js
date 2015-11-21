'use strict'

pokerApp.controller('editAccountCtrl', ['$scope', '$rootScope', '$state', 'apiServices', 'Auth', function($scope, $rootScope, $state, $stateParams){
  
  var saving_succesful = false
  var deleting_succesful = false
  
  var postData = function(){
    console.log("POST FUNCTION")
    apiServices.AccountService.EditAccount(getFormData())
    alert('POST FUNCTION')
  }
  
  $(document).ready(function(){
    
    //Open Password Popup
    $("#editAccountButton").click( function() {
      display_edit_account_dialogue()
    })
    
    //Open Delete Dialogue
    $("#deleteAccountButton").click( function() {
      display_delete_account_dialogue()
    })
    
    //Submit edit account request
    $("#passwordFormSaveButton").unbind().click( function() {
      var formData = $.merge($("#editaccountform").serializeArray(),$("#edit_account_password_form").serializeArray())
      
      $.post( "api/account/edit", formData, function(data) {
        if (data.succesful == true) {
          update_user_view(data)
          saving_succesful = true
        }
        else {
        }
        close_edit_account_dialogue()
        display_info_dialogue(data.message)
        
      }, "json").error(function(){
        close_edit_account_dialogue()
        display_info_dialogue("Account data could not be updated, please try again")
        }
    )})
    
    //Submit delete account request
    $("#delete_account_confirm_button").unbind().click( function() {
      var password = $("#delete_account_password_form").serializeArray()
      $.post( "api/account/delete", password, function(data) {
        if (data.succesful == true) {
          deleting_succesful = true
          close_delete_account_dialogue()
          display_info_dialogue(data.message)
        }
        else {
          close_delete_account_dialogue()
          display_info_dialogue(data.message)
        }
      }, "json").error(function(){
        close_delete_account_dialogue()
        display_info_dialogue("Account could not be deleted. Please try it again")
        }) 
    })
    
    //Hide Password Popup when clicking on the cancel button
    $("#passwordFormCancelButton").click( function() {
      close_edit_account_dialogue()
    })
    
    //Hide Popups when pressing esc key
    $(document).keyup(function(e) {
        if (e.keyCode == 27) { // if user presses esc key
          close_edit_account_dialogue()
          close_delete_account_dialogue()
        }
    })
    
    //Hide info dialogue when clicking on ok button
    $("#edit_account_dialogue_ok_button").click( function() {
      close_info_dialogue()
      if (saving_succesful){
        saving_succesful = false
        $state.go('account')
      }
      if (deleting_succesful){
        deleting_succesful = false
        location.reload()
      }
    })
    
    //Hide Password Popup when clicking on the cancel button
    $("#delete_account_cancel_button").click( function() {
      close_delete_account_dialogue()
    })
    
  })
  
  //Functions to popup dialogues
  
  function display_edit_account_dialogue(){
    centering_actions()
    $('.overlay-content').show().css({'top': scrollTop+20+'px'})
  }

  function display_info_dialogue(message){
    $('#edit_account_dialogue_information').text(message)
    centering_actions()
    $('#edit_account_dialogue').show().css({'top': scrollTop+20+'px'})
  }
  
  function display_delete_account_dialogue(){
    centering_actions()
    $('#delete_account_dialogue').show().css({'top': scrollTop+20+'px'})
  }
  
  
  //Functions to close the dialogues
  function close_edit_account_dialogue(){
    $('.overlay-bg, .overlay-content').hide()
    $("#edit_account_password_form").trigger('reset')
  }

  function close_info_dialogue(){
    $('.overlay-bg, #edit_account_dialogue').hide()
    $('#edit_account_dialogue_information').text("")
  }
  
  function close_delete_account_dialogue(){
    $(".overlay-bg, #delete_account_dialogue").hide()
    $("#delete_account_password_form").trigger('reset')
  }
  
  
  //Updates the frontend user model after the model in the backend has been succesfully updated
  function update_user_view(response_data){
    $scope.user.first_name = response_data.first_name
    $scope.user.last_name = response_data.last_name
    $scope.user.email = response_data.email
    $scope.user.username = response_data.username
  }
  
  //Helper function to centering the user dialogues
  function centering_actions(){
    var docHeight = $(document).height() 
    var scrollTop = $(window).scrollTop()
    $('.overlay-bg').show().css({'height' : docHeight})
  }
}])

