$c->{plugins}->{"Screen::EPrint::Box::CollectionMembership"}->{params}->{disable} = 0;
$c->{plugins}->{"Screen::EPrint::Box::CollectionMembership"}->{appears}->{summary_top} = undef;
$c->{plugins}->{"Screen::EPrint::Box::CollectionMembership"}->{appears}->{summary_right} = 1100;
$c->{plugins}->{"Screen::EPrint::Box::CollectionMembership"}->{appears}->{summary_bottom} = undef;
$c->{plugins}->{"Screen::EPrint::Box::CollectionMembership"}->{appears}->{summary_left} = undef;
$c->{plugins}->{"Collection"}->{params}->{disable} = 0;
$c->{plugins}->{"InputForm::Component::Field::CollectionSelect"}->{params}->{disable} = 0;
$c->{plugins}->{"Screen::NewCollection"}->{params}->{disable} = 0;
$c->{plugins}->{"Screen::EPrint::CollectionEdit"}->{params}->{disable} = 0;
$c->{plugin_alias_map}->{"Screen::EPrint::Edit"} = "Screen::EPrint::CollectionEdit";
$c->{plugin_alias_map}->{"Screen::EPrint::CollectionEdit"} = undef;
#RM we need one for view too!
$c->{plugins}->{"Screen::EPrint::CollectionDetails"}->{params}->{disable} = 0;
$c->{plugin_alias_map}->{"Screen::EPrint::Details"} = "Screen::EPrint::CollectionDetails";
$c->{plugin_alias_map}->{"Screen::EPrint::CollectionDetails"} = undef;
#RM we need one for deposit...
#$c->{plugins}->{"Screen::EPrint::CollectionDeposit"}->{params}->{disable} = 0;
#$c->{plugin_alias_map}->{"Screen::EPrint::Deposit"} = "Screen::EPrint::CollectionDeposit";
#$c->{plugin_alias_map}->{"Screen::EPrint::CollectionDeposit"} = undef;
#RM this is for selecting a collection from an item
#$c->{plugins}->{"InputForm::Component::Field::SelectCollection"}->{params}->{disable} = 0;

#fields to go in landing page for collection items

$c->{collection_summary_page_metadata} = [qw/

    project_date
    funders
    alt_title
    date
    collection_mode
	creators_name
    contributors_name
	divisions
    research_centre
    corp_creators
	subjects
    relation
    official_url
	/];


#### extra metadata that extends  the summary page record - hidden by js - accessed by additional details link

push(
    @{$c->{collection_summary_page_metadata_full}},
    qw/
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
    /
);


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
#$c->{collection_render} = $c->{eprint_render};


$c->{collection_render} = sub {
        my( $eprint, $repository, $preview ) = @_;


		 my $succeeds_field   = $repository->dataset("eprint")->field("succeeds");
    my $commentary_field = $repository->dataset("eprint")->field("commentary");

    my $flags = {
                 has_multiple_versions => $eprint->in_thread($succeeds_field),
                 in_commentary_thread  => $eprint->in_thread($commentary_field),
                 preview               => $preview,
                };

    my %fragments = ();

    # Put in a message describing how this document has other versions
    # in the repository if appropriate
    if ($flags->{has_multiple_versions})
    {
        my $latest = $eprint->last_in_thread($succeeds_field);

        #my @rdfiles;
        if ($latest->value("eprintid") == $eprint->value("eprintid"))
        {
            $flags->{latest_version} = 1;
            $fragments{multi_info} =
              $repository->html_phrase("page:latest_version");
        } ## end if ($latest->value("eprintid"...))
        else
        {
            $fragments{multi_info} =
              $repository->render_message(
                        "warning",
                        $repository->html_phrase(
                            "page:not_latest_version",
                            link => $repository->render_link($latest->get_url())
                        )
              );
        } ## end else [ if ($latest->value("eprintid"...))]
    } ## end if ($flags->{has_multiple_versions...})

    # Now show the version and commentary response threads
    if ($flags->{has_multiple_versions})
    {
        $fragments{version_tree} =
          $eprint->render_version_thread($succeeds_field);
    }

    if ($flags->{in_commentary_thread})
    {
        $fragments{commentary_tree} =
          $eprint->render_version_thread($commentary_field);
    }
    
    my $export_bar = $repository->make_element( "div", style => "ep_block" );
    $fragments{export_bar} = $export_bar;
    {
        my @plugins = $repository->get_plugins(
            type => "Export",
            can_accept => "dataobj/eprint",
            is_advertised => 1,
            is_visible => "all" );
        my $uri = $repository->get_url( path => "cgi" ) . "/export_redirect";
        my $form = $repository->render_form( "GET", $uri );
        $export_bar->appendChild( $form );
        $form->appendChild( $repository->render_hidden_field( dataobj => $eprint->id ) );
        my $select = $repository->make_element( "select", name => "format" );
        $form->appendChild( $select );
        foreach my $plugin ( sort { $a->{name} cmp $b->{name} } @plugins )
        #foreach my $plugin (@plugins)
        {
            my $plugin_id = $plugin->get_id;
            $plugin_id =~ s/^Export:://;
	         my $option = $repository->make_element( "option", value => $plugin_id );
            $select->appendChild( $option );
            $option->appendChild( $plugin->render_name );
        }
        my $button = $repository->make_element( "input", type => "submit", value => $repository->phrase( "lib/searchexpression:export_button" ), class => "ep_form_action_button" );
        $form->appendChild( $button );
    }

    if (0)
    {

        # Experimental SFX Link
        my $authors      = $eprint->value("creators");
        my $first_author = $authors->[0];
        my $url          = "http://demo.exlibrisgroup.com:9003/demo?";

        #my $url = "http://aire.cab.unipd.it:9003/unipr?";
        $url .= "title=" . $eprint->value("title");
        $url .= "&aulast=" . $first_author->{name}->{family};
        $url .= "&aufirst=" . $first_author->{name}->{family};
        $url .= "&date=" . $eprint->value("date");
        $fragments{sfx_url} = $url;
    } ## end if (0)

    if (0)
    {

        # Experimental OVID Link
        my $authors      = $eprint->value("creators");
        my $first_author = $authors->[0];
        my $url          = "http://linksolver.ovid.com/OpenUrl/LinkSolver?";
        $url .= "atitle=" . $eprint->value("title");
        $url .= "&aulast=" . $first_author->{name}->{family};
        $url .= "&date=" . substr($eprint->value("date"), 0, 4);
        if ($eprint->is_set("issn"))
        {
            $url .= "&issn=" . $eprint->value("issn");
        }
        if ($eprint->is_set("volume"))
        {
            $url .= "&volume=" . $eprint->value("volume");
        }
        if ($eprint->is_set("number"))
        {
            $url .= "&issue=" . $eprint->value("number");
        }
        if ($eprint->is_set("pagerange"))
        {
            my $pr = $eprint->value("pagerange");
            $pr =~ m/^([^-]+)-/;
            $url .= "&spage=$1";
        } ## end if ($eprint->is_set("pagerange"...))
        $fragments{ovid_url} = $url;
    } ## end if (0)

	$fragments{parts} = $eprint->get_related_objects("http://purl.org/dc/terms/hasPart");
    		

	foreach my $key (keys %fragments)
    {
        $fragments{$key} = [$fragments{$key}, "XHTML"];
    }

    my $title = $eprint->render_citation("brief");
    my $links = $repository->xml()->create_document_fragment();
        #my $title = undef;
		#my $links = undef;
	my $page = $eprint->render_citation("collection_item", %fragments,
                                        flags => $flags);

	return ($page, $title, $links);

};

$c->{eprint_render} = sub
{
        my( $eprint, $session, $preview ) = @_;
	
	if( $eprint->value("type") ne "collection" )
	{
        	return $session->get_repository->call("collection_eprint_render", $eprint, $session, $preview );
	}
	
        return $session->get_repository->call("collection_render", $eprint, $session, $preview );
};

