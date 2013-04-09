$(document).ready(function() {
  $('#key_genrator').click(function() {
    $.ajax({
      url: "/api_keys",
      dataType: "json",
      type: "post",
      success: function(data, textStatus, jqXHR) {
        if (data.valid) {
         $('.access_key').html(data.access_token)
         $('.org_key').html(data.organisation_key)
         $('.key_reset').attr('data_api' , data.api_id)
         $('.first_time_button').toggle()
        } 
      },
      error: function(jqXHR, textStatus, errorThrown) {
        if (jqXHR.status === 403) {
           window.location.href = "/";
        } 
      }
    })
  });
  
   $('.key_reset').click(function() {
    api_id  = $(this).attr('data_api') 
    $.ajax({
      url: "/api_keys/"+api_id,
      dataType: "json",
      type: "put",
      success: function(data, textStatus, jqXHR) {
        if (data.valid) {
         $('.access_key').html(data.access_token)
         $('.org_key').html(data.organisation_key)
        } 
      },
      error: function(jqXHR, textStatus, errorThrown) {
        if (jqXHR.status === 403) {
           window.location.href = "/";
        } 
      }
    })
  });
  
});
