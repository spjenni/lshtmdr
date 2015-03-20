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
     
    if(jQuery(this).attr("id").match(/c[0-9]+_.+(|_[0-9]+)_lshtmid/)){
		console.log("regex match...");    
	    console.log("auto checking...");
    
  	  	var id = jQuery(this).attr("id");
   	 	var flag_id = id.replace("lshtmid", "lshtm_flag");
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
//      	console.log("This dude doesn't have an lshtmid we shall make one....?");
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
       		jQuery(tr).attr("id", row_id ).append('<td class="clear_button"><a type="image" src="/style/images/delete.png" alt="clear" title="Clear row" href="javascript:clear_row(\''+row_id+'\')"><img src="/style/images/delete.png"></a></td>');  
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
      //	alert("Please confirm that you accept the terms and conditions for this dataset");
      //return false;
    }
    
  });
  
  if(jQuery("form[action='http://w01.lshtmdrtest.da.ulcc.ac.uk/cgi/request_doc#t']").length > 0){
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
/**                         .js functions added by SJ                             **/
/***********************************************************************************/
jQuery(document).ready(function(){
	
	//SJ: Simple logged in check to show request document link if user is not logged in//
	//future versions will need to relate login status to document security level      //
	if(jQuery("#file_security").length && eprints_logged_in == false){

	  jQuery("div#hide_request").css("display","inline");  
	   
	   /*get user credentials for future versions */
	   // jQuery.getJSON( "/cgi/export-ones-self", function( data ) {
			 //alert("in JSON:" + data["usertype"]);
	   //});

	 }
});

/* SJ: extra jQuery functions for the implementation of tool tip for deposit workflow */
jQuery(document).ready(function(){
	
	load_tooltips();
	
	//config for bxslider
   jQuery('.bxslider').bxSlider({
		mode:'fade',
		infiniteLoop: true,  
		speed: 700,
		auto: true,
		
		hyperlinks: true,     
	});



/* SJ: Call to load jquery function for qr_codes */
	jQuery(function()
	{
		//jQuery('#ep_qrcode').qrcode({width: 75, height: 75, text: window.location.href});
	});
	
});


//redefine the behaviour of the help button on the default surround
	//icon is also changed
function load_tooltips(){
	
	
	jQuery("[id$=_show]").each(function() {
		var element_id = this.id;
		var link = jQuery( this ).children();
		
		link.bind("click", function (e) {
			e.preventDefault();
		});
		link.prop("onclick", null);
		link.css('cursor','default');
		link.children().attr("src","/display_images/help_lshtm.png");
		
		var final = element_id.replace("show", "inner"); 
		
		
		//console.log(jQuery("#" + final).html());
			jQuery(this).tooltip({
				items: "[id]",
				content: function () {
					return jQuery("#" + final).html();
				}
			});	
	});
}
	
function reinstate_tooltip(container){
		
		console.log(help);
}

