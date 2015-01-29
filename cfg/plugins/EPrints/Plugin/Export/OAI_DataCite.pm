=head1 NAME

EPrints::Plugin::Export::OAI_DataCite

=cut

package EPrints::Plugin::Export::OAI_DataCite;


######################################################################
# Copyright (C) British Library Board, St. Pancras, UK
#
# Author: Steve Carr, British Library
# Email: stephen.carr@bl.uk
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
######################################################################

use EPrints::Plugin::Export;

@ISA = ( "EPrints::Plugin::Export" );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my $self = $class->SUPER::new( %opts );

	$self->{name} = "Datacite DC OAI Schema";
	$self->{accept} = [ 'dataobj/eprint' ];
	$self->{visible} = "";
	$self->{is_advertised} = 1;
	$self->{suffix} = ".xml";
	$self->{mimetype} = "text/xml";
	
	$self->{metadataPrefix} = "oai_datacite";
	$self->{xmlns} = "http://datacite.org/schema/kernel-3";
	$self->{schemaLocation} = "http://datacite.org/schema/kernel-3/metadata.xsd";

	return $self;
}


sub output_dataobj
{
	my( $plugin, $dataobj ) = @_;

	my $xml = $plugin->xml_dataobj( $dataobj );

	return EPrints::XML::to_string( $xml );
}




#######################################################################
#
# Steve Carr - eprints revision (standard revision in order to offer
# something other than basic dublin core - which isn't going to be enough
# to encode the complex data that we are dealing with for e-theses)
# This subroutine takes an eprint object and renders the XML DOM
# to export as the uketd_dc default format in OAI.
#
######################################################################

sub xml_dataobj
{
	my( $plugin, $eprint ) = @_;

	# we have a variety of namespaces since we're doing qualified dublin core, so we need an
	# array of references to three element arrays in our data structure
#	my @etdData = $plugin->eprint_to_oai_datacite( $eprint );
	
	my $namespace = $plugin->{xmlns};
	my $schema = $plugin->{schemaLocation};
	my $prefix = $plugin->{metadataPrefix};

	my $repo = $plugin->{session};
        # the eprint may well be null since it may not be a thesis but an article
        my $oai_datacite = $repo->make_element(
		"oai_datacite:resource",
		"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
		"xsi:schemaLocation" => $namespace." ".$schema,
		"xmlns:oai_datacite" => $namespace,
	);

	if($eprint->is_set( "id_number")){
		$oai_datacite->appendChild( $plugin->{session}->render_data_element( 8, $prefix.":identifier", $eprint->value("id_number"), "identifierType"=> "DOI"  ) );
	}else{
		$oai_datacite->appendChild( $plugin->{session}->render_data_element( 8, $prefix.":identifier", $eprint->uri, "identifierType"=> "URL"  ) );

	}

		my $creators = $eprint->get_value( "creators" );
		if( defined $creators ){
			my $cs = $repo->make_element($prefix.":creators");
	
			$oai_datacite->appendChild($cs);
			foreach my $creator ( @{$creators} ){
				my $c = $repo->make_element($prefix.":creator");
				$cs->appendChild($c);
				$c->appendChild($plugin->{session}->render_data_element(12,$prefix.":creatorName", EPrints::Utils::make_name_string( $creator->{name} )));

				if(defined $creator->{orcid}){
					$c->appendChild($plugin->{session}->render_data_element(12,$prefix.":nameIdentifier",  $creator->{orcid}, nameIdentifierScheme => "ORCID", schemeURI=>"http://www.orcid.org"));
				}
	
			}
		}
		$oai_datacite->appendChild( $plugin->{session}->render_data_element( 8, $prefix.":title", $eprint->value("title") ) );
		if($eprint->is_set("alt_title")){
			$oai_datacite->appendChild( $plugin->{session}->render_data_element( 8, $prefix.":title", $eprint->value("alt_title"), "titleType"=>"AlternativeTitle"  ) );
		}
		if($eprint->is_set("publisher")){
			$oai_datacite->appendChild( $plugin->{session}->render_data_element( 8, $prefix.":publisher", $eprint->value("publisher") ) );
		}
		#publicationYear will be latest embargo date or the publication date (?)
		#check embargos
		my @documents = $eprint->get_all_documents();
		my $mimetypes = $repo->config( "oai", "mime_types" );
		my $embargo_year=0;
		my $contents;
		my $licenses;
		my $license_form_url;

		for my $doc( @documents ){
			my $format = $mimetypes->{$doc->get_value("format")};
			$format = $doc->get_value("format") unless defined $format;
			#TODO use format
			#embargo for publicationYear (not tested)
			my $embargo = 0;			
			if ($doc->is_set("date_embargo")){
				$embargo = $doc->get_value("date_embargo") ;
				$embargo =~ /^(\d{4})/;
				$embargo = $1;
			}	
			if(defined $embargo && $embargo > $embargo_year){
				$embargo_year = $embargo;
			}
			#content for resourceType (not used)
			 if($doc->is_set("content")){
				$contents->{$doc->value("content")} = 0 if(!defined $contents->{$doc->value("content")});
				$contents->{$doc->value("content")}++;

			 	if($doc->value("content") eq "licence_form"){
					$license_form_url = $doc->url;
				}
			}
			#licences for RightsList
			 if($doc->is_set("license")){
				my $license_phrase = $repo->phrase("licenses_typename_".$doc->value("license"));
				$licenses->{$license_phrase} = 0 if(!defined $licenses->{$license_phrase});	
				$licenses->{$license_phrase} = $repo->phrase("licenses_typename_".$doc->value("license")."_uri") if($doc->value("license") ne "attached");
			}
		}	
		$licenses->{$repo->phrase("licenses_typename_attached")} = $license_form_url;

		if($embargo_year){
			$oai_datacite->appendChild( $plugin->{session}->render_data_element( 8, $prefix.":publicationYear", $embargo_year ) );
		}elsif($eprint->is_set("date")){
			my $ds = $eprint->value("datestamp");
			$oai_datacite->appendChild( $plugin->{session}->render_data_element( 8, $prefix.":publicationYear", $ds ) );	
		}
		my $contributors = $eprint->get_value( "contributors" );
		if( defined $contributors ){
			my $cs = $repo->make_element($prefix.":contributors");	
			$oai_datacite->appendChild($cs);
			foreach my $contributor ( @{$contributors} ){
				my $c = $repo->make_element($prefix.":contributor");
				$cs->appendChild($c);
				$c->appendChild($plugin->{session}->render_data_element(12,$prefix.":contributorName", EPrints::Utils::make_name_string( $contributor->{name} )));

				if(defined $contributor->{orcid}){
					$c->appendChild($plugin->{session}->render_data_element(12,$prefix.":nameIdentifier",  $contributor->{orcid}, nameIdentifierScheme => "ORCID", schemeURI=>"http://www.orcid.org"));
				}
	
			}
		}

#		$oai_datacite->appendChild( $plugin->{session}->render_data_element( 8, $prefix.":Date", $eprint->value("datestamp"), dateType =>  "Submitted" ) );	
		#Not sure we can do this because dateType is controlled.
#		if($eprint->is_set("date")){
#			$oai_datacite->appendChild( $plugin->{session}->render_data_element( 8, $prefix.":Date", $eprint->value("date"), dateType =>  $eprint->value("date_type") ) );
#		}

		if($eprint->value("type") eq "collection"){ #condition unlikely to be met here
			$oai_datacite->appendChild( $plugin->{session}->render_data_element( 8, $prefix.":resourceTypeGeneral", "Collection" ) );
		}
		if($eprint->value("type") eq "data_collection"){ 
			$oai_datacite->appendChild( $plugin->{session}->render_data_element( 8, $prefix.":resourceTypeGeneral", "Dataset" ) );
			#scrap that.... it would appear to be not repeatable (so which to choose??)
#			for my $content(keys %$contents){
#				$oai_datacite->appendChild( $plugin->{session}->render_data_element( 8, $prefix.":resourceType", "Dataset/".$content ) );
#			}
		}

		#Related identifiers
		if($eprint->is_set("relation")){
			my $ris = $repo->make_element($prefix.":relatedIdentifiers");	
			$oai_datacite->appendChild($ris);
			for my $relation(@{$eprint->value("relation")}){
				$relation->{type} =~ /\/([^\/]+)$/;
				$ris->appendChild( $plugin->{session}->render_data_element( 8, $prefix.":relatedIdentifier", $repo->config("base_url").$relation->{uri}, relatedIdentifierType => "URL", relationType => $1 ) );
			}
		}

		#Descriptions
		my $ds = $repo->make_element($prefix.":descriptions");	
		$oai_datacite->appendChild($ds);
		if($eprint->is_set("abstract")){
				$ds->appendChild( $plugin->{session}->render_data_element( 8, $prefix.":description", $eprint->value("abstract"), descriptionType => "Abstract" ) );
		}
		if($eprint->is_set("collection_method")){
				$ds->appendChild( $plugin->{session}->render_data_element( 8, $prefix.":description", $eprint->value("collection_method"), descriptionType => "Methods" ) );
		}
		if($eprint->is_set("language")){
			$oai_datacite->appendChild( $plugin->{session}->render_data_element( 8, $prefix.":language", $eprint->value("language")->[0] ) );
		}
		#RightsList
		my $rl = $repo->make_element($prefix.":rightsList");	
		$oai_datacite->appendChild($rl);
		for my $right(keys %$licenses){
			$rl->appendChild( $plugin->{session}->render_data_element( 8, $prefix.":rights", $right, rightsURI => $licenses->{$right}));
		}

		return $oai_datacite;
	
#	}else{
#		return undef;
#	}
	# turn the list of pairs into XML blocks (indented by 8) and add them
	# them to the ETD element.
#	foreach( @etdData )
#	{
#		$plugin->{repository}->log("have etdData...");
#		if(scalar $_ < 4){
#			$oai_datacite->appendChild( $plugin->{session}->render_data_element( 8, $_->[2].":".$_->[0], $_->[1] ) );
#		}else{
#		# there's an attribute to add
#			$oai_datacite->appendChild( $plugin->{session}->render_data_element( 8, $_->[2].":".$_->[0], $_->[1], $_->[3]=> $_->[4]  ) );
#			
#		}
#	}

}

##############################################################################
#
# Steve Carr
# subroutine to create a suitable array of array refs to the two item arrays
# as per routine directly above for dublin core (dc). The only difference is that
# qualified dublin core will have additional namespaces and more elements from
# the eprint can be utilised. So we return a longer, three element array per
# array ref. This may need rethinking when we get to attributes (e.g. xsi:type="URI")
#
#
##############################################################################

sub eprint_to_oai_datacite
{
	my( $plugin, $eprint ) = @_;

	my $session = $plugin->{session};

	my @etddata = ();
	# we still want much the same dc data so include under the dc namespace
	# by putting the namespace last this won't break the simple dc rendering routine
	# above. Skip all records that aren't theses because oai_datacite is nonsensical for
	# non-thesis items.
	
	if($eprint->is_set( "id_number")){
		$plugin->{repository}->log("Here with ".$eprint->get_value("id_number"));		
		push @etddata, [ "identifier", $eprint->get_value("id_number"), "oai_datacite", "IdentiferType", "DOI" ];
=comment
		my $creators = $eprint->get_value( "creators_name" );
		if( defined $creators )
		{
			foreach my $creator ( @{$creators} )
			{
				push @etddata, [ "creator", EPrints::Utils::make_name_string( $creator ), "dc" ];
			}
		}

		push @etddata, [ "title", $eprint->get_value( "title" ), "dc" ]; 
		
		if( $eprint->is_set( "date" ) )
		{
			push @etddata, [ "date", $eprint->get_value( "date" ), "dc" ];
		}

		# grab the creators without the ID parts so if the site admin
		# sets or unsets creators to having and ID part it will make
		# no difference to this bit.
	
	
		my $subjectid;
		foreach $subjectid ( @{$eprint->get_value( "subjects" )} )
		{
			my $subject = EPrints::DataObj::Subject->new( $session, $subjectid );
			# avoid problems with bad subjects
			next unless( defined $subject ); 
			push @etddata, [ "subject", EPrints::Utils::tree_to_utf8( $subject->render_description() ), "dc" ];
		}
	
		# Steve Carr : we're using qdc, namespace dcterms, version of description - 'abstract'
		push @etddata, [ "abstract", $eprint->get_value( "abstract" ), "dcterms" ]; 
		
		# Steve Carr : theses aren't technically 'published' so we can't assume a publisher here as in original code
		if(defined $eprint->get_value( "publisher" )){
			push @etddata, [ "commercial", $eprint->get_value( "publisher" ), "uketdterms" ]; 
		}
	
		my $editors = $eprint->get_value( "editors_name" );
		if( defined $editors )
		{
			foreach my $editor ( @{$editors} )
			{
				push @etddata, [ "contributor", EPrints::Utils::make_name_string( $editor ), "dc" ];
			}
		}

		## Date for discovery. For a month/day we don't have, assume 01.
		my $date = $eprint->get_value( "date" );
		if( defined $date )
		{
	        	$date =~ m/^(\d\d\d\d)(-\d\d)?/;
			my $issued = $1;
			if( defined $2 ) { $issued .= $2; }
			push @etddata, [ "issued", $issued, "dcterms" ];
		}
	
	
		my $ds = $eprint->get_dataset();
		push @etddata, [ "type", $session->get_type_name( "eprint", $eprint->get_value( "type" ) ), "dc" ];
		
		# The URL of the abstract page is the dcterms isreferencedby
		push @etddata, [ "isReferencedBy", $eprint->get_url(), "dcterms" ];
	
	
		my @documents = $eprint->get_all_documents();
		my $mimetypes = $session->config( "oai", "mime_types" );
		foreach( @documents )
		{
			my $format = $mimetypes->{$_->get_value("format")};
			$format = $_->get_value("format") unless defined $format;
			#$format = "application/octet-stream" unless defined $format;
			
					push @etddata, [ "format", $format, "dc" ];
			# information about extent and checksums could be added here, if they are available
			# the default eprint doesn't have a place for this but both could be generated dynamically
		}
	
		# Steve Carr : we're using isreferencedby for the official url splash page
		if( $eprint->exists_and_set( "official_url" ) )
		{
			push @etddata, [ "isReferencedBy", $eprint->get_value( "official_url" ), "dcterms", "dcterms:URI"];
		}
			
		if( $eprint->exists_and_set( "thesis_name" )){
			push @etddata, [ "qualificationname", $eprint->get_value( "thesis_name" ), "uketdterms"];
		}
		if( $eprint->exists_and_set( "thesis_type")){
			push @etddata, [ "qualificationlevel", $eprint->get_value( "thesis_type" ), "uketdterms"];
		}
		if( $eprint->exists_and_set( "institution" )){
			push @etddata, [ "institution", $eprint->get_value( "institution" ), "uketdterms"];
		}
		if( $eprint->exists_and_set( "department" )){
			push @etddata, [ "department", $eprint->get_value( "department" ), "uketdterms"];
		}
		if( $eprint->exists_and_set( "advisor" )){
			push @etddata, [ "advisor", $eprint->get_value( "advisor" ), "uketdterms"];
		}
		if( $eprint->exists_and_set( "language" )){
			push @etddata, [ "language", $eprint->get_value( "language" ), "dc"];
		}
		if( $eprint->exists_and_set( "sponsors" )){
			push @etddata, [ "sponsor", $eprint->get_value( "sponsors" ), "uketdterms"];
		}
		if( $eprint->exists_and_set( "alt_title" )){
			push @etddata, [ "alternative", $eprint->get_value("alt_title" ), "dcterms"];
		}
		if( $eprint->exists_and_set( "checksum" )){
			push @etddata, [ "checksum", $eprint->get_value("checksum"), "uketdterms" ];
		}
		if( $eprint->exists_and_set( "date_embargo" )){
			push @etddata, ["date_embargo", $eprint->get_value("date_embargo"), "uketdterms"];
		}
		if( $eprint->exists_and_set( "embargo_reason" )){
			push @etddata, ["embargo_reason", $eprint->get_value("embargo_reason"), "uketdterms"];
		}
		if( $eprint->exists_and_set( "rights" )){
			push @etddata, ["rights", $eprint->get_value("rights"), "dc"];
		}
		if( $eprint->exists_and_set( "citations" )){
			push @etddata, ["hasVersion", $eprint->get_value("citations"), "dcterms"];
		}
		if( $eprint->exists_and_set( "referencetext" )){
			push @etddata, ["references", $eprint->get_value("referencetext"), "dcterms"];
		}
		
=cut		
	
		# dc.source TO DO
		# dc.coverage TO DO
		
	}
	$plugin->{repository}->log("returning data with ".scalar(@etddata)." in it");	
	return @etddata;
}
	
1;


=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2000-2011 University of Southampton.

=for COPYRIGHT END

=for LICENSE BEGIN

This file is part of EPrints L<http://www.eprints.org/>.

EPrints is free software: you can redistribute it and/or modify it
under the terms of the GNU Lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

EPrints is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
License for more details.

You should have received a copy of the GNU Lesser General Public
License along with EPrints.  If not, see L<http://www.gnu.org/licenses/>.

=for LICENSE END

