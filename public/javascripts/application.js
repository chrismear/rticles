// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

$(document).ready(function () {
  $('a.insert_paragraph').click(function (event) {
    event.preventDefault();
    $(event.target).parent('.control').siblings('.insert_paragraph_form').show('fast');
    $(event.target).parent('.control').hide();
  });
  
  $('.insert_paragraph_form a.cancel').click(function (event) {
    event.preventDefault();
    $(event.target).parents('.insert_paragraph_form').hide('fast');
    $(event.target).parents('.insert_paragraph_form').siblings('.control').show();
  });
  
  $('a.edit_paragraph').live('click', function (event) {
    event.preventDefault();
    $(event.target).closest('.paragraph_wrapper').hide();
    $(event.target).closest('.paragraph_internal').children('.edit_paragraph_form').show('fast');
  });
  
  $('.edit_paragraph_form a.cancel').live('click', function (event) {
    event.preventDefault();
    $(event.target).closest('.edit_paragraph_form').hide('fast');
    $(event.target).closest('.edit_paragraph_form').siblings('.paragraph_wrapper').show();
  });
  
  $('.edit_paragraph_form').live('ajax:success', function (event, data) {
    $(event.target).closest('.paragraph_internal').replaceWith(data);
  });
});
