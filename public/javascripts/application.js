// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

$(document).ready(function () {
  $('a.insert_paragraph').click(function (event) {
    event.preventDefault();
    $(event.target).parent('.control').siblings('.insert_paragraph_form').show('fast');
    $(event.target).parent('.control').hide();
  });
  
  $('a.cancel').click(function (event) {
    event.preventDefault();
    $(event.target).parents('.insert_paragraph_form').hide('fast');
    $(event.target).parents('.insert_paragraph_form').siblings('.control').show();
  });
});
