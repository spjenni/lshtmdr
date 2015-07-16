

######################################################################
#
# validate_eprint( $eprint, $repository, $for_archive ) 
#
######################################################################
#
# $eprint 
# - EPrint object
# $repository 
# - Repository object (the current repository)
# $for_archive
# - boolean (see comments at the start of the validation section)
#
# returns: @problems
# - ARRAY of DOM objects (may be null)
#
######################################################################
# Validate the whole eprint, this is the last part of a full 
# validation so you don't need to duplicate tests in 
# validate_eprint_meta, validate_field or validate_document.
#
######################################################################

$c->{validate_eprint} = sub
{
	my( $eprint, $repository, $for_archive ) = @_;
	
	my $xml = $repository->xml();
	
	my @problems = ();
	
	# If we don't have creators (eg. for a book) then we 
	# must have editor(s). To disable that rule, remove the 
	# following block.	

	if( !$eprint->is_set( "creators" ) && 
		!$eprint->is_set( "editors" ) )
	{
		my $fieldname = $xml->create_element( "span", class=>"ep_problem_field:creators" );
		push @problems, $repository->html_phrase( 
				"validate:need_creators_or_editors",
				fieldname=>$fieldname );
	}

	# SJ: Validation to check online data resource has a link otherwise will not show on citation
	if($eprint->is_set( "related_resources" )){
		
		my $rr = $eprint->value( "related_resources" );
		
		foreach my $rr_check ( @$rr ) 
		{
			if($rr_check->{type} eq 'dataresource' && (!$rr_check->{title} || !$rr_check->{url}))
			{
				my $fieldname = $xml->create_element( "span", class=>"ep_problem_field:related_resources" );
				push @problems, $repository->html_phrase( 
					"validate:need_online_resource",
					fieldname=>$fieldname );
			}
		}	
	}

	
	for my $document ($eprint->get_all_documents()){
		# embargo expiry date must be in the future
		if( EPrints::Utils::is_set( $document->value( "date_embargo" ) ) )
		{
			#my $value = $document->value( "date_embargo" );
			#my ($thisyear, $thismonth, $thisday) = EPrints::Time::get_date_array();
			#my ($year, $month, $day) = split( '-', $value );
			#if( $year < $thisyear || ( $year == $thisyear && $month < $thismonth ) ||
			#	( $year == $thisyear && $month == $thismonth && $day <= $thisday ) )
			#{
			#	my $fieldname = $xml->create_element( "span", class=>"ep_problem_field:documents" );
			#	push @problems,
			#		$repository->html_phrase( "validate:embargo_invalid_date",
			#		fieldname=>$fieldname );
			#}
			if(!EPrints::Utils::is_set( $document->value( "embargo_reasons" ) ) || 
				(EPrints::Utils::is_set( $document->value( "embargo_reasons" ) ) && $document->value("embargo_reasons") eq "other" && !EPrints::Utils::is_set( $document->value( "embargo_reasons_other" ) ) ) ){

				print STDERR "EMBARGO REASONS WARNING\n";

				my $fieldname = $xml->create_element( "span", class=>"ep_problem_field:documents" );
				push @problems,
					$repository->html_phrase( "validate:embargo_reasons_not_given",
					fieldname=>$fieldname,
					format=>$document->value("format"));
		
			}
		}
	}

	return( @problems );
};
