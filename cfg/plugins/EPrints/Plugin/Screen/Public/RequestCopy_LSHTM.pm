=head1 NAME

EPrints::Plugin::Screen::Public::RequestCopy_LSHTM

=cut

package EPrints::Plugin::Screen::Public::RequestCopy_LSHTM;

use EPrints::Plugin::Screen::Public::RequestCopy;

@ISA = ( 'EPrints::Plugin::Screen::Public::RequestCopy' );

use strict;

sub new
{
        my( $class, %params ) = @_;

        my $self = $class->SUPER::new(%params);

	 $self->{name} = "Request a copy with requester email.";

        return $self;
}


sub action_request
{
        my( $self ) = @_;

        my $session = $self->{session};

        my $request = $self->{processor}->{dataobj};

        my $rc = $self->workflow->update_from_form( $self->{processor} );
        return if !$rc; # validation failed

        my $email = $request->value( "requester_email" );

        my $eprint = $self->{processor}->{eprint};
        my $doc = $self->{processor}->{document};
        my $contact_email = $self->{processor}->{contact_email};

        my $user = EPrints::DataObj::User::user_with_email( $session, $contact_email );
        if( defined $user )
        {
                $request->set_value( "userid", $user->id );
        }

        $request = $self->{processor}->{dataset}->create_dataobj( $request->get_data );

        my $history_data = {
                datasetid=>"request",
                objectid=>$request->get_id,
                action=>"create",
        };

        if( defined $self->{processor}->{user} )
        {
                $history_data->{userid} = $self->{processor}->{user}->get_id;
        }
        else
        {
                $history_data->{actor} = $email;
        }
     # Log request creation event
        my $history_ds = $session->dataset( "history" );
        $history_ds->create_object( $session, $history_data );

        # Send request email
        my $subject = $session->phrase( "request/request_email:subject", eprint => $eprint->get_value( "title" ) );
        my $mail = $session->make_element( "mail" );
        $mail->appendChild( $session->html_phrase(
                "request/request_email:body",
                eprint => $eprint->render_citation_link_staff,
                document => defined $doc ? $doc->render_value( "main" ) : $session->make_doc_fragment,
                requester => $request->render_citation( "requester", requester_email=>$email ),
                reason => $request->is_set( "reason" ) ? $request->render_value( "reason" )
                        : $session->html_phrase( "Plugin/Screen/EPrint/RequestRemoval:reason" ),
                                 
                # SJ: other form fields added to $mail
                variables_required => $request->is_set( "variables_required" ) ? $request->render_value( "variables_required" )
                        : $session->html_phrase( "Plugin/Screen/EPrint/RequestCopy_LSHTM:variables_required" ),     
         
				supporting_information => $request->is_set( "supporting_information" ) ? $request->render_value( "supporting_information" )
                        : $session->html_phrase( "Plugin/Screen/EPrint/RequestCopy_LSHTM:supporting_information" ),     
   
				organisation => $request->is_set( "organisation" ) ? $request->render_value( "organisation" )
                        : $session->html_phrase( "Plugin/Screen/EPrint/RequestCopy_LSHTM:organisation" )    
                ) );
     
        my $result;
        if( defined $user && defined $doc )
        {
                # Contact is registered user and EPrints holds requested document
                # Send email to contact with accept/reject links

                my $url = $session->get_url( host => 1, path => "cgi", "users/home" );
                $url->query_form(
                                screen => "Request::Respond",
                                requestid => $request->id,
                        );

                $mail->appendChild( $session->html_phrase( "request/request_email:links",
                        accept => $session->render_link( "$url&action=accept" ),
                        reject => $session->render_link( "$url&action=reject" ) ) );

                $result = EPrints::Email::send_mail(
                        session => $session,
                        langid => $session->get_langid,
                        to_name => EPrints::Utils::tree_to_utf8( $user->render_description ),
                        to_email => $contact_email,
                        subject => $subject,
                        message => $mail,
                        sig => $session->html_phrase( "mail_sig" ),
                        cc_list => EPrints::Utils::is_set( $session->config( "request_copy_cc" ) ) ? $session->config( "request_copy_cc" ) : [],
                );
        }
        else
        {
                # Contact is non-registered user or EPrints holds no documents
                # Send email to contact with 'replyto'
                $result = EPrints::Email::send_mail(
                        session => $session,
                        langid => $session->get_langid,
                        to_name => defined $user ? EPrints::Utils::tree_to_utf8( $user->render_description ) : "",
                        to_email => $contact_email,
                        subject => $subject,
                        message => $mail,
                        sig => $session->html_phrase( "mail_sig" ),
                        replyto_email => $email,
                        cc_list => EPrints::Utils::is_set( $session->config( "request_copy_cc" ) ) ? $session->config( "request_copy_cc" ) : [],
                );
        }

        if( !$result )
        {
                $self->{processor}->add_message( "error", $session->html_phrase( "general:email_failed" ) );
                return;
        }

        # Send acknowledgement to requester
        $mail = $session->make_element( "mail" );
        $mail->appendChild( $session->html_phrase(
                "request/ack_email:body",
                document => defined $doc ? $doc->render_value( "main" ) : $session->make_doc_fragment,
                eprint  => $eprint->render_citation_link ) );

        $result = EPrints::Email::send_mail(
                session => $session,
                langid => $session->get_langid,
                to_email => $email,
                subject => $session->phrase( "request/ack_email:subject", eprint=>$eprint->get_value( "title" ) ),
                message => $mail,
                sig => $session->html_phrase( "mail_sig" )
        );
	
        if( !$result )
        {
                $self->{processor}->add_message( "error", $session->html_phrase( "general:email_failed" ) );
                return;
        }

        $self->{processor}->add_message( "message", $session->html_phrase( "request/ack_page", link => $session->render_link( $eprint->get_url ) ) );
        $self->{processor}->{request_sent} = 1;
}

