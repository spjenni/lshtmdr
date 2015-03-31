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
	my( $self, $state, $eprint, $format ) = @_;

	if( ! $eprint->[0]->isa( "EPrints::DataObj::EPrint") )
	{
		$self->runtime_error( "documents() must be called on an eprint object." );
	}
	$format = $format->[0];
	$eprint = $eprint->[0];

	my $sorteddocs = [];
	for my $doc($eprint->get_all_documents()){
		next if($format ne $doc->value("format"));
		push @$sorteddocs, $doc;
	}
	return [ [@$sorteddocs],  "ARRAY" ];

}

