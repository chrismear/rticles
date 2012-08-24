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

  $('a.edit_paragraph').on('click', function (event) {
    event.preventDefault();
    $(event.target).closest('.paragraph_wrapper').hide();
    $(event.target).closest('.paragraph_internal').children('.edit_paragraph_form').show('fast');
  });

  $('.edit_paragraph_form a.cancel').on('click', function (event) {
    event.preventDefault();
    $(event.target).closest('.edit_paragraph_form').hide('fast');
    $(event.target).closest('.edit_paragraph_form').siblings('.paragraph_wrapper').show();
  });
});
