# Local plugin file to overide a specific method of perl_lib/Eprints/DataObj/File.pm
# This is an alternative to using a bazaar plugin which ovewrites the complete File.pm
# package via the core lib directory. Therefore, only a local copy of the repository will
# have the change. The fix uses John Salters method which can be found here:
# http://blog.soton.ac.uk/oneshare/2009/09/25/taking-stock-and-mopping-up-the-mess-i-made-of-eprints/

package EPrints::Plugin::NewFile;

@ISA = ( 'EPrints::DataObj::File' );

use strict;

# This line allows the core package to be overwitten
package EPrints::DataObj::File;


sub set_file
{
	my( $self, $content, $clen ) = @_;

	$self->{session}->get_storage->delete( $self );

	$self->set_value( "filesize", 0 );
	$self->set_value( "hash", undef );
	$self->set_value( "hash_type", undef );

	return 0 if $clen == 0;

	use bytes;
	# on 32bit platforms this will cause wrapping at 2**31, without integer
	# Perl will wrap at some much larger value (so use 64bit O/S!)
	# use integer;

	# calculate the SHA256 as the data goes past
	my $sha = Digest::SHA->new('256');

	my $f;
	if( ref($content) eq "CODE" )
	{
		$f = sub {
				my $buffer = &$content;
				$sha->add( $buffer );
				return $buffer;
			};
	}
	elsif( ref($content) eq "SCALAR" )
	{
		return 0 if length($$content) == 0;

		my $i = 0;
		$f = sub {
				return "" if $i++;
				$sha->add( $$content );
				return $$content;
			};
	}
	else
	{
		binmode($content);
		$f = sub {
				return "" unless sysread($content,my $buffer,16384);
				$sha->add( $buffer );
				return $buffer;
			};
	}

	my $rlen = do {
		local $self->{data}->{filesize} = $clen;
		$self->{session}->get_storage->store( $self, $f );
	};

	# no storage plugin or plugins failed
	if( !defined $rlen )
	{
		$self->{session}->log( $self->get_dataset_id."/".$self->get_id."::set_file(".$self->get_value( "filename" ).") failed: No storage plugins succeeded" );
		return undef;
	}

	# read failed
	if( $rlen != $clen )
	{
		$self->{session}->log( $self->get_dataset_id."/".$self->get_id."::set_file(".$self->get_value( "filename" ).") failed: expected $clen bytes but actually got $rlen bytes" );
		return undef;
	}

	$self->set_value( "filesize", $rlen );
	$self->set_value( "hash", $sha->hexdigest );
	$self->set_value( "hash_type", "SHA256" );

	return $rlen;
}
