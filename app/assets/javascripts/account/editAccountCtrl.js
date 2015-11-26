'use strict'

pokerApp.controller('editAccountCtrl', ['$scope', '$rootScope', '$state', 'apiServices', 'Auth', function($scope, $rootScope, $state, $stateParams){
  
  var saving_succesful = false
  var deleting_succesful = false

  
  $(document).ready(function(){
    
    //hide new password input field if user is logged in with facebook
    if ($(this).scope().user.uid.length > 4){
     $("#new_password_input").hide()
     $("#email_input").prop("disabled", true)
    }
    
    //Open Password Popup
    $("#editAccountButton").click( function() {
      display_password_dialogue($(this).scope().user.uid.length > 4)
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
  
  function display_password_dialogue(fb_logged_in){
    centering_actions()
    if (fb_logged_in){
      $('#password_dialogue_message').text("Are you sure want to change your account data?")
      $('#edit_account_password_form').hide()
    }
    else {
      $('#password_dialogue_message').text("Please enter your current password to save your new account information")
      $('#edit_account_password_form').show()
    }
    $('#password_dialogue').show()
  }

  function display_info_dialogue(message){
    $('#edit_account_dialogue_information').text(message)
    centering_actions()
    $('#edit_account_dialogue').show()
  }
  
  function display_delete_account_dialogue(){
    centering_actions()
    $('#delete_account_dialogue').show()
  }
  
  
  //Functions to close the dialogues
  function close_edit_account_dialogue(){
    $('.overlay-bg, #password_dialogue').hide()
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

