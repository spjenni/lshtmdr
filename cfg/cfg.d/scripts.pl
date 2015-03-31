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
                    substr($url, 0, $len / 2) . " ... "
                  . substr($url, -$len / 2);
            } ## end if (length($filetmp) >...)
            else
            {
                $url_trunc = $url;
            }

	return [ $url_trunc, "STRING" ];
}
