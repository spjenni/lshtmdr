#JM: we return $count to update the real number of items after being filtered.
#    this requires hacking perl_lib/Update/Views.pm

$c->{render_no_nulls} = sub
{
	my( $repo, $item_list, $view_definition, $path_to_this_page, $filename ) = @_;
	
	my $xml = $repo->xml();

	my $doc_frag = $xml->create_element("div");
	my $count=0;
	foreach my $item ( @{$item_list} ){
		if($item->value("full_text_status") eq "public" || $item->value("full_text_status") eq "restricted" ){
			$doc_frag->appendChild($xml->create_element("p"));
			$doc_frag->appendChild($item->render_citation_link("views"));
			$doc_frag->appendChild($xml->create_element("p"));
			$count++;
		}
	}
	
	return ($doc_frag, $count);
};


#JM: to render lshtmids as names

# the view id to be used in
#   EPrints::Update::Views::update_view_list
#   EPrints::Script::Compiled::run_label_link
$c->{creators_view_id} = 'creators';


$c->{ulcc_render_view_menu_id_author} = sub
{
  # this is basically EPrints::Update::Views::render_menu adapted
	my( $repo, $view, $sizes, $values, $fields, $has_submenu ) = @_;

	my $xml = $repo->xml();

	my $cols = 3;
	my $col_len = POSIX::ceil( scalar @{$values} / $cols );
	
	my $col_n = 0;
	my $table = $xml->create_element( "table", cellpadding=>"0", cellspacing=>"0", border=>"0", class=>"ep_view_cols ep_view_cols_$cols" );
	my $tr = $xml->create_element( "tr" );
	$table->appendChild( $tr );
	my $add_ul;
	
	
	for( my $i=0; $i<@{$values}; ++$i )
	{
		if( $cols>1 && $i % $col_len == 0 )
		{
			++$col_n;
			my $td = $repo->make_element( "td", valign=>"top", class=>"ep_view_col ep_view_col_".$col_n );
			$add_ul = $repo->make_element( "ul" );
			$td->appendChild( $add_ul );	
			$tr->appendChild( $td );	
		}
		
		my $value = $values->[$i];
		next unless( EPrints::Utils::is_set($value) );
		
		my $size = 0;
		my $id = $fields->[0]->get_id_from_value( $repo, $value );
		if( defined $sizes && defined $sizes->{$id} )
		{
			$size = $sizes->{$id};
		}
		next if( $size == 0 );
		
		my $fileid = $fields->[0]->get_id_from_value( $repo, $value );

		my $li = $repo->make_element( "li" );

		my $name = $repo->call( "name_from_creatorid", $repo, $value );
		unless( $name )
		{
		  $repo->log("[ulcc_render_view_menu_id_author] no name found for LSHTM ID: $id");
		  next;
		}
		my $xhtml_value = $repo->render_name( $name );

		my $link = EPrints::Utils::escape_filename( $fileid );
		if( $has_submenu ) { $link .= '/'; } else { $link .= '.html'; }
		my $a = $repo->render_link( $link );
		$a->appendChild( $xhtml_value );
		$li->appendChild( $a );

		if( defined $sizes && defined $sizes->{$fileid} )
		{
			$li->appendChild( $repo->make_text( " (".$sizes->{$fileid}.")" ) );
		}
		$add_ul->appendChild( $li );
	}
	while( $cols > 1 && $col_n < $cols )
	{
		++$col_n;
		my $td = $repo->make_element( "td", valign=>"top", class=>"ep_view_col ep_view_col_".$col_n );
		$tr->appendChild( $td );	
	}

	return $table;
};

#Chris Yates (21/05/10) - Start - Allows ordering of authors by surname using id's
$c->{group_by_author} = sub
{
        my( $repo, $menu, $menu_fields, $values, $n ) = @_;

        $n = 1; #Number of characters to order by

        my $sections = {};
        foreach my $value ( @{$values} )
        {
                #JM: ignore empty strings
                next if ( !defined($value) or length($value) == 0 );
                
                #Get surname to use as grouping value
#               my $name = EPrints::DataObj::User::name_from_username( $session, $value );
#               $repo->log("Value: $value");
                my $name = $repo->call( "name_from_creatorid", $repo, $value );
#               $repo->log("Name: $name");
                my $family = $name->{family};

                if(!defined $family) {
                        $family = $value;
                }

                my $v = EPrints::Utils::tree_to_utf8(
                                $menu_fields->[0]->render_single_value( $repo, $family) );

                utf8::decode( $v );
                # lose everything not a letter or number
                $v =~ s/[^\p{L}\p{N}]//g;

                my $start = uc substr( $v, 0, $n );
                #JM: to report content in odd sections
                if( $start eq "" )
                {
                  $repo->log("$value generated ?");
                }
                $start = "?" if( $start eq "" );
                utf8::encode( $start );

                push @{$sections->{$start}}, $value;
        }
        
        foreach my $c ( 'A'..'Z' )
        {
                if(defined $sections->{$c}) {

                        my $Collator = Unicode::Collate->new();
                        my @vs = @{$sections->{$c}};

                        my %sort;
                        foreach my $id ( @vs )
                        {
#                               my $user = EPrints::DataObj::User::name_from_username( $session, $id );
				                        my $user = $repo->call( "name_from_creatorid", $repo, $id );

                                my $surname = defined $user->{family} ? $user->{family} : 'unknown';
                                my $forename = defined $user->{given} ? $user->{given} : 'unknown';
                                $sort{$id} = defined $user ? $surname.$forename : 'unknown';
                        }

                        my @sorted = sort { $Collator->cmp( $sort{$a}, $sort{$b} ) } keys %sort;
                        $sections->{$c} = \@sorted;
                }
#RM removed as this will render empty groups (new to 3.3.12)                
#                else
#                {
#                        $sections->{$c} = [];
#                }
        }
        return $sections;
};
#Chris Yates (21/05/10) - End

#JM: retrieve name from creator id
$c->{name_from_creatorid} = sub
{
  my( $repo, $creatorid ) = @_;

  # consider incoming empty strings
  return if ( !defined $creatorid or length($creatorid) == 0 );
  
  # we build a cached authority list if it has not been built or if we have a non-cached creator id
  my $generate_cache = 0;
    
  if ( !(defined $repo->{name_from_creatorid_cached} and $repo->{name_from_creatorid_cached}) )
  {
    $generate_cache = 1;
    #$repo->log("[name_from_creatorid] Cached authority list not found, set to generate.\n");
  }
  elsif ( !defined $repo->{name_from_creatorid_cache}->{$creatorid} )
  {
    $generate_cache = 1;
    #$repo->log("[name_from_creatorid] LSHTM ID $creatorid not cached, setting cache to re-generate.\n");
  }   
  
  if ($generate_cache)
  {
    #$repo->log("[name_from_creatorid] Generating cache for lshtmid to name conversion...");
    my $db = $repo->database;
    my $sql = "SELECT creators_lshtmid AS lshtmid, creators_name_family AS family, creators_name_given AS given";
    $sql .= " FROM";
    $sql .= "           ( SELECT      eprintid, MIN(pos) as pos, creators_lshtmid";
    $sql .= "             FROM      ( SELECT    MAX(eprintid) AS eprintid, creators_lshtmid";
    $sql .= "                         FROM      eprint_creators_lshtmid";
    $sql .= "                         WHERE     LENGTH(creators_lshtmid)>0";
    $sql .= "                         GROUP BY  creators_lshtmid) MAX_EPRINTIDS";
    $sql .= "             LEFT JOIN eprint_creators_lshtmid";
    $sql .= "             USING     (eprintid, creators_lshtmid)";
    $sql .= "             GROUP BY  eprintid, creators_lshtmid";
    $sql .= "           ) LSHTMID";
    $sql .= " LEFT JOIN eprint_creators_name";
    $sql .= " USING     (eprintid, pos);";
    my $sth = $db->prepare($sql);
    $sth->execute;
    $repo->{name_from_creatorid_cache} = $sth->fetchall_hashref('lshtmid');
    
    $repo->{name_from_creatorid_cached} = 1;
    #$repo->log("[name_from_creatorid] \t Done.");
  }
  
  if ( $repo->{name_from_creatorid_cache}->{$creatorid} )
  {
    return $repo->{name_from_creatorid_cache}->{$creatorid};
  }
  else
  {
    # this should not happen: would mean an lshtmid without a name
    $repo->log("[name_from_creatorid] ERROR: $creatorid -> NOT FOUND\n");
    return "ID: $creatorid";
  }
};
