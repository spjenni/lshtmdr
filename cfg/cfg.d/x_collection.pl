$c->{plugins}->{"Screen::EPrint::Box::CollectionMembership"}->{params}->{disable} = 0;
$c->{plugins}->{"Screen::EPrint::Box::CollectionMembership"}->{appears}->{summary_top} = undef;
$c->{plugins}->{"Screen::EPrint::Box::CollectionMembership"}->{appears}->{summary_right} = 1100;
$c->{plugins}->{"Screen::EPrint::Box::CollectionMembership"}->{appears}->{summary_bottom} = undef;
$c->{plugins}->{"Screen::EPrint::Box::CollectionMembership"}->{appears}->{summary_left} = undef;
$c->{plugins}->{"Collection"}->{params}->{disable} = 0;
$c->{plugins}->{"InputForm::Component::Field::CollectionSelect"}->{params}->{disable} = 0;
$c->{plugins}->{"Screen::NewCollection"}->{params}->{disable} = 0;

$c->{plugins}->{"InputForm::Component::Field::AddToCollection"}->{params}->{disable} = 0;

#$c->{plugins}->{"Screen::EPrint::CollectionEdit"}->{params}->{disable} = 0;
#$c->{plugin_alias_map}->{"Screen::EPrint::Edit"} = "Screen::EPrint::CollectionEdit";
#$c->{plugin_alias_map}->{"Screen::EPrint::CollectionEdit"} = undef;

#fields to go in landing page for collection items

$c->{collection_summary_page_metadata} = [qw/
    project_date
    funders
    alt_title
    date
    collection_mode
    primary_contact_name
    contributors_name
    divisions
    research_centre
    corp_creators
    subjects
    relation
    official_url
/];


#### extra metadata that extends  the summary page record - hidden by js - accessed by additional details link

$c->{collection_summary_page_metadata_hidden} = [qw/
    projects
    grant
    collection_method
    collection_date
    geographic_cover
    bounding_box
    keywords
    legal_ethical
    provenance
    language
    ispublished
    publisher
    restrictions
    copyright_holders
    commentary
    note
    sword_depositor
    userid
    datestamp
    lastmod
    /];


$c->{z_collection_validate_eprint} = $c->{validate_eprint};

$c->{validate_eprint} = sub
{
	my( $eprint, $session, $for_archive ) = @_;

	my @problems = ();

	if( $eprint->get_type eq 'collection' ){
		return( @problems );
	}

	@problems = $session->get_repository()->call("z_collection_validate_eprint", $eprint, $session, $for_archive);

	return( @problems );
};

$c->{z_collection_eprint_warnings} = $c->{eprint_warnings};

$c->{eprint_warnings} = sub
{
        my( $eprint, $session ) = @_;

        my @problems = ();

        if( $eprint->get_type eq 'collection' ){
                return( @problems );
        }

        @problems = $session->get_repository()->call("z_collection_eprint_warnings", $eprint, $session );

        return( @problems );
};

$c->{collection_session_init} = $c->{session_init};

$c->{session_init} = sub {
        my ($repository, $offline) = @_;

        push @{$repository->{types}->{eprint}}, "collection";

        $repository->call("collection_session_init");
};

$c->{collection_eprint_render} = $c->{eprint_render};

#overwrite collection_render in order to make a custom render method for collections
$c->{collection_render} = sub {

	my ($eprint, $repository, $preview) = @_;

####### All this nonsense ######

	my $succeeds_field = $repository->dataset( "eprint" )->field( "succeeds" );
	my $commentary_field = $repository->dataset( "eprint" )->field( "commentary" );

	my $flags = { 
		has_multiple_versions => $eprint->in_thread( $succeeds_field ),
		in_commentary_thread => $eprint->in_thread( $commentary_field ),
		preview => $preview,
	};
	my %fragments = ();

	# Put in a message describing how this document has other versions
	# in the repository if appropriate
	if( $flags->{has_multiple_versions} )
	{
		my $latest = $eprint->last_in_thread( $succeeds_field );
		if( $latest->value( "eprintid" ) == $eprint->value( "eprintid" ) )
		{
			$flags->{latest_version} = 1;
			$fragments{multi_info} = $repository->html_phrase( "page:latest_version" );
		}
		else
		{
			$fragments{multi_info} = $repository->render_message(
				"warning",
				$repository->html_phrase( 
					"page:not_latest_version",
					link => $repository->render_link( $latest->get_url() ) ) );
		}
	}		


	# Now show the version and commentary response threads
	if( $flags->{has_multiple_versions} )
	{
		$fragments{version_tree} = $eprint->render_version_thread( $succeeds_field );
	}
	
	if( $flags->{in_commentary_thread} )
	{
		$fragments{commentary_tree} = $eprint->render_version_thread( $commentary_field );
	}


	foreach my $key ( keys %fragments ) { $fragments{$key} = [ $fragments{$key}, "XHTML" ]; }
	

	my $title = $eprint->render_citation("brief");

	my $links = $repository->xml()->create_document_fragment();
	if( !$preview )
	{
		$links->appendChild( $repository->plugin( "Export::Simple" )->dataobj_to_html_header( $eprint ) );
		$links->appendChild( $repository->plugin( "Export::DC" )->dataobj_to_html_header( $eprint ) );
	}
	
	#SJ: Added to test files at collection level
	my @content = $repository->get_types("collection_content");
	$flags->{rc_filetypes} = \@content;

#       Using epc script related_objects()
#    	$fragments{parts} = $eprint->get_related_objects("http://purl.org/dc/terms/hasPart");

###### Is there because... #####
	my $page = $eprint->render_citation( "collection_item", %fragments, flags=>$flags );


###### This bit doesn't really work : gives a Template not loaded error #######
	#to define a specific template to render the abstract with, you can do something like:
	# my $template;
	# if( $eprint->value( "type" ) eq "article" ){
	# 	$template = "article_template";
	# }
	# return ( $page, $title, $links, $template );

###### In theory we could remove most of the above and just ... #######
    	# my ($page, $title, $links) = $repository->call("recollect_eprint_render", $eprint, $repository, $preview);
	#return( $page, $title, $links "recollect_summary_page");

####### But... #######
	return( $page, $title, $links );


};

$c->{eprint_render} = sub
{
	my ($eprint, $repository, $preview) = @_;

	if( $eprint->value("type") ne "collection" )
	{
        	return $repository->call("collection_eprint_render", $eprint, $repository, $preview );
	}
	
	return $repository->call("collection_render", $eprint, $repository, $preview );
};

