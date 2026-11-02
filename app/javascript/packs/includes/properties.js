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

  // On 422, show preserved visitor inputs and validation errors without
  // relying on inline scripts that may be blocked by Content Security Policy.
  if ($('#contact-modal .alert-danger').length && $.fn.modal) {
    $('#contact-modal').modal('show');
  }

  // Synchronize completion status with the selected transaction type.
  var listingType = $('select[name="property[for_sale]"]');
  var listingStatus = $('select[name="property[status]"]');
  if (listingType.length && listingStatus.length) {
    function syncListingStatus(){
      var sale = listingType.val() === 'true';
      listingStatus.find('option[value="sold"]').prop('disabled', !sale).prop('hidden', !sale);
      listingStatus.find('option[value="leased"]').prop('disabled', sale).prop('hidden', sale);
      if ((sale && listingStatus.val() === 'leased') || (!sale && listingStatus.val() === 'sold')) {
        listingStatus.val('available');
      }
    }
    listingType.on('change', syncListingStatus);
    syncListingStatus();
  }


});
