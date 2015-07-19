package EPrints::Plugin::Event::CoinSequentialDOI;
use strict;
our @ISA = qw/ EPrints::Plugin::Event /;
#now for the clever bit
package EPrints::Plugin::Event::DataCiteEvent;

#RM lets do the DOI coining somewhere (reasonably) accessible 

sub coin_doi {

    my( $self, $repository, $dataobj) = @_;
    
    my $session = $self->{session};
	print STDERR "###### in overridden coin_doi#########\n";
    # SJ: added to create sequential DOI ids according RM's allow_custom_doi format
    my $doi_id = $dataobj->id;

    if( $repository->get_conf( "datacitedoi", "start_sequential_doi" ) )
    {
		$doi_id = $self->sequential_doi( $session, $repository,$dataobj ); 	
	}

	#RM zero padds eprintid as per config
	my $z_pad = $repository->get_conf( "datacitedoi", "zero_padding") || 0;
	my $id  = sprintf("%0".$z_pad."d", $doi_id);

	#Check for custom delimiters
	my ($delim1, $delim2) = @{$repository->get_conf( "datacitedoi", "delimiters")};
	#default to slash
	$delim1 = "/" if(!defined $delim1);
	#second defaults to first
	$delim2 = $delim1 if(!defined $delim2);
	#construct the DOI string
	my $prefix = $repository->get_conf( "datacitedoi", "prefix");
	my $thisdoi = $prefix.$delim1.$repository->get_conf( "datacitedoi", "repoid").$delim2.$id;

	my $eprintdoifield = $repository->get_conf( "datacitedoi", "eprintdoifield");
	
	#Custom DOIS
	#if DOI field is set attempt to use that if config allows
	if($dataobj->exists_and_set( $eprintdoifield) ){

		#if config does not allow ... bail
		if( !$repository->get_conf( "datacitedoi", "allow_custom_doi" ) ){
			$repository->log("DOI is already set and custom overrides are disaallowed by config");
			return EPrints::Const::HTTP_INTERNAL_SERVER_ERROR;
		}
		#we are allowed (check prefix just in case)
		$thisdoi = $dataobj->get_value( $eprintdoifield );
		if($thisdoi !~ /^$prefix/){
			$repository->log("Prefix does not match ($prefix) for custom DOI: $thisdoi");
			$dataobj->set_value($eprintdoifield, ""); #unset the bad DOI!!
			$dataobj->commit();
			return EPrints::Const::HTTP_INTERNAL_SERVER_ERROR;
		}#We'll leave Datacite to do any further syntax checking etc...
	}

	return $thisdoi;
};

sub sequential_doi {
	
	my( $session, $repository, $dataobj) = @_;
	
	my $ds = $repository->get_dataset('archive');
	
	# check for eprints with DOIs
	my @filters = (
		{ meta_fields => [qw( id_number )], value => "",  match => "SET"},
    );
	
	# create the search
	my $search = new EPrints::Search( 
		session=>$session, 
		dataset=>$ds );
		
	# search list
	my $list = $ds->search(
		filters => \@filters,
    );
	
	# check to see if any DOis have been coined, if not set first DOI in system to be 1
	if (!defined $list or $list->count < 1)
	{
		return 1;
	}
	else
	{
		# add 1 to the courrent count so that DOI has sequentialy allocated ID 
		return ( $list->count() + 1 );
	}
};
