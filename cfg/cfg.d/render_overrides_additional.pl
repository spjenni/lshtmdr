# SJ:some extra render functions for LSHTM Data Compass


# SJ: Extra render for contributors compound field adds type directly after name
$c->{contributors_render} = sub
{
	my( $session, $field, $value ) = @_;

	my $repo = $session->get_repository();

	my $familylast = defined $field->{render_order} && $field->{render_order} eq "gf";

 	my $frag = $repo->make_doc_fragment;
 
    my $names = $value;
   	$names = [$names] if(ref($names) eq "HASH");
	my $count=0;
	for my $name(@$names){
    	$count++;
    	my $span = $repo->make_element("span", class=>"person_name");
        my $firstbit = "";
	    if( defined $name->{name}->{honourific} && $name->{name}->{honourific} ne "" ){
	    	$firstbit = $name->{name}->{honourific}." ";
	    }
	    if( defined $name->{name}->{given} ){
			no warnings qw/uninitialized/;
	        my $initials = $name->{name}->{given};
	        $initials =~ s/^(\w)[^\s]*(|\s+(\w)[^\s]*(|\s+(\w)[^\s]*))$/$1$3$5/; #no more than 3 initials...
	        $firstbit.= $initials;
	    }

		my $secondbit = "";
	    if( defined $name->{name}->{family} ){
	    	$secondbit = $name->{name}->{family};
	    }
	    if( defined $name->{name}->{lineage} && $name->{name}->{lineage} ne "" ){
	        $secondbit .= " ".$name->{name}->{lineage};
	    }
		if( !length( $firstbit ) ){
        	$span->appendChild($repo->make_text($secondbit));
	        
	    }elsif( defined $familylast && $familylast ){
	    	$span->appendChild($repo->make_text($firstbit." ".$secondbit));
	        
        }else{
	        $span->appendChild($repo->make_text($secondbit.", ".$firstbit));
        }
        
        # SJ: contributer type added to render_name_with_initials
        if( defined $name->{type} )
		{
			my $role = $name->{type};
			my $role_spaces = $repo->phrase("contributor_type_typename_".$role);
			$span->appendChild( $repo->make_text( " (" . $role_spaces . ")" ));
		}
        
	    $frag->appendChild($span);
        #$repo->log("count: ".$count." limit: ".scalar(@$names));
        $frag->appendChild($repo->html_phrase("lib/metafield:join_name")) if($count<(scalar(@$names)-1));
        $frag->appendChild($repo->make_text(" and ")) if($count==(scalar(@$names)-1));
        
	    #$repo->log("Sending: ".$secondbit.", ".$firstbit);
	}	
	
    return $frag;
};

# SJ: Extra render for contributors compound field adds type directly after name
$c->{render_name_with_initials_lshtm} = sub
{
	my( $session, $field, $value ) = @_;

	my $repo = $session->get_repository();

	my $familylast = defined $field->{render_order} && $field->{render_order} eq "gf";

 	my $frag = $repo->make_doc_fragment;

    my $names = $value;
    
   	$names = [$names] if(ref($names) eq "HASH");
	my $count=0;
	for my $name(@$names){
    	$count++;
    	my $span = $repo->make_element("span", class=>"person_name");
 
    	
        my $firstbit = "";
	    if( defined $name->{name}->{honourific} && $name->{name}->{honourific} ne "" ){
	    	$firstbit = $name->{name}->{honourific}." ";
	    }
	    if( defined $name->{name}->{given} ){
			no warnings qw/uninitialized/;
	        my $initials = $name->{name}->{given};
	        $initials =~ s/^(\w)[^\s]*(|\s+(\w)[^\s]*(|\s+(\w)[^\s]*))$/$1$3$5/; #no more than 3 initials...
	        $firstbit.= $initials;
	    }

		my $secondbit = "";
		my $fullName = "";
		
	    if( defined $name->{name}->{family} ){
	    	$secondbit = $name->{name}->{family};
	    }
	    if( defined $name->{name}->{lineage} && $name->{name}->{lineage} ne "" ){
	        $secondbit .= " ".$name->{name}->{lineage};
	    }
		if( !length( $firstbit ) ){
        	#$span->appendChild($repo->make_text($secondbit));
	        $fullName.=$secondbit;
	    }elsif( defined $familylast && $familylast ){
	    	#$span->appendChild($repo->make_text($firstbit." ".$secondbit));
	         $fullName.=$firstbit." ".$secondbit;
        }else{
	        #$span->appendChild($repo->make_text($secondbit.", ".$firstbit));
	         $fullName.=$secondbit.", ".$firstbit;
        }
        
        ####################################################################
		if( $name->{name}->{lshtmid} )
		{
			my $nlink = $repo->{rel_path}.'/view/creators/'.$name->{name}->{lshtmid};
		
			$nlink .= '.html';

			$a = $repo->render_link( $nlink );
			$a->appendChild($repo->make_text($fullName));
			$span->appendChild($a);
		}
		else
		{
			$span->appendChild($repo->make_text($fullName));
		}
		####################################################################
		
		$frag->appendChild($span);
        #$repo->log("count: ".$count." limit: ".scalar(@$names));
        $frag->appendChild($repo->html_phrase("lib/metafield:join_name")) if($count<(scalar(@$names)-1));
        $frag->appendChild($repo->make_text(" and ")) if($count==(scalar(@$names)-1));
        
	    #$repo->log("Sending: ".$secondbit.", ".$firstbit);
	}

    return $frag;
};

# SJ: Render to allow use of <br />
$c->{citation_render_breaks} = sub
{
	my( $session, $field, $value ) = @_;

	my $repo = $session->get_repository();

 	my $frag = $repo->make_doc_fragment;

	my @string = split( '<br \/>', $value);

	foreach my $ftString (@string){
		$frag->appendChild($repo->make_text($ftString));
		my $break = $repo->make_element( 'br' );
		$frag->appendChild($break);
	}
 	
 	return $frag;
};
