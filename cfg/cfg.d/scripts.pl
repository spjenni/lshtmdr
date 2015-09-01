package EPrints::Plugin::ScriptPlugin;

use strict;

our @ISA = qw/EPrints::Plugin/;

#now for the cliever bit

package EPrints::Script::Compiled;

sub run_current_user
{
	my( $self, $state ) = @_;

	return [ $state->{session}->current_user(),  "STRING" ];
}

sub run_export_bar
{
	my( $self, $state, $eprint ) = @_;

	if( ! $eprint->[0]->isa( "EPrints::DataObj::EPrint") )
	{
		$self->runtime_error( "documents() must be called on an eprint object." );
	}
	$eprint = $eprint->[0];
	my $repository = $state->{session}->get_repository();
	my $export_bar = $repository->make_element( "div", style => "ep_block" );
	
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
	
	foreach my $plugin (@plugins)
	{
	    my $plugin_id = $plugin->get_id;
	    $plugin_id =~ s/^Export:://;
	    my $option = $repository->make_element( "option", value => $plugin_id );
	    $select->appendChild( $option );
	    $option->appendChild( $plugin->render_name );
	}
	my $button = $repository->make_element( "input", type => "submit", value => $repository->phrase( "lib/searchexpression:export_button" ), class => "ep_form_action_button" );
	$form->appendChild( $button );
	
	return [ $export_bar, "XHTML" ];
}

sub run_documents_recollect
{
	my( $self, $state, $eprint, $content ) = @_;

	if( ! $eprint->[0]->isa( "EPrints::DataObj::EPrint") )
	{
		$self->runtime_error( "documents() must be called on an eprint object." );
	}
	$content = $content->[0];
	$eprint = $eprint->[0];

	my $sorteddocs = [];
	for my $doc($eprint->get_all_documents()){
		next if($content ne $doc->value("content"));
		push @$sorteddocs, $doc;
	}
	return [ [@$sorteddocs],  "ARRAY" ];

}
#this is really the size fot he doc's main file
sub run_human_doc_size
{
	my( $self, $state, $doc ) = @_;

	if( !defined $doc->[0] || ref($doc->[0]) ne "EPrints::DataObj::Document" )
	{
		$self->runtime_error( "Can only call doc_zie() on document objects not ".
			ref($doc->[0]) );
	}

	if( !$doc->[0]->is_set( "main" ) )
	{
		return 0;
	}

	my %files = $doc->[0]->files;

	return [ EPrints::Utils::human_filesize($files{$doc->[0]->get_main}) || 0, "INTEGER" ];
}

sub run_doc_mime
{
	my( $self, $state, $doc ) = @_;

	if( !defined $doc->[0] || ref($doc->[0]) ne "EPrints::DataObj::Document" )
	{
		$self->runtime_error( "Can only call doc_zie() on document objects not ".
			ref($doc->[0]) );
	}

	if( !$doc->[0]->is_set( "main" ) )
	{
		return 0;
	}
	my $fileobj = $doc->[0]->stored_file( $doc->[0]->get_main );

	return [ $fileobj->value("mime_type"), "STRING" ];
}

sub run_truncate_url
{
	my( $self, $state, $obj, $url ) = @_;

     	 #check the length of the url first,  if more that 30 chars truncate the middle
            my $len = 30;
            my $url_trunc;
		    $url = $url->[0];
            if (length($url) > $len)
            {
                $url_trunc =
                    substr($url, 0, $len / 2) . " >"
                  . substr($url, -$len / 2);
            } ## end if (length($filetmp) >...)
            else
            {
                $url_trunc = $url;
            }

	return [ $url_trunc, "STRING" ];
}

#SJ: returns an XHTML file name that breaks every 36 chars
sub run_truncate_url_xhtml
{
	my( $self, $state, $obj, $url ) = @_;

	my $repository = $state->{session}->get_repository();
	my $frag = $repository->make_doc_fragment();
	
	$url = $url->[0];
	
	# check for file extension
	my $ext = index( $url, '.' );
	
	# remove the extension
	if( $ext != -1 )
	{
			$url = substr( $url,0, $ext);
	} 

	# if a more than 1 line make the first line 36 chars
	# then make the the following lines 39 chars for (reasonable)
	# alignment
	if(length($url) > 36)
	{
		my $first_str = substr($url, 0, 35);		
		my $last_str = substr($url, 35, length($url));
		
		my @filename_parts = $last_str =~ /(.{1,38})/g;
		unshift(@filename_parts, $first_str);
	
		foreach (@filename_parts) 
		{
			$frag->appendChild($repository->make_text($_));
			$frag->appendChild($repository->make_element( "br" ));
		} 
	}
	# otherwise just add the file name
	else
	{
		$frag->appendChild($repository->make_text($url));
	}
	return [ $frag, "XHTML" ];
}

#I hope there turns out ot be a better way to do this...
sub run_raw_set_value
{
	my( $self, $state, $objvar, $value ) = @_;

	if( !defined $objvar->[0] )
	{
		$self->runtime_error( "can't get a property {".$value->[0]."} from undefined value" );
	}
	my $ref = ref($objvar->[0]);
	if( $ref eq "HASH" || $ref eq "EPrints::RepositoryConfig" )
	{
		my $v = $objvar->[0]->{ $value->[0] };
		my $type = ref( $v ) =~ /^XML::/ ? "XHTML" : "STRING";
		return [ $v, $type ];
	}
	if( $ref !~ m/::/ )
	{
		$self->runtime_error( "can't get a property from anything except a hash or object: ".$value->[0]." (it was '$ref')." );
	}
	if( !$objvar->[0]->isa( "EPrints::DataObj" ) )
	{
		$self->runtime_error( "can't get a property from non-dataobj: ".$value->[0] );
	}
	if( !$objvar->[0]->get_dataset->has_field( $value->[0] ) )
	{
		$self->runtime_error( $objvar->[0]->get_dataset->confid . " object does not have a '".$value->[0]."' field" );
	}
	return [ $objvar->[0]->get_value( $value->[0] ), "STRING"];
}

#SJ: returns an XHTML file name that breaks every 39 chars
sub run_truncate_lshtm
{
	my( $self, $state, $obj, $title ) = @_;

	my $repository = $state->{session}->get_repository();
	my $frag = $repository->make_doc_fragment();
	
	my $name = $title->[0];

	if(length($name) > 40)
	{
		my $first_str = substr($name, 0, 39);
		$first_str =~ s/\s+\w+$//;

		$frag->appendChild($repository->make_text($first_str."... > view"));
	}
	# otherwise just add the file name
	else
	{
		$frag->appendChild($repository->make_text($name." > view"));
	}

	return [ $frag, "XHTML" ];
}

sub run_truncate_rr
{
	my( $self, $state, $obj, $title ) = @_;

	my $repository = $state->{session}->get_repository();
	my $frag = $repository->make_doc_fragment();
	
	my $name = $title->[0];

	if(length($name) > 40)
	{
		my $first_str = substr($name, 0, 38);
		$first_str =~ s/\s+\w+$//;

		$frag->appendChild($repository->make_text($first_str."... > view "));
		$frag->appendChild($repository->make_element( "br" ));
	}
	# otherwise just add the file name
	else
	{
		$frag->appendChild($repository->make_text($name));
	}

	return [ $frag, "XHTML" ];
}
