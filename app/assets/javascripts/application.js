// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require twitter/bootstrap

//= require_tree .

var toggleDisplay = function (id) {
    ele = document.getElementById(id);
    if (ele.style.display == "none") {
        ele.style.display = "block";
    }
    else {
        ele.style.display = "none";
    }
}
var openPopup = function (url, popup_id, percent) {
    if (typeof (percent) === 'undefined')
        percent = 60;

    if (screen) {
        w = screen.availWidth * percent / 100;
        h = screen.availHeight * percent / 100;
    }

    var features = "top=" + (screen.height - h) + ", left=" + (screen.width - w) + ", width=" + w + ", height=" + h + ", scrollbars=1";
    window.open(url, popup_id, features);
}


var updateNewsType = function(newsId, newVal) {
    var el = $('#news-type-select-' + newsId);
    $(el).attr('disabled', 'disabled');

    $.ajax({
        url: '/admin/news/update_news_type',
        data: 'news_id=' + newsId + '&news_type_id=' + newVal,
        success: function() {
            $(el).removeAttr('disabled');
        },
        error: function() {
            $(el).removeAttr('disabled');
        }
    })
}


    $(document).ready(function() {
        jQuery('#all_feed_table').dataTable({
            sPaginationType:"full_numbers",
            "bJQueryUI":true,
            "sDom":'T<"clear">lfrtip'
        })
        
        jQuery('#day_feed_table').dataTable({
            sPaginationType:"full_numbers",
            "bJQueryUI":true,
            "sDom":'T<"clear">lfrtip'
        })
        jQuery('#week_feed_table').dataTable({
            sPaginationType:"full_numbers",
            "bJQueryUI":true,
            "sDom":'T<"clear">lfrtip'
        })
        
    })

