# By default there are no custom fields in document objects, but this file
# provides you with an example should you wish to (c.f. eprint_fields.pl)
push @{$c->{fields}->{document}},
	{
		name => "retention_period",
		type => "set",
        required => 1,
        input_rows => 1,
		options => [
			'indefinite',
            '10',
            '11',
			'12',
            '13',
            '14',
			'15',
            '16',
            '17',
			'18',
            '19',
            '20',
            'other',
		],
	},
	{
		name => "embargo_reasons",
		type => "namedset",
        input_rows => 1,
		set_name => "embargo_reasons",
	},
	{
		name => "embargo_reasons_other",
		type => "text",
		input_cols => 40,
		#input_rows => 1
	}

;
