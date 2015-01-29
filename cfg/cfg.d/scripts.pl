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
