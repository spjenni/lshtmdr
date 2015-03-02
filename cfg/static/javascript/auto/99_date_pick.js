/* SJ: extra jQuery functions for the implementation of date picker for deposit workflow */
jQuery(document).ready(function(){
	
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
	
});
