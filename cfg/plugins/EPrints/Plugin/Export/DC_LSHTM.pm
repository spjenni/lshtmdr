=head1 NAME

EPrints::Plugin::Export::DC_LSHTM

=cut

package EPrints::Plugin::Export::DC_LSHTM;

# eprint needs magic documents field

# documents needs magic files field

#use EPrints::Plugin::Export::TextFile;

@ISA = ( "EPrints::Plugin::Export::DC" );
use Data::Dumper;
use strict;

sub new
{
        my( $class, %params ) = @_;

        my $self = $class->SUPER::new( %params );

        $self->{name} = "Dublin Core (with Type as Type)";

        return $self;
}

sub convert_dataobj
{
        my( $plugin, $eprint ) = @_;

        my $dataset = $eprint->{dataset};

        my @dcdata = ();

        # The URL of the abstract page
        if( $eprint->is_set( "eprintid" ) )
        {
                push @dcdata, [ "relation", $eprint->get_url() ];
        }

        push @dcdata, $plugin->simple_value( $eprint, title => "title" );

        # grab the creators without the ID parts so if the site admin
        # sets or unsets creators to having and ID part it will make
        # no difference to this bit.

        if( $eprint->exists_and_set( "creators_name" ) )
        {
                my $creators = $eprint->get_value( "creators_name" );
                if( defined $creators )
                {
                        foreach my $creator ( @{$creators} )
                        {
                                next if !defined $creator;
                                push @dcdata, [ "creator", EPrints::Utils::make_name_string( $creator ) ];
                        }
                }
        }

    if( $eprint->exists_and_set( "subjects" ) )
        {
                my $subjectid;
                foreach $subjectid ( @{$eprint->get_value( "subjects" )} )
                {
                        my $subject = EPrints::DataObj::Subject->new( $plugin->{session}, $subjectid );
                        # avoid problems with bad subjects
                                next unless( defined $subject );
                        push @dcdata, [ "subject", EPrints::Utils::tree_to_utf8( $subject->render_description() ) ];
                }
        }

	if( $eprint->exists_and_set( "corp_creators" ) )
        {
                my $corp_creators = $eprint->get_value( "corp_creators" );
                if( defined $corp_creators )
                {
                        foreach my $corp_creator ( @{$corp_creators} )
                        {       
                                next if !defined $corp_creator;
                                push @dcdata, [ "creator", $corp_creator  ];
                        }
                }
        }


        push @dcdata, $plugin->simple_value( $eprint, abstract => "description" );
        push @dcdata, $plugin->simple_value( $eprint, publisher => "publisher" );

        if( $eprint->exists_and_set( "editors_name" ) )
        {
                my $editors = $eprint->get_value( "editors_name" );
                if( defined $editors )
                {
                        foreach my $editor ( @{$editors} )
                        {
                                push @dcdata, [ "contributor", EPrints::Utils::make_name_string( $editor ) ];
                        }
                }
        }

        ## Date for discovery. For a month/day we don't have, assume 01.
        if( $eprint->exists_and_set( "date" ) )
        {
                my $date = $eprint->get_value( "date" );
                if( defined $date )
                {
                        $date =~ s/(-0+)+$//;
                        push @dcdata, [ "date", $date ];
                }
        }
		#RM I have used typ for type instrad of peerReviewed/nonPeerReviewed
		if( $eprint->exists_and_set( "type" ) )
        {
                push @dcdata, [ "type", EPrints::Utils::tree_to_utf8( $eprint->render_value( "type" ) ) ];
        }

		
        my @documents = $eprint->get_all_documents();
        my $mimetypes = $plugin->{session}->get_repository->get_conf( "oai", "mime_types" );
        
        foreach( @documents )
        {
				# SJ: set the correct language phrase
				my $doc_lang = $plugin->{session}->get_repository->html_phrase ("languages_typename_".$_->value("language") );
        
                my $format = $mimetypes->{$_->get_value("format")};
                #SJ: mime_type pushed instead of format
                $format = $_->get_value("mime_type") unless defined $format;
                $format = "application/octet-stream" unless defined $format;
                push @dcdata, [ "format", $format ];
                push @dcdata, [ "language", $doc_lang ] if $_->exists_and_set("language");
                push @dcdata, [ "rights", EPrints::XML::to_string($_->render_value("license")) ] if $_->exists_and_set("language");
                push @dcdata, [ "identifier", $_->get_url() ];
        }

        # The citation for this eprint
        push @dcdata, [ "identifier",
                EPrints::Utils::tree_to_utf8( $eprint->render_citation() ) ];

        # Most commonly a DOI or journal link
        push @dcdata, $plugin->simple_value( $eprint, official_url => "relation" );

        # Probably a DOI
        push @dcdata, $plugin->simple_value( $eprint, id_number => "relation" );

        # If no documents, may still have an eprint-level language
        # SJ: change to language_l to remove incorrect hash call
        my @lang_ph = $plugin->simple_value( $eprint, language_l => "language" );
		#SJ: get the correct language phrase for OAI output
		my $xml = $plugin->{session}->get_repository->xml;
		foreach my $i (0..$#lang_ph) 
		{
			foreach my $j (0..$#{$lang_ph[$i]}) 
			{  	
				if($j)
				{	
					$lang_ph[$i][$j] = $xml->to_string($plugin->{session}->get_repository->html_phrase("languages_typename_".$lang_ph[$i][$j]));
				}
			}
		}
        
        push @dcdata, @lang_ph;
     	# dc.source not handled yet.
        # dc.coverage not handled yet.

        return \@dcdata;
}

