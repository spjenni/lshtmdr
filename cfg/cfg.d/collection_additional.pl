package EPrints::DataObj::EPrint;

no warnings;

use strict;

our @ISA = qw/ EPrints::DataObj /;


#RM adds this inverse relation...
# $collection->add_from_collection( $eprintid );


sub add_from_collection
{
        my( $self, $eprint ) = @_;

		my $repo = $self->{session};
        
       # my $eprint = EPrints::DataSet->get_object_from_uri( $repo, $targetid );
        if( !defined $eprint )
        {
                return 0;
        }

        if( $eprint->value("type") eq $self->value("type") )
        {
                return 0;
        }

 	 	return 0 unless( $self->is_collection );

        return 0 if( $self->belongs( $eprint->get_id ) );

        
        my $r = $self->value("relation");

               my $er = $eprint->value("relation");

        push @$er, { type => 'http://purl.org/dc/terms/isPartOf', uri => $self->internal_uri };

        $eprint->set_value( 'relation', $er );
        $eprint->commit;
        $eprint->remove_static;

        return 1;
 };
