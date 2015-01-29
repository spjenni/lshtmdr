#This bit doesn't work because the relation field is not in $c->{fields} :(

for(@{$c->{fields}->{eprint}})
{
	if( $_->{name} eq 'relation' )
	{
    
    print STDERR "HERE ==> ".$_->{name}."\n";

                $_->{render_single_value} = 'render_relation';
                last;
    }
}

#This bit works, but needed a render_value line in the core... DataObj/EPrint.pm

$c->{render_relation} = sub
{
	my( $session, $field, $value, $alllangs, $nolink, $object) = @_;

	my $repo = $session->get_repository();
my $frag = $session->make_doc_fragment();
    $frag->appendChild(my $ul = $repo->make_element("ul", class=>"relations_list"));
    if($object->is_collection){
    	for my $part($object->get_related_objects("http://purl.org/dc/terms/hasPart")){
    		$ul->appendChild(my $li = $repo->make_element("li"));
            $li->appendChild($part->render_citation_link("brief"));
        }    	
    }else{
    	for my $part($object->get_related_objects("http://purl.org/dc/terms/isPartOf")){
    		$ul->appendChild(my $li = $repo->make_element("li"));
            $li->appendChild($part->render_citation_link("brief"));
        }    	
    }

	return $frag;
};


$c->{render_possible_test_doi} = sub 
{
        my( $session, $field, $value ) = @_;

        $value = "" unless defined $value;
        #$value =~ s/^http:\/\/dx\.doi\.org//;
		$value =~ s/^http:\/\/test\.datacite\.org\/handle//;
        
        if( $value !~ /^(doi:)?10\.\d\d\d\d\// ) { return $session->make_text( $value ); }

        $value =~ s/^doi://;

        my $url = "http://test.datacite.org/handle/$value";
        my $link = $session->render_link( $url, "_blank" );
        $link->appendChild( $session->make_text( $value ) );
        #$session->get_repository->log("rendering possible doi...");
        return $link;
};

$c->{render_name_with_initials} = sub 
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
	    if( defined $name->{honourific} && $name->{honourific} ne "" ){
	    	$firstbit = $name->{honourific}." ";
	    }
	    if( defined $name->{given} ){
	        my $initials = $name->{given};
	        $initials =~ s/^(\w)[^\s]*(|\s+(\w)[^\s]*(|\s+(\w)[^\s]*))$/$1$3$5/; #no more than 3 initials...
	        $firstbit.= $initials;
	    }

		my $secondbit = "";
	    if( defined $name->{family} ){
	    	$secondbit = $name->{family};
	    }
	    if( defined $name->{lineage} && $name->{lineage} ne "" ){
	        $secondbit .= " ".$name->{lineage};
	    }
		if( !length( $firstbit ) ){
        	$span->appendChild($repo->make_text($secondbit));
	        
	    }elsif( defined $familylast && $familylast ){
	    	$span->appendChild($repo->make_text($firstbit." ".$secondbit));
	        
        }else{
	        $span->appendChild($repo->make_text($secondbit.", ".$firstbit));
        }
	    $frag->appendChild($span);
        #$repo->log("count: ".$count." limit: ".scalar(@$names));
        $frag->appendChild($repo->html_phrase("lib/metafield:join_name")) if($count<(scalar(@$names)-1));
        $frag->appendChild($repo->make_text(" and ")) if($count==(scalar(@$names)-1));
        
	    #$repo->log("Sending: ".$secondbit.", ".$firstbit);
	}	
	
    return $frag;
};

