##### route and activate ReCollectDocuments plugin

#$c->{plugin_alias_map}->{"InputForm::Component::Documents"} = "InputForm::Component::ReCollectDocuments";
#$c->{plugin_alias_map}->{"InputForm::Component::ReCollectDocuments"} = undef;
#$c->{plugins}->{"InputForm::Component::ReCollectDocuments"}->{params}->{disable} = 0;

##### activate NewDeposit plugin

$c->{plugins}->{"Screen::NewDeposit"}->{params}->{disable} = 0;

#### overide eprint_render

$c->{recollect_eprint_render} = $c->{eprint_render};

$c->{eprint_render} = sub {

    my ($eprint, $repository, $preview) = @_;
    
    if($eprint->value("type") ne "data_collection"){
	#trad. eprint_render for most items
	return $repository->call("recollect_eprint_render", $eprint, $repository, $preview);
    }

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
	my @content = $repository->get_types("recollect_content");
	$flags->{rc_filetypes} = \@content;

###### Is there because... #####
	my $page = $eprint->render_citation( "recollect_summary_page", %fragments, flags=>$flags );


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

###################################################################################################
############################### Apply the recollect metadata profile ##############################
###################################################################################################

#To *add* different traditional eprint fields to the summary page metadata (defined in eprints_render.pl) do this:

push (@{$c->{summary_page_metadata}},
    qw/
      creators
    /
);

push (@{$c->{summary_page_metadata_hidden}},
    qw/
      corp_creators
    /
);

#To entirely control the summary_page_metadata from this file redefine the whole thing like this:

$c->{summary_page_metadata} = [qw/
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
    official_url/];

$c->{summary_page_metadata_hidden} = [qw/
	repo_link
        projects
	project_date
	funders
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
	lastmod/];


#Apply the recollect metadata profile

for my $recollect_field (@{$c->{recollect_metadata_profile}}){
	
	#Add fields to database
	$c->add_dataset_field(
                      "eprint",
			$recollect_field->{field_definition},
                      reuse => 1
                     );

	#This will automatically *add* *recollect* fields to the summary_page_metadata depending on flag in recollect MD profile object
	#To reorder just reorder the recollect_metadata_profile
	#If you need to mix the order of recollect and trad fields then comment out below and redefine as above
#	push @{$c->{summary_page_metadata}}, $recollect_field->{field_definition}->{name} if($recollect_field->{summary_page_metadata});
#	push @{$c->{summary_page_metadata_hidden}}, $recollect_field->{field_definition}->{name} if($recollect_field->{summary_page_metadata_hidden});

	#apply search flag to sub fields of compounds if set
	if($recollect_field->{field_definition}->{type} eq "compound" &&
			($recollect_field->{advanced_search} || $recollect_field->{simple_search})
		){ 
		for my $sub (@{$recollect_field->{field_definition}->{fields}}){
			push @{$c->{search}->{advanced}->{search_fields}}, { meta_fields => [ $recollect_field->{field_definition}->{name}."_".$sub->{sub_name} ] } if($recollect_field->{advanced_search});
			push @{$c->{search}->{simple}->{search_fields}->[0]->{meta_fields}}, $recollect_field->{field_definition}->{name}."_".$sub->{sub_name} if($recollect_field->{simple_search});
		}
	}else{
		#This will automatically *add* *recollect* fields to the advanced search form depending on flag in recollect MD profile object
		push @{$c->{search}->{advanced}->{search_fields}}, { meta_fields => [ $recollect_field->{field_definition}->{name} ] } if($recollect_field->{advanced_search});
		#To reorder just reorder the recollect_metadata_profile
		
		#This will automatically *add* *recollect* fields to the simple search form depending on flag in recollect MD profile object
		#NB assumes simple_Search has one field.... which it generally does
		push @{$c->{search}->{simple}->{search_fields}->[0]->{meta_fields}}, $recollect_field->{field_definition}->{name}  if($recollect_field->{simple_search});
	}	
}


=head1 NAME

EPrints::Plugin::Screen::EPrint

=cut


package EPrints::Plugin::Screen::EPrint::Edit;

use EPrints::Plugin::Screen;

#@ISA = ( 'EPrints::Plugin::Screen' );

#use strict;

sub workflow_id
{
	my ($plugin) = @_;
	my $repo = $plugin->get_repository;
	my $eprint = $plugin->{processor}->{eprint};
	$repo->log("In recollect cfg.d:workflow_id => ".$eprint->value("type"));
	
	if($eprint->value("type") eq "data_collection"){
		return "recollect";
	}
	if($eprint->value("type") eq "collection"){
		return "collection";
	}
	return "default";
}

#switch for details page too....

package EPrints::Plugin::Screen::EPrint::Details;

use EPrints::Plugin::Screen;

#@ISA = ( 'EPrints::Plugin::Screen::EPrint' );

sub workflow_id
{
	my ($plugin) = @_;
	my $repo = $plugin->get_repository;
	my $eprint = $plugin->{processor}->{eprint};
	$repo->log("In *recollect cfg.d:workflow_id => ".$eprint->value("type"));
	
	if($eprint->value("type") eq "data_collection"){
		return "recollect";
	}
	if($eprint->value("type") eq "collection"){
		return "collection";
	}
	return "default";
}


#Getting daft now
package EPrints::Plugin::Screen::EPrint::Deposit;

use EPrints::Plugin::Screen;

#@ISA = ( 'EPrints::Plugin::Screen::EPrint' );

sub workflow_id
{
	my ($plugin) = @_;
	my $repo = $plugin->get_repository;
	my $eprint = $plugin->{processor}->{eprint};
	$repo->log("In **recollect cfg.d:workflow_id => ".$eprint->value("type"));
	
	if($eprint->value("type") eq "data_collection"){
		return "recollect";
	}
	if($eprint->value("type") eq "collection"){
		return "collection";
	}
	return "default";
}
#remove the default item colection...
$c->{plugins}->{"Screen::NewEPrint"}->{appears}->{item_tools} = undef;
