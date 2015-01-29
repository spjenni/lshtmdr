=head1 NAME

EPrints::Plugin::Export::lshtmdr_HTML

=cut

package EPrints::Plugin::Export::lshtmdr_HTML;

# eprint needs magic documents field

# documents needs magic files field

use EPrints::Plugin::Export::HTMLFile;

@ISA = ( "EPrints::Plugin::Export::HTML" );

use strict;

sub output_dataobj
{
        my( $plugin, $dataobj ) = @_;

    	my $xml = $plugin->xml_dataobj( $dataobj );

#	$plugin->{session}->log(EPrints::XML::to_string( $xml, undef, 1 ));
#	$plugin->{session}->log("###########################");
        
        return EPrints::XML::to_string( $xml, undef, 1 );
};

sub output_list
{
        my( $plugin, %opts ) = @_;

        my $r = [];
       
        $opts{list}->map( sub {
                my( $session, $dataset, $item ) = @_;

                my $part = $plugin->output_dataobj( $item, %opts );
                if( defined $opts{fh} )
                {
                      print {$opts{fh}} "<base target=\"_parent\"/> \n"; 
                      print {$opts{fh}} $part;
                }
                else
                {
                        push @{$r}, $part;
                }
        } );

        if( defined $opts{fh} )
        {
                return undef;
        }

        return join( '', @{$r} );
}
1;

