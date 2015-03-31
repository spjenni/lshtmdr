$c->{set_eprint_defaults} = sub
{
	my( $data, $repository ) = @_;

	$data->{type} = "article";

	#LSHTMDR set defaults here

	#Generic

	my $user = $repository->current_user;
        if( defined $user )
        {
	    #display initials, but don't store initials....
	    #my $initials = $user->get_value( 'name' )->{given};
	    #   $initials =~ s/^(\w)[^\s]*(|\s+(\w)[^\s]*(|\s+(\w)[^\s]*))$/$1$3$5/; #no more than 3 initials...
	
		#pre-load creators data with current user data (this would be annoying unless self-archiving)
		if($user->is_set("name")){

			$data->{creators} =  [ {
				name => {
					given => $user->get_value( 'name' )->{given}, 
					family => $user->get_value( 'name' )->{family}, 
					honourific => $user->get_value( 'name' )->{honourific},
					lineage => $user->get_value( 'name' )->{lineage}
				},
				id => $user->get_value( 'email' ),
				lshtmid => $user->get_value( 'lshtmid' ),
				orcid => $user->get_value( 'orcid' )
			} ];
		}	
		#set the lshtm_flag if lshtmid is present
        	$data->{creators}->[0]->{lshtm_flag} = "TRUE" if(defined $data->{creators}->[0]->{lshtmid});
		#to encourage contactability we load in the users email to the contact_email...
        	$data->{contact_email}  = $user->get_value( 'email' );
        }
	#This lot can some default values set by phrases for ease of editing.
	$data->{corp_creators} = [$repository->phrase("default_corp_creators_value")];
	$data->{publisher} = $repository->phrase("default_publisher_value");
	$data->{place_of_pub} = $repository->phrase("default_place_of_pub_value");
	$data->{copyright_holders} = [$repository->phrase("default_copyright_holders_value")];
	$data->{language} = [{ l => $repository->phrase("default_language_value")}];

};

