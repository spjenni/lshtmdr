
$c->{set_document_defaults} = sub 
{
	my( $data, $repository, $eprint ) = @_;

	$data->{language} = $repository->get_langid();
	$data->{security} = "public";

	#Conditional defaults from from recollect
	if($eprint->value("type") eq "data_collection"){
		$data->{retention_period} = "indefinite";
	}

};
