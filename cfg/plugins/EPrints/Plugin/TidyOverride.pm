package EPrints::Plugin::TidyOverride;

@ISA = ('EPrints::Plugin');

use strict;

package EPrints::DataObj;

no warnings;

sub tidy
{
        my( $self ) = @_;

        foreach my $field ( $self->{dataset}->get_fields )
        {
                next if !$field->property( "multiple" );
                next if $field->isa( "EPrints::MetaField::Subobject" );

                # tidy at the compound-field level only (no sub-fields)
                next if defined $field->property( "parent_name" );

                my $value_arrayref = $field->get_value( $self );
                next if !EPrints::Utils::is_set( $value_arrayref );

                my @list;
                my $set = 0;
                foreach my $item ( @{$value_arrayref} )
                {
                        #RM Hack deeeep in the core!!
                        #but we need this to not set even if the boolean flag is defined...
                        #if it is no and nothing else is defined then don't set!!!

                        if(ref($item) eq "HASH" && defined $item->{lshtm_flag}){
                                if(!defined $item->{lshtmid} &&
                                        !defined $item->{name} &&
                                        !defined $item->{id}){
                                        $set = 1;
                                        next;
                                }

                        }
                        if( !EPrints::Utils::is_set( $item ) )
                        {
                                $set = 1;
                                next;
                        }
                        push @list, $item;
                }

                # set if there was a blank line
                if( $set )
                {
                        $field->set_value( $self, \@list );
                }

                # directly add this to the data if it's a compound field
                # this is so that the ordervalues code can see it.
                if( $field->isa( "EPrints::MetaField::Compound" ) )
                {
                        $self->{data}->{$field->get_name} = \@list;
                }
        }
}

