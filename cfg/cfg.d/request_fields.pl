push @{$c->{fields}->{request}},

{
	name => 'requester_name',
	type => 'name',
    required => 1,
},
{
	name => 'organisation',
	type => 'text',
},
{
	name   => 'time_period',
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
   required => 1,
},
{
	name   => 'terms_and_conditions',
    type   => 'boolean',
},
{
	name   => 'variables_required',
    type   => 'longtext',
     
},
{
	name   => 'supporting_information',
    type   => 'longtext',
     
},
