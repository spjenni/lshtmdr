/* LSHTM Google maps functionality has 2 functions to control adding markers to
 * the bounding box recollect metadata field
 * One function to add all eprint markers to a view on the main page. */

jQuery.noConflict();

/* jQuery function required to stop form submission when enter is pressed in the
 * google maps search box */
jQuery(document).on('keyup keypress', 'form input[type="text"]', function(e) {
  if(e.keyCode == 13) {
    e.preventDefault();
    return false;
  }
});

function deposit_map(){
	if(document.getElementById("ep_map_frame")){
		map_draw();
	}
}

/******************************************************************/
/* Function to add the drawing markers of a geographical location */
/******************************************************************/

function map_draw(){
	
	var mapOptions = {
		center: { lat: 51.520614, lng: -0.13002},
		zoom: 17
    };
    
	var map = new google.maps.Map(document.getElementById('map-canvas'), mapOptions);
    var shapes = [];
    var markers = [];
    var new_shape = false;
  
    //check if geolocation metadata exists and if so print it on the map
    if( document.getElementsByClassName("ep_eprint_bounding_box_north_edge")[0].value.length > 0 )
    {
		
		var neLat = document.getElementsByClassName("ep_eprint_bounding_box_north_edge")[0].value;
		var neLng = document.getElementsByClassName("ep_eprint_bounding_box_east_edge")[0].value;
		
		var swLat = document.getElementsByClassName("ep_eprint_bounding_box_south_edge")[0].value;
		var swLng = document.getElementsByClassName("ep_eprint_bounding_box_west_edge")[0].value;


		/* create bounds object */
		var current_bounds = new google.maps.LatLngBounds(
				new google.maps.LatLng(swLat, swLng),
				new google.maps.LatLng(neLat, neLng)
		);
		
		
		var info_window = new google.maps.InfoWindow({
					content: "Click the box to remove the box and location data",
					shadowStyle: 1, 
		});
		
		/* use the bounds to draw the rectangle */
		map.fitBounds(current_bounds);
		var rectangle1 = new google.maps.Rectangle({
			strokeColor: '#FF0000',
			editable: true,
			clickable: true,
			strokeOpacity: 0.8,
			strokeWeight: 2,
			fillColor: '#FF0000',
			fillOpacity: 0.35,
			map: map,
			bounds: current_bounds,
			
		});
		rectangle1.setMap(map);
		
		var info = (document.getElementById('click_info'));
		var content = document.createTextNode("Click the box to delete it. Please note that this will remove all the location data");
		info.appendChild(content);
		
		/* add a click listner to rectangle to delete map */
		google.maps.event.addListener(rectangle1, 'click', function(){
			 rectangle1.setMap(null);
			 info.style.display='none';
			 if(new_shape == false)
			 {
				clear_values();
			 }
		});

		google.maps.event.addListener(rectangle1, 'mouseover', function(){
				info.style.display='inline-block';
		});
		
		google.maps.event.addListener(rectangle1, 'mouseout', function(){
				info.style.display='none';
		});
		
		google.maps.event.addListener(rectangle1, 'bounds_changed', function(event){
			info.style.display='none';
			
			var ne = rectangle1.getBounds().getNorthEast();
			var sw = rectangle1.getBounds().getSouthWest();
				
			document.getElementsByClassName("ep_eprint_bounding_box_north_edge")[0].value = ne.lat();
			document.getElementsByClassName("ep_eprint_bounding_box_east_edge")[0].value = ne.lng();
				
			document.getElementsByClassName("ep_eprint_bounding_box_south_edge")[0].value = sw.lat();
			document.getElementsByClassName("ep_eprint_bounding_box_west_edge")[0].value = sw.lng();
		});
	}
	/* end of draw current eprint bounding box */

   //Drawing manager functionality
    var drawingManager = new google.maps.drawing.DrawingManager({
    drawingMode: google.maps.drawing.OverlayType.null,
    drawingControl: true,
    drawingControlOptions: {
		position: google.maps.ControlPosition.TOP_CENTER,
		drawingModes: [
			
			google.maps.drawing.OverlayType.RECTANGLE,
		
		]
	},
	
    rectangleOptions:{
		fillColor: '#9966cc',
		fillOpacity: 0.2,
		strokeWeight: 1,
		clickable: true,
		editable: true,
		zIndex: 1
	},
	
	});
	
	
	google.maps.event.addListener(drawingManager,'rectanglecomplete',function(rectangle){
   
		clear_area();
		
		var ne = rectangle.getBounds().getNorthEast();
		var sw = rectangle.getBounds().getSouthWest();
		
		document.getElementsByClassName("ep_eprint_bounding_box_north_edge")[0].value = ne.lat();
		document.getElementsByClassName("ep_eprint_bounding_box_east_edge")[0].value = ne.lng();
		
		document.getElementsByClassName("ep_eprint_bounding_box_south_edge")[0].value = sw.lat();
		document.getElementsByClassName("ep_eprint_bounding_box_west_edge")[0].value = sw.lng();
		
		//document.getElementById("map_marker_type").value = 1;
		
		shapes.push(rectangle);
		
		new_shape = true;
		
		google.maps.event.addListener(shapes[0],'click',function(){
			clear_area();
			clear_values();
			new_shape = false;
		});
		
		google.maps.event.addListener(shapes[0], 'bounds_changed', function(event){

			 
			 var ne = rectangle1.getBounds().getNorthEast();
				var sw = rectangle1.getBounds().getSouthWest();
				
				document.getElementsByClassName("ep_eprint_bounding_box_north_edge")[0].value = ne.lat();
				document.getElementsByClassName("ep_eprint_bounding_box_east_edge")[0].value = ne.lng();
				
				document.getElementsByClassName("ep_eprint_bounding_box_south_edge")[0].value = sw.lat();
				document.getElementsByClassName("ep_eprint_bounding_box_west_edge")[0].value = sw.lng();
		});
	});
	drawingManager.setMap(map);

	/* search box functionality */
	var input = (document.getElementById('pac-input'));
	
	map.controls[google.maps.ControlPosition.TOP_LEFT].push(input);

	var searchBox = new google.maps.places.SearchBox((input));

	google.maps.event.addListener(searchBox, 'places_changed', function() {
		var places = searchBox.getPlaces();

		if (places.length == 0) {
			return;
		}
		for (var i = 0, marker; marker = markers[i]; i++) {
			marker.setMap(null);
		}

		// For each place, get the icon, place name, and location.
		var bounds = new google.maps.LatLngBounds();
		
		for (var i = 0, place; place = places[i]; i++) {
			var image = {
				url: place.icon,
				size: new google.maps.Size(71, 71),
				origin: new google.maps.Point(0, 0),
				anchor: new google.maps.Point(17, 34),
				scaledSize: new google.maps.Size(25, 25)
		  };

		// Create a marker for each place.
		var marker = new google.maps.Marker({
			 map: map,
			 icon: image,
			 title: place.name,
			 position: place.geometry.location
		  });

	  markers.push(marker);

	  bounds.extend(place.geometry.location);
	 }

	  map.fitBounds(bounds);
	  map.setZoom(1);
	});
	//End of search box functionality
	
	google.maps.event.addListener(map, 'bounds_changed', function() {
		var bounds = map.getBounds();
		searchBox.setBounds(bounds);
	});
	
	function clear_area()
	{
		if (shapes.length > 0){
			
			shapes[0].setMap(null);
			shapes.splice(0,1);
		}
	}

	function clear_values()
	{
		document.getElementsByClassName("ep_eprint_bounding_box_north_edge")[0].value = null;
		document.getElementsByClassName("ep_eprint_bounding_box_east_edge")[0].value = null;
		document.getElementsByClassName("ep_eprint_bounding_box_south_edge")[0].value = null;
		document.getElementsByClassName("ep_eprint_bounding_box_west_edge")[0].value = null;	
	}
}


/******************************************************************/
/* functionality for map which show all eprints with bounding box*/
/******************************************************************/

function map_show(eprints){
	

	var mapOptions = {
		center: { lat: 10, lng: 0},
		zoom:2,
		minZoom: 2,
    };
    
	var map = new google.maps.Map(document.getElementById('map-canvas'), mapOptions);	
	var map_locs = document.getElementsByClassName("map_loc");

	var info_window = new google.maps.InfoWindow({
		content: "Data map",
		shadowStyle: 1,
		  
	});
	
	//CHECK IF ANY EPRINTS EXIST
    //loop through each eprint and create a marker and short citation 
    //for the infowindow
    if(eprints.length > 0){
		for(var i=0; i<eprints.length; i++)
		{     
				var current_eprint = eprints[i];
				var info_window_array = [];
				//check the eprint has bounding box metatdata
				if(current_eprint.hasOwnProperty('bounding_box'))
				{
					/*very messy! will be updated when MapsView.pm passes required fields*/
					
					//get required eprint metadata, will be set by perl in the future
					var ep_title = current_eprint.title;
					var ep_ne = current_eprint.bounding_box["north_edge"];
					var ep_ee = current_eprint.bounding_box["east_edge"];
					var ep_se = current_eprint.bounding_box["south_edge"];
					var ep_we = current_eprint.bounding_box["west_edge"];
					//var ep_abstract = current_eprint.abstract;
					var ep_cp = current_eprint.copyright_holders;
					var ep_uri = current_eprint.uri;
					var ep_creator = "";
					
					//output creators object
					if(current_eprint.creators.length>0)
					{
						var family = "";
						var given = "";
						var intials = "";
						
						for (var n=0; n<current_eprint.creators.length; n++)
						{
							//check for presence of family and given name in each creators object
							if(current_eprint.creators[n]["name"]["family"] != null){ family = current_eprint.creators[n]["name"]["family"] }
							if(current_eprint.creators[n]["name"]["given"] != null)
							{ 
								//create single intials from the given name
								intials = ", ";
								given = current_eprint.creators[n]["name"]["given"]; 
								
								//split the given name for a max of 3 intials
								//and make sure all commas are in the correct place
								var split_given = given.split(" ", 3);
								for (var m=0; m<split_given.length; m++)
								{
									intials = intials + split_given[m].charAt(0) + " ";
								}
								intials = intials.substr(0, intials.length-1); 
							}
							ep_creator = ep_creator + family + intials + ", ";
						}
						ep_creator = ep_creator.substr(0, ep_creator.length-2); 
					}
					
					//push the locations onto the information window
					info_window_array.push(ep_ne, ep_ee, ep_se, ep_we);
		
					//create the html for the infowindow
					var content = '<div id="map_info">';
					if(ep_title != null){ content += '<h1 class="maps_info">' + current_eprint.title + '</h1>'};			
					//if(ep_abstract != null){ content += '<p class="maps_info_content">Abstract: ' +  ep_abstract  + '</p>'};
					
					if(ep_cp != null){ content += '<p class="maps_info_content">' +  ep_creator  + '</p>'};
					content += '<p class="maps_info_content">';

					/* latlng for debug
					for (var j=0; j<info_window_array.length; j++){
	
						content += ' ' + info_window_array[j];
							
					}
					*/

					content +="</p>";
					if(ep_uri != null){ content += '<p class="maps_info_link"><a href="' + ep_uri + '">Metadata Record</a></p>'};
					content += '</div>';
					
					// get the bounds for centering			
					var current_bounds = new google.maps.LatLngBounds(				
							new google.maps.LatLng(ep_se, ep_we),
							new google.maps.LatLng(ep_ne, ep_ee));
		
					//add marker and set content
					var marker = new google.maps.Marker({
						position: current_bounds.getCenter(),
						map: map,
						html: content,
					});
					
					google.maps.event.addListener(marker, 'click', function () {
						info_window.setContent(this.html);
						info_window.open(map, this);
					});
				}
		}
	}
}

google.maps.event.addDomListener(window, 'load', deposit_map);
