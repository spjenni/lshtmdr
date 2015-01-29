=head1 NAME

EPrints::Plugin::Screen::EPrint::CollectionDetails

=cut

package EPrints::Plugin::Screen::EPrint::CollectionDetails;

@ISA = ( 'EPrints::Plugin::Screen::EPrint::Details' );

use strict;

sub workflow_id
{
        my ( $self ) = @_;

        if( $self->{processor}->{eprint}->value("type") eq "collection" )
        {
                return "collection";
        }
        return "default";
}
