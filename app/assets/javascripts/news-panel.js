var editNewsPanel = function(news_id, company_count) {
    var prevEdit = $(".edit-news-block:visible");

    if (company_count == 0)
        $('#news-companies-' + news_id).show();
    if (prevEdit.attr("id") != news_id)
        prevEdit.hide('slow');
    $('#' + news_id).slideToggle('slow');
    prevEdit.find(".more-details").hide('slow');
    prevEdit.find(".news-companies").hide('slow');
    prevEdit.find('.expand-view').html('Show More');
    $("#error").html('');
}

var toggleExpandedView = function(news_id, company_count) {
    var expand_view = $('#expand-view-' + news_id)
    var news_companies = $('#news-companies-' + news_id)
    $('#more-' + news_id).slideToggle('slow');

    if (company_count == 0 && !news_companies.is(":visible")) {
        news_companies.slideDown('slow')
    } else if (company_count > 0) {
        news_companies.slideToggle('slow');
    }

    if (expand_view.html() == 'Show More') {
        expand_view.html('Show Less');
    } else {
        expand_view.html('Show More');
    }
}

var hideEditNewsPanel = function(el, news_id) {
    $('#more-' + news_id).hide('slow');
    $('#news-companies-' + news_id).hide('slow')
    el.closest('.edit-news-block').hide('slow')
    $(".news-companies, div#more-" + news_id).css('display', 'none');
}

var changeNewsState = function(news_id, new_state) {
    $.ajax({
        url : '/admin/news/toggle_state',
        data : 'id=' + news_id + "&state=" + new_state,
        type : 'get',
        dataType : 'json',
        success: function(data) {
           if(data.valid)
            {
                if(new_state == "block")
                    {
                        $('#news-'+news_id+' tr:first-child').css('background-color','lightgray')
                    }else
                     {
                         $('#news-'+news_id+' tr:first-child').css('background-color','#87D48D')
                     }   
                        
                
                hideBlockLockRow(data.news);
            }    
            
        }
    });
}

var hideBlockLockRow = function(news_id) {
//    hideEditNewsPanel($("#" + news_id), news_id);
//    blockRow(news_id);
//    lockedNewsIds.push(news_id);
}

var deleteNews = function(news_id) {
    if (confirm('Are You Sure?')) {
        $.ajax({
            url : '/admin/news/'+news_id,
            dataType : 'json',
            type : 'delete',
            data:{'_method': 'delete'},
            beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
            success: function(dataq) {
                 $('tbody#news-'+dataq.news).fade()
            }
        });
    }
}

var blockRow = function(news_id) {
    var dis_tr = $("input[name=state-" + news_id + "]").closest('tr');
    dis_tr.block_row({
        message : null,
        overlayCSS : {
            backgroundColor : "#FFFFFF"
        }
    });
}

var unblockRow = function(news_id) {
    var dis_tr = $("input[name=state-" + news_id + "]").closest('tr');
    dis_tr.unblock_row();
}

var lockNews = function() {
    $.ajax({
        url : '/admin/news/lock_news',
        type : 'get',
        data : 'locked_news_ids=' + JSON.stringify(lockedNewsIds)
    });
}

var unlockNews = function() {
    $.ajax({
        url : '/admin/news/unlock_news',
        type : 'get',
        data : 'locked_news_ids=' + JSON.stringify(lockedNewsIds)
    });
}

var hideDeletedNews = function() {
    $.ajax({
        url : '/admin/news/hide_destroyed_news',
        type : 'get',
        data : 'initial_news_ids=' + JSON.stringify(initialNewsIds)
    });
}

// For button controls
var buttonControls = function() {
    $("#add-news").button({
        icons: {
            primary: "ui-icon-plusthick"
        }
    });
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

// Functions added to block/unblock table rows by using blockUI jquery library
$.fn.block_row = function(opts) {
    row = $(this)
    height = row.height();
    $('td, th', row).each(function() {
        cell = $(this);
        cell.wrapInner('<div class="holderByBlock container" style="width:100%; height: ' + height + 'px; overflow: hidden;"></div>');
        cell.addClass('cleanByBlock');
        cell.attr('style', 'border: 0; padding: 0;')
        $('div.holderByBlock', cell).block(opts);
    });
};

$.fn.unblock_row = function(opts) {
    row = $(this)
    $('.cleanByBlock', row).each(function() {
        cell = $(this);
        $('div.holderByBlock', cell).unblock({
            onUnblock : function(cell, opts) {
                this_cell = $(cell).parent('td, th');
                this_cell.html($('.holderByBlock', this_cell).html());
                this_cell.removeAttr('style');
                this_cell.removeClass('cleanByBlock');
            }
        });
    });
}; 