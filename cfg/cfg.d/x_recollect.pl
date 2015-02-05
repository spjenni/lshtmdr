##### route and activate ReCollectDocuments plugin

$c->{plugin_alias_map}->{"InputForm::Component::Documents"} = "InputForm::Component::ReCollectDocuments";
$c->{plugin_alias_map}->{"InputForm::Component::ReCollectDocuments"} = undef;
$c->{plugins}->{"InputForm::Component::ReCollectDocuments"}->{params}->{disable} = 0;

##### activate NewDeposit plugin

$c->{plugins}->{"Screen::NewDeposit"}->{params}->{disable} = 0;

#####  add  data_collection as default type

$c->{recollect_set_eprint_defaults} = $c->{set_eprint_defaults};
$c->{set_eprint_defaults} = sub
{
	my( $data, $repository ) = @_;
	$repository->call("recollect_set_eprint_defaults");
	if(!EPrints::Utils::is_set( $data->{type} ))
	{
		$data->{type} = "data_collection";	
	}
};

#### add automatic values for publisher and date

$c->{recollect_set_eprint_automatic_fields} = $c->{set_eprint_automatic_fields};
$c->{set_eprint_automatic_fields} = sub
{
	my( $eprint ) = @_;
	#$repo->call("recollect_set_eprint_automatic_fields", $eprint);
	if(!$eprint->is_set( "publisher" ) ) 
                {
                         $eprint->set_value( "publisher", "UK Data Archive" );
                }
	my $lastmod = $eprint->get_value( "lastmod" );
	if(!$eprint->is_set( "date" ) ) 
                {
                         $eprint->set_value( "date", $lastmod );
                }
};

#####  add embargo date cap at 2 years


$c->{recollect_validate_document} = $c->{validate_document};
$c->{validate_document} = sub {
    my ($document, $repository, $for_archive) = @_;
    my $eprint = $document->get_eprint();

	if($eprint->value("type") ne "data_collection"){
            return $repository->call("recollect_validate_document");
         }

    my @problems = ();

    my $xml = $repository->xml();

    # CHECKS IN HERE

    # "other" documents must have a description set
    if ($document->value("format") eq "other"
        && !EPrints::Utils::is_set($document->value("formatdesc")))
    {
        my $fieldname =
          $xml->create_element("span", class => "ep_problem_field:documents");
        push @problems,
          $repository->html_phrase(
                                   "validate:need_description",
                                   type => $document->render_citation("brief"),
                                   fieldname => $fieldname
                                  );
    } ## end if ($document->value("format"...))

    # security can't be "public" if date embargo set
    if ($document->value("security") eq "public"
        && EPrints::Utils::is_set($document->value("date_embargo")))
    {
        my $fieldname =
          $xml->create_element("span", class => "ep_problem_field:documents");
        push @problems,
          $repository->html_phrase("validate:embargo_check_security",
                                   fieldname => $fieldname);
    } ## end if ($document->value("security"...))

    #
##### embargo expiry date currently capped at 2 years
##### to change update my $embargo_cap
    #
    if (EPrints::Utils::is_set($document->value("date_embargo")))
    {
        my $value = $document->value("date_embargo");
        my ($thisyear, $thismonth, $thisday) = EPrints::Time::get_date_array();
        my ($year, $month, $day) = split('-', $value);
        if (   $year < $thisyear
            || ($year == $thisyear && $month < $thismonth)
            || ($year == $thisyear && $month == $thismonth && $day <= $thisday))
        {
            my $fieldname = $xml->create_element("span",
                                         class => "ep_problem_field:documents");
            push @problems,
              $repository->html_phrase("validate:embargo_invalid_date",
                                       fieldname => $fieldname);
        } ## end if ($year < $thisyear ...)

        my $embargo_cap = $thisyear + 1;
        if (   $year > $embargo_cap
            || ($year == $embargo_cap && $month > $thismonth)
            || (   $year == $embargo_cap
                && $month == $thismonth
                && $day >= $thisday))
        {
            my $fieldname = $xml->create_element("span",
                                         class => "ep_problem_field:documents");
            push @problems,
              $repository->html_phrase("validate:embargo_too_far_in_future",
                                       fieldname => $fieldname);

        } ## end if ($year > $embargo_cap...)

    } ## end if (EPrints::Utils::is_set...)
    return (@problems);
};

##### add eprint dataset fields

$c->add_dataset_field(
                      "eprint",
                      {
                       name   => 'bounding_box',
                       type   => 'compound',
                       fields => [
                                  {
                                   sub_name => 'north_edge',
                                   type     => 'float',
                                  },
                                  {
                                   sub_name => 'east_edge',
                                   type     => 'float',
                                  },
                                  {
                                   sub_name => 'south_edge',
                                   type     => 'float',
                                  },
                                  {
                                   sub_name => 'west_edge',
                                   type     => 'float',
                                  },
                                 ],
                      },
                      reuse => 1
                     );

$c->add_dataset_field(
                      "eprint",
                      {
                       name       => 'alt_title',
                       type       => 'longtext',
                       input_rows => 3,
                      },
                      reuse => 1
                     );

$c->add_dataset_field(
                      "eprint",
                      {
                       name       => 'collection_method',
                       type       => 'longtext',
                       input_rows => '10',
                      },
                      reuse => 1
                     );

$c->add_dataset_field(
                      "eprint",
                      {
                       name => 'grant',
                       type => 'text',
                      },
                      reuse => 1
                     );

$c->add_dataset_field(
		    "eprint",
		    {
		     name       => 'provenance',
		     type       => 'longtext',
		     input_rows => '3',
		    },
		    reuse => 1
                     );

$c->add_dataset_field(
                      "eprint",
                      {
                       name => 'restrictions',
                       type => 'text',
                      },
                      reuse => 1
                     );

$c->add_dataset_field(
                      "eprint",
                      {
                       name => 'geographic_cover',
                       type => 'text',
                      },
                      reuse => 1
                     );

$c->add_dataset_field(
		    "eprint",
		    {
		     name => 'language',
		     type => 'text',

		    },
		    reuse => 1
                     );

$c->add_dataset_field(
		    "eprint",
		    {
		     name => 'metadata_language',
		     type => 'text',

		    },
		    reuse => 1
                     );

$c->add_dataset_field(
                      "eprint",
                      {
                       name       => 'legal_ethical',
                       type       => 'longtext',
                       input_rows => '10',
                      },
                      reuse => 1
                     );

$c->add_dataset_field(
                      "eprint",
                      {
                       name        => 'terms_conditions_agreement',
                       type        => 'boolean',
                       input_style => 'medium',
                      },
                      reuse => 1
                     );

$c->add_dataset_field(
                      "eprint",
                      {
                       name   => 'collection_date',
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
                      reuse => 1
                     );

$c->add_dataset_field(
                      "eprint",
                      {
                       name   => 'temporal_cover',
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
                      reuse => 1
                     );

$c->add_dataset_field(
                      "eprint",
                      {
                       name => 'original_publisher',
                       type => 'text',
                      },
                      reuse => 1
                     );

$c->add_dataset_field(
		    "eprint",
		    {
		     name         => 'related_resources',
		     type         => 'compound',
		     multiple     => 1,
		     render_value => 'EPrints::Extras::render_url_truncate_end',
		     fields       => [
			 {
			  sub_name   => 'url',
			  type       => 'url',
			  input_cols => 40,
			 },
			 {
			  sub_name     => 'type',
			  type         => 'set',
			  render_quiet => 1,
			  options      => [
			      qw(
				pub
				author
				org
				)
			  ],
			 } ],
		     input_boxes   => 1,
		     input_ordered => 0,
		    },
		    reuse => 1
		     );

$c->add_dataset_field(
                      "eprint",
                      {
                       name => 'doi',
                       type => 'text',
                      },
                      reuse => 1
                     );

$c->add_dataset_field(
                      "eprint",
                      {
                       name => 'retention_date',
                       type => 'date',
                       render_res => 'day',
                      },
                      reuse => 1
                     );

$c->add_dataset_field(
                      "eprint",
                      {
                       name => 'retention_action',
                       type => 'text',
                      },
                      reuse => 1
                     );

$c->add_dataset_field(
                      "eprint",
                      {
                       name => 'retention_comment',
                       type => 'longtext',
                      },
                      reuse => 1
                     );


#### extra metadata that extends  the summary page record - hidden by js - accessed by additional details link

push(
    @{$c->{summary_page_metadata_full}},
    qw/
      alt_title
      creators
      corp_creators
      data_type
      contributors
      funders	
      collection_date
      temporal_cover
      grant
      date
      date_type
      geographic_cover
      bounding_box
      collection_method
      legal_ethical
      provenance
      note
      language
      metadata_language
      relation
      projects
      ispublished
      publisher
      restrictions
      copyright_holders
      contact_email
      lastmod
      /
    );


#### overide eprint_render

$c->{recollect_eprint_render} = $c->{eprint_render};

$c->{eprint_render} = sub {

    my ($eprint, $repository, $preview) = @_;
    
    if($eprint->value("type") ne "data_collection"){
            return $repository->call("recollect_eprint_render", $eprint, $repository, $preview);
         }

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

##########
    #
    #
    ##rd essex
    #
    #
##########

    #add rdessex div to append file content to
    my $div_right =
      $repository->make_element('div', class => "rd_citation_right");

    #add rdessex doc frag to add content to
    my $rddocsfrag = $repository->make_doc_fragment;

    #Add main Available Files h2 heading
    #Check if there are docs to display, if not print No files to display

    my $heading = $repository->make_element('h2', class => "file_list_heading");
    $heading->appendChild($repository->make_text(" Available Files"));
    $rddocsfrag->appendChild($heading);

    if (scalar( $eprint->get_all_documents() ) eq 0)
    {

        my $nodocs =
          $repository->make_element('p', class => "file_list_nodocs");
        $nodocs->appendChild($repository->make_text(" No Files to display"));
        $rddocsfrag->appendChild($nodocs);

    } ## end if ($doc_check eq 0)

    # add hashref to store our content types and associated files
    my $rdfiles = {};

    #get all documents from the eprint, then loop through and add each content type and associated files as a hash key and an array of values
    foreach my $rddoc ($eprint->get_all_documents())

    {

        my $content = $rddoc->get_value("content");
        {
            if (defined($content) && $content eq "full_archive")
            {
                push @{$rdfiles->{"rdarchive"}}, $rddoc;
            }
            elsif (defined($content) && $content eq "data")
            {
                push @{$rdfiles->{"rddata"}}, $rddoc;
            }
            elsif (defined($content) && $content eq "documentation")
            {
                push @{$rdfiles->{"rddocu"}}, $rddoc;
            }
            elsif (defined($content) && $content eq "readme")
            {
                push @{$rdfiles->{"rdreadme"}}, $rddoc;
            }
            elsif (defined($content) && $content eq "depmeta")
            {
                push @{$rdfiles->{"rddepmeta"}}, $rddoc;
            }

        }
    } ## end foreach my $rddoc ($eprint->get_all_documents...)

    # add a list of constants to generate our headings
    my $list = {

        "rdarchive" => 'Full Archive',
        "rddata"    => 'Data',
        "rddocu"    => 'Documentation',
        "rdreadme"  => 'Read me',
        "rddepmeta" => 'Departmental metadata'

    };

    # loop through a list of content types adding a header if files exist in the array
    foreach my $content_type (qw/ rdarchive rddata rddocu rdreadme rddepmeta /)
    {
        next unless (defined $rdfiles->{$content_type});
        my $rdheading = $repository->make_element('h2', class => "file_title");
        $rdheading->appendChild($repository->make_text($list->{$content_type}));
        $rddocsfrag->appendChild($rdheading);

        #if files exist, add a table to hold the filenames

        #begin rd table
        my $rdtable =
          $repository->make_element(
                                    "table",
                                    border      => "0",
                                    cellpadding => "2",
                                    width       => "100%"
                                   );

        $rddocsfrag->appendChild($rdtable);

        #for each document add a table row
        foreach my $rdfile (@{$rdfiles->{$content_type}})

        {
            my $tr  = $repository->make_element('tr');
            my $tdr = $repository->make_element('td', class => 'files_box');
            my $trm = $repository->make_element('tr');
            $tr->appendChild($tdr);

            #get the url and render the filename as a link
            my $a = $repository->render_link($rdfile->get_url);

            my $filetmp =
              substr($rdfile->get_url, (rindex($rdfile->get_url, "/") + 1));

            #check the length of the url first,  if more that 30 chars truncate the middle
            my $len = 30;
            my $filetmp_trunc;
            if (length($filetmp) > $len)
            {
                $filetmp_trunc =
                    substr($filetmp, 0, $len / 2) . " ... "
                  . substr($filetmp, -$len / 2);
            } ## end if (length($filetmp) >...)
            else
            {
                $filetmp_trunc = $filetmp;
            }

            #generate a doc id for javascript to target
            my $docid      = $rdfile->get_id;
            my $doc_prefix = "_doc_" . $docid;

            #add filemeta div
            my $filemetadiv =
              $repository->make_element(
                                        'div',
                                        id    => $doc_prefix . '_filemetadiv',
                                        class => 'rd_full'
                                       );

            #Add table to hold filemeta
            my $filetable =
              $repository->make_element(
                                        "table",
                                        id          => "filemeta",
                                        border      => "0",
                                        cellpadding => "2",
                                        width       => "100%"
                                       );

            #Render a row to hold the link to  extended metadata
            #If a value exists add a table row for each file metafield

            #check to see who should be able to access this document
            #if there's an embagro, print the date the doc becomes available
            #
            if (   (defined($rdfile->get_value("security"))) ne "public"
                && (defined($rdfile->get_value("date_embargo"))) ne "")
            {
                my $docavailable =
                  $repository->make_element('div', class => 'rd_doc_available',
                  );
                my $until       = $repository->make_text(' until ');
                my $dateembargo = $rdfile->render_value("date_embargo");
                my $security    = $rdfile->render_value("security");
                $docavailable->appendChild($security);
                $docavailable->appendChild($until);
                $docavailable->appendChild($dateembargo);
                $filetable->appendChild(
                    $repository->render_row(
                        $repository->html_phrase("document_fieldname_security"),
                        $docavailable
                    )
                );
            } ## end if ((defined($rdfile->get_value...)))
            else
            {

                $filetable->appendChild(
                    $repository->render_row(
                        $repository->html_phrase("document_fieldname_security"),
                        $rdfile->render_value("security")
                    )
                );
            } ## end else [ if ((defined($rdfile->get_value...)))]

            #
            # loop through the remaining document metadata and add a row of data for each -
            #
            #
            my @rd_filemeta_items =
              qw(content formatdesc rev_number mime_type license);

            # get the doc id to use as prefix on div ids

            foreach my $rd_filemeta_item (@rd_filemeta_items)
            {
                if (   $rdfile->is_set($rd_filemeta_item)
                    && $rd_filemeta_item eq "mime_type")
                {
                    $filetable->appendChild(
                        $repository->render_row(
                            $repository->html_phrase(
                                           "file_fieldname_" . $rd_filemeta_item
                            ),

                            #$rdfile->render_value($rd_filemeta_item_value)
                            $rdfile->render_value($rd_filemeta_item)
                                               )
                                           );
                } ## end if ($rdfile->is_set($rd_filemeta_item...))

                elsif ($rdfile->is_set($rd_filemeta_item))
                {
                    $filetable->appendChild(
                               $repository->render_row(
                                   $repository->html_phrase(
                                       "document_fieldname_" . $rd_filemeta_item
                                   ),
                                   $rdfile->render_value($rd_filemeta_item)
                               )
                    );
                } ## end elsif ($rdfile->is_set($rd_filemeta_item...))
            } ## end foreach my $rd_filemeta_item...

            # calculate the filesize of each file and print it
            if (defined($rdfile))
            {
                my %files         = $rdfile->files;
                my $size_in_bytes = ($files{$rdfile->get_main("filesize")});
                my $filesize = EPrints::Utils::human_filesize($size_in_bytes);

                {
                    $filetable->appendChild(
                        $repository->render_row(
                            $repository->html_phrase("file_fieldname_filesize"),
                            $repository->make_text($filesize)
                        )
                    );
                }
            } ## end if (defined($rdfile))

            #Append filetable to filemetadiv
            $filemetadiv->appendChild($filetable);

            #render our file name as a link element and append to the left-hand side of the table
            $a->appendChild($repository->make_text($filetmp_trunc));

            #render a collapsible box to house our filemeta table

            my ($self) = @_;

            my %options;
            $options{session}   = $self->{session};
            $options{id}        = $doc_prefix . "_file_meta";
            $options{title}     = $a;
            $options{content}   = $filemetadiv;
            $options{collapsed} = 1;
            my $filebox = EPrints::Box::render(%options);

            #Append filemetabox to our file table
            $tdr->appendChild($filebox);

            #Append whole row to table
            $rdtable->appendChild($tr);

        } ## end foreach my $rdfile (@{$rdfiles...})

    } ## end foreach my $content_type (...)

    #Append the whole fragment to div_right, then add div_right to the fragments hash to be sent to the dom
    $div_right->appendChild($rddocsfrag);
    $fragments{rd_sorteddocs} = $div_right;

    foreach my $key (keys %fragments)
    {
        $fragments{$key} = [$fragments{$key}, "XHTML"];
    }

    my $page = $eprint->render_citation("recollect_summary_page", %fragments,
                                        flags => $flags);

    my $title = $eprint->render_citation("brief");
    my $links = $repository->xml()->create_document_fragment();
    if (!$preview)
    {
        $links->appendChild($repository->plugin("Export::Simple")
                            ->dataobj_to_html_header($eprint));
        $links->appendChild(
            $repository->plugin("Export::DC")->dataobj_to_html_header($eprint));
    } ## end if (!$preview)

    return ($page, $title, $links);
};

##### update advanced search

$c->{search}->{advanced} = 
{
	search_fields => [
		{ meta_fields => [ "documents" ] },
		{ meta_fields => [ "creators_name" ] },
        { meta_fields => [ "title" ] },
        { meta_fields => [ "abstract" ] },
		{ meta_fields => [ "date" ] },
		{ meta_fields => [ "keywords" ] },
		{ meta_fields => [ "subjects" ] },
#		{ meta_fields => [ "department" ] },
		{ meta_fields => [ "divisions" ] },
	],
	preamble_phrase => "cgi/advsearch:preamble",
	title_phrase => "cgi/advsearch:adv_search",
	citation => "result",
	page_size => 20,
	order_methods => {
		"byyear" 	 => "-date/creators_name/title",
		"byyearoldest"	 => "date/creators_name/title",
		"byname"  	 => "creators_name/-date/title",
		"bytitle" 	 => "title/creators_name/-date"
	},
	default_order => "byyear",
	show_zero_results => 1,
};



