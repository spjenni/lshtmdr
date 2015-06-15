/*
 * This javascript file will be loaded after all the system files.
 * (so other javascript functions will already be loaded)
 *
 * Javascript files are loaded in alphabetic order, hence the "90"
 * in the filename to force it to load after the other files!
 *
 * To totally replace a system js file, create a file of the same
 * name in this directory. eg. 50_preview.js
 *
*/

/* Genius: http://james.padolsey.com/javascript/regex-selector-for-jquery/ */
jQuery.expr[':'].regex = function(elem, index, match) {
    var matchParams = match[3].split(','),
        validLabels = /^(data|css):/,
        attr = {
            method: matchParams[0].match(validLabels) ?
                        matchParams[0].split(':')[0] : 'attr',
            property: matchParams.shift().replace(validLabels,'')
        },
        regexFlags = 'ig',
        regex = new RegExp(matchParams.join('').replace(/^\s+|\s+$/g,''), regexFlags);
    return regex.test(jQuery(elem)[attr.method](attr.property));
}

var keep_id = [];
function hide_lshtmid(){
 
  //annoyingly hardcoded for th :|
  jQuery('th:regex(id,c[0-9]+_creators_th_6)').hide();
  jQuery('th:regex(id,c[0-9]+_contributors_th_7)').hide();
  jQuery('th:regex(id,c[0-9]+_primary_contact_th_4)').hide();
 
  //regex for inputs... :)
  //multiple
  jQuery('input:regex(id,c[0-9]+_.+_[0-9]+_lshtmid)').each(function(){
   
        jQuery(this).attr("type", "hidden");
     
  });
  //single...
  jQuery('input:regex(id,c[0-9]+_.+_lshtmid)').each(function(){
        jQuery(this).attr("type", "hidden");
     
  });
}
function auto_check_lshtmid_flag(){
//  jQuery('input:regex(id,c[0-9]+_.+(|_[0-9]+)_lshtmid)').on("change", function(){   
  //  jQuery("table.ep_form_input_grid").on("change", 'input:regex(id,c[0-9]+_.+(|_[0-9]+)_lshtmid)', function() {
  jQuery("table.ep_form_input_grid").on("change", 'input', function() {
    
    if(jQuery(this).attr("id").match(/c[0-9]+_.+(|_[0-9]+)_family/)){
			
            var id = jQuery(this).attr("id");
            var flag_id = id.replace("name_family", "lshtm_flag");
            
            if(jQuery(this).val().length == 0){
				jQuery("#"+flag_id).prop('checked', false);
			}else{
				jQuery("#"+flag_id).prop('checked', true);
      }
    }
  });
}

function sync_lshtmid_and_flag(){
//  jQuery("table.ep_form_input_grid").on("change", 'input:regex(id,c[0-9]+_.+(|_[0-9]+)_lshtmid)', function() {

  jQuery("table.ep_form_input_grid").on("change", 'input:regex(id,c[0-9]+_.+(|_[0-9]+)_lshtm_flag)', function() {
    var id = jQuery(this).attr("id");
    var lshtmid_id = id.replace("lshtm_flag","lshtmid");
    var family_id = id.replace("lshtm_flag","name_family");
    var given_id = id.replace("lshtm_flag","name_given");
    var email_id = id.replace("lshtm_flag","id");
    if(jQuery(this).is(":checked")){

      if(jQuery("#"+lshtmid_id).val().length ==0 && keep_id[id] == undefined){
//          console.log("This dude doesn't have an lshtmid we shall make one....?");
        var string = jQuery("#"+family_id).val()+jQuery("#"+given_id).val()+jQuery("#"+email_id).val();
        keep_id[id] = jQuery.md5(string);
      }

    if(keep_id[id] != undefined && keep_id[id].length > 0)
            jQuery("#"+lshtmid_id).val(keep_id[id]);

    }else{ 
               keep_id[id] = jQuery("#"+lshtmid_id).val();
        jQuery("#"+lshtmid_id).val("");   
    }
     
  });

}

function init_clear_buttons(fields){
  for(var i=0; i<fields.length; i++){
    var field = fields[i];
    var regex_str = 'td:regex(id,c[0-9]+_'+field+'_cell_2_[0-9]+)';
      jQuery(regex_str).each(function(){
             
              var tr = jQuery(this).parent("tr");
     
              if(jQuery(tr).find("td.clear_button").length>0)
               return 1;
     
              var row = jQuery(this).attr("id").replace(/^.+_([0-9]+)$/gi, function (str, group1) {
                return group1;
              });
              var row_id = field+"_"+row;
               jQuery(tr).attr("id", row_id ).append('<td class="clear_button"><a type="image" src="/display_images/close.png" alt="clear" title="Clear row" href="javascript:clear_row(\''+row_id+'\')"><img src="/display_images/close.png"></a></td>'); 
      });
    }
}

function clear_row(row_id){
  jQuery("#"+row_id+" input, #"+row_id+" select").each(function(){
    if(jQuery(this).attr("type") === "checkbox"){
      jQuery(this).attr("checked",false);
    }
    jQuery(this).val("");
  });
 
}

jQuery(document).ready(function(){
 
  //these three are also called from 87_component_field.js which reinitialises
  //stuff when it is added to the bottom
  hide_lshtmid();
  auto_check_lshtmid_flag();
  sync_lshtmid_and_flag();
  init_clear_buttons(["creators","contributors"]);
 
  jQuery( "input[value='Public::RequestCopy']" ).parent("form").submit(function(){
   
    if ( jQuery( 'input:regex(id,c[0-9]+_terms_and_conditions)' ).is( ":checked" ) ){
        //alert("yo");
    }else{
      //Taking out while T and Cs are written
      //    alert("Please confirm that you accept the terms and conditions for this dataset");
      //return false;
    }
   
  });
 
  if(jQuery("form[action='http://datacompass.lshtm.ac.uk/cgi/request_doc#t']").length > 0){
    var form = jQuery(this);
    jQuery.getJSON( "/cgi/export-ones-self", function( data ) {
          jQuery(form).find('input:regex(id,c[0-9]+_requester_name_family)').val(data["name"]["family"]);
        jQuery(form).find('input:regex(id,c[0-9]+_requester_name_given)').val(data["name"]["given"]);
          jQuery(form).find('input:regex(id,c[0-9]+_requester_name_honourific)').val(data["name"]["honourific"]);
        jQuery(form).find('input:regex(id,c[0-9]+_requester_email)').val(data["email"]);

    });
  }
});


/***********************************************************************************/
/*                         .js functions added by SJ                               */
/***********************************************************************************/
jQuery(document).ready(function(){
   /*
    //SJ: Simple logged in check to show request document link if user is not logged in//
    //future versions will need to relate login status to document security level      //
    /*
    if(jQuery("#file_security").length && eprints_logged_in == true){
      
       //get user credentials for future versions
       jQuery.getJSON( "/cgi/export-ones-self", function( data ) {
		var security = jQuery("#file_security").val();
		if(security === "staffonly" && jQuery.inArray(data.usertype,["admin","editor"]))
		      	jQuery("div#hide_request").hide();
		else if(security === "validuser")
		      	jQuery("div#hide_request").hide();

             console.log("in JSON:", data["usertype"]);
             console.log("in JSON:", security);
	     

       }) .done(function() {
	    console.log( "second success" );
	  })
	  .fail(function(e) {
	    console.log( "error: "+ e );
	  })
	  .always(function() {
		//console.log( "complete" );
	  });
     }
	*/
	
	/* SJ: extra jQuery functions for the implementation of tool tip for deposit workflow */
	//call the function to bind tooltips to help button
    load_tooltips();
   
    //config for bxslider
    jQuery('.bxslider').bxSlider({
        mode:'fade',
        infiniteLoop: true, 
        speed: 2000,
        auto: true,
        hyperlinks: true, 
        tickerHover: true, 
        pause: 9000,  
    });

	//SJ: Call to load jquery function for qr_codes
    jQuery(function()
    {
        jQuery('#ep_qrcode').qrcode({width: 75, height: 75, text: window.location.href});
    });
    
    //update the latest_tool iframe to include styling
    //required to style the front page iframe
     jQuery('iframe').load(function() {
        var frame = jQuery('iframe').contents().find("p");
        var link = jQuery('iframe').contents().find("a");
        frame.css("font-family", "Arial");
        frame.css("font-size", "0.8em");
        link.css("color","#25688F");
    });

});


//object to hold help text of each component
var help_text = {};

//redefine the behaviour of the help button on the default surround
//icon is also changed
function load_tooltips(){
    
    jQuery("img[src$='multi_down.png']").each(function() {
		jQuery(this).attr("src","/display_images/lshtm_down_arrow.gif");
	});
	
	jQuery("img[src$='multi_up.png']").each(function() {
		jQuery(this).attr("src","/display_images/lshtm_up_arrow.gif");
	});

    jQuery("[id$=_show]").each(function() {
		
        var element_id = this.id;
		
		//SJ recorrected. Should have searched for string in ID. Allows tooltips on file
		//upload form to work even if hide/show used
		if(element_id.search("opt") == -1){
		//RM contains coming up undefined
		//This will not throw error (may even be the intended use?)
		//if(jQuery.contains(this, "opt") != true){

			var link = jQuery( this ).children();
		   
			//bind to help link and switch off
			link.bind("click", function (e) {
				e.preventDefault();
			});
			//stop click blur event for help show
			link.prop("onclick", null);
			link.css('cursor','default');
			//add new help icon
			link.children().attr("src","/display_images/help_lshtm.png");
				  
			//get the help text div
			var final = element_id.replace("show", "inner");
		   
			//add help text to object
			help_text[final] = jQuery("#" + final).html();
			
			//add the tool tip to _inner_show div
			jQuery(this).tooltip({
				items: "[id]",
				content: function () {
					return jQuery("#" + final).html();
				}
			});	
		} 
    });

    /* SJ: extra jQuery functions for the implementation of date picker for deposit workflow */

    // attach a new datepicker to each date field instance in the workflow
    jQuery("[id*=_year]").each(function() {
	
	jQuery( this ).datepicker({
		showOn: "button",
		dateFormat: 'yy-mm-dd',
		buttonImage: "/display_images/calendar.png",
		buttonImageOnly: true,
		buttonText: "Select date",
		onSelect: function(date)
		{
			// get the specific instance ids for the 3 parts of the date
			var element_id = this.id;
			var day_id = element_id.replace("year", "day"); 
			var month_id = element_id.replace("year", "month"); 
			
			//	get substrings for each date part
			var yy=date.substring(0,4);
			var mm=date.substring(5,7);
			var dd=date.substring(8,11);
			
			// populate the parts of the date
			jQuery("#" + this.id).val(yy);
			jQuery("#" + day_id).val(dd);
			jQuery("#" + month_id).val(mm);
		},
	});
	
	// attach the date graphic to the field
	jQuery(".ui-datepicker-trigger").css("float","left");
	jQuery(".ui-datepicker-trigger").css("margin-right","10px");	
     });
}

//function called from 87_component.js to rebind the 
//help text tooltip to __inner_help due ajax repsonse
//component
function reinstate_tooltip(container){
       
    var container_id = container + "_content";
    	
    jQuery("#" + container_id).find('img[src$="multi_down.png"]').attr("src","/display_images/lshtm_down_arrow.gif");
    jQuery("#" + container_id).find('img[src$="multi_up.png"]').attr("src","/display_images/lshtm_up_arrow.gif");

	jQuery('div[id^='+container+']div[id$=_show]').each(function() {

		element_id = this.id;
		
		if((this.id).search("opt") == -1){
			var link = jQuery( this ).children();
		   
			//bind to help link and switch off
			link.bind("click", function (e) {
				e.preventDefault();
			});
			//stop click blur event for help show
			link.prop("onclick", null);
			link.css('cursor','default');
			//add new help icon
			link.children().attr("src","/display_images/help_lshtm.png");
			
			var final = element_id.replace("show", "inner");
			
			//check to see if this a deposit form help or a document form help
			//if document use a direct extraction of the html
			//otherwise index the preloaded help_text array
			if(final.indexOf("doc") > -1){
				var value = jQuery("#" + final).html();
			}
			else{	
				var value = help_text[final];   
			}
			
			jQuery("#" + this.id).tooltip({
				items: "[id]",
				content: value,
			});
		}
	}); 
}


