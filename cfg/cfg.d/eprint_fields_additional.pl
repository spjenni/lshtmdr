# uncomment and use this file to add/modify default eprints fields

push @{$c->{fields}->{eprint}},

{
  name => 'research_centre',
  type => 'subject',
  multiple => 1,
  top => 'research_centre',
  browse_link => 'research_centre',
},

{
  name => 'research_groups',
  type => 'text',
  multiple => 1,
  input_boxes =>2,
},

{
    name => 'collection_mode',
    type => 'compound',
    multiple => 1,
    fields => [
    	{
        	sub_name=> 'cm',
    		type => 'namedset',
    		set_name => 'collection_mode',
            browse_link => "collection_mode",
        },
    ],
    input_boxes => 2,
    
},
{
	name   => 'project_date',
	type   => 'compound',
	fields => [
    	{
        	sub_name   => 'date_from',
            type       => 'date',
            render_res => 'day',
        },
        {
        	sub_name => 'date_to',
        	type     => 'date',
        },
    ],
},
{ 
	name=>"date_embargo", 
	type=>"date", 
	required=>0,
	min_resolution=>"year" 
},	
;
