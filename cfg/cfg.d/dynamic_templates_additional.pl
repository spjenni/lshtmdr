# SJ: Additional pins 

$c->{dynamic_template}->{function} = sub {

	my( $repository, $parts ) = @_;
	
	my $year =  (localtime)[5] + 1900;
 
	$parts->{year} = $repository->make_text( $year );
};
