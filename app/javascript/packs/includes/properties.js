$(function(){

  $('#show-tel').on('click', function(){
    var $this = $(this);
    $this.find("span").text( $this.data("telephone") );
  });

  $('#toggleDetails').on('click', function(){
    var details = $('#prop-details');
    details.toggleClass('open');
    $(this).text(details.hasClass('open') ? 'Show less' : 'Show more');
  });

  $('#send-message-to-agent').on('click', function(){
    var button = $(this);
    if (button.prop('disabled')) return;

    var feedback = $('#contact-feedback');

    var data = {
      property_id: $('#property_id').val(),
      first_name: $('#message-first-name').val(),
      last_name: $('#message-last-name').val(),
      email: $('#message-email').val(),
      message: $('#message-text').val()
    };

    button.prop('disabled', true);
    feedback.text('Sending...');

    $.ajax({
      url: $('#email_agent').attr('action'),
      method: 'POST',
      dataType: 'json',
      headers: {
        'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
      },
      data: data
    }).done(function(){
      $('#contact-modal .modal-body').html(
        '<p>Your message has been sent successfully!</p>'
      );
      button.remove();
    }).fail(function(xhr){
      var message;

      if (xhr.status === 422) {
        message = 'Please provide a valid name, email and message.';
      } else if (xhr.status === 429) {
        message = 'Too many requests. Please try again later.';
      } else {
        message = 'Unable to send your message. Please try again.';
      }

      feedback.text(message);
    }).always(function(){
      button.prop('disabled', false);
    });
  });

  $('#contact-modal').on('show.bs.modal', function (event) {
    var button = $(event.relatedTarget);
    var modal = $(this);
  });
});
