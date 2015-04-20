=pod

# Please see http://wiki.eprints.org/w/User_login.pl
$c->{check_user_password} = sub {
	my( $repo, $username, $password ) = @_;

	... check whether $password is ok

	return $ok ? $username : undef;
};
=cut


$c->{check_user_password} = sub {

	my( $repo, $username, $password ) = @_;
	
#	print STDERR "User $username is attempting to login\n";


	# LDAP tunables
	my $ldap_host = "authldap.lshtm.ac.uk";
	my $dn = "cn=ulcceprintsproxy,ou=proxyusers,ou=resources,o=lshtm";

	use Net::LDAPS;

	#$ldap_host = "auth2.lshtm.ac.uk";
	my $ldap = Net::LDAPS->new($ldap_host,
                          port => '636',
                          verify => 'none');
	unless( $ldap )
	{
		print STDERR "LDAP error: $@\n";
		print STDERR "LDAP broke!! going native (any users)...\n";
	  my $user = $repo->user_by_username( $username );
		if(defined $user){
			return $repo->database->valid_login( $username, $password );
		}
		return 0;
	}
#	print STDERR "Have an LDAP connection\n";

 	# Get password for the search-bind-account
# 	my $id = $repo->get_id;
# 	my $dir = $id;
 #	$dir =~ s/test/-test/;
 #	my $ldappass = `cat /www/$dir/eprints3/archives/$id/cfg/ldap.passwd`;
	my $ldappass = `cat $c->{ldap_pw_location}`;
 	chomp($ldappass);

 	my $mesg = $ldap->bind( $dn, password=>$ldappass );
 	if( $mesg->code() ){
		print STDERR "LDAP Bind error: " . $mesg->error() . "\n";
 		return 0;
	}
#	print STDERR "LDAP bound using $dn\n";

	# Distinguished name (and attributes needed later on) for this user
	my $result = $ldap->search (
	       base    => "o=lshtm",
	       scope   => "sub",
	       filter  => "cn=$username",
	       attrs   =>  ['1.1', 'uid', 'sn', 'givenname', 'mail', 'LSHTMPayrollNo', 'eduPersonScopedAffiliation', 'LSHTMeDirCtx', 'cn'],
	       sizelimit=>1
	);

	my $entr = $result->pop_entry;

#	print STDERR "LDAP entry: $entr\n";

	if(!defined $entr ){
		print STDERR "No entry found for $username going native (admin and exceptions only)...\n";
	  my $user = $repo->user_by_username( $username );
		if(defined $user && ($user->get_type eq "admin" || $username eq "bmc" || $username eq "ulcceditor" || $username eq "ulcctest2")){
#        print STDERR "Exceptions met\n";
			return $repo->database->valid_login( $username, $password );
		}
		return 0;
	}
	
	my $ldap_dn = $entr->dn;

	# Check password
#	print STDERR "LDAP attempt: *$ldap_dn*, password => *$password* \n";

	my $messg = $ldap->bind( $ldap_dn, password => $password );
	if( $messg->code() ){
		print STDERR "LDAP password fail: " . $messg->code() . "\n";
		return 0;
	}

	# Does account already exist?
	my $user = $repo->user_by_username( $username );
	if( !defined $user ){
		# New account
		my $userdata = {
    		usertype => "user",
    		username => $username,
    	};
    	$user = $repo->dataset( "user" )->create_dataobj( $userdata );
	}

	# Set metadata
	my $name = {};
	$name->{family} = $entr->get_value( "sn" );
	$name->{given} = $entr->get_value( "givenName" );
	$user->set_value( "name", $name );
	$user->set_value( "username", $username );
	$user->set_value( "email", $entr->get_value( "mail" ) );
    $repo->log("Setting lshtmid with ".$entr->get_value("cn"));
	$repo->log("Setting lshtmid with ".Digest::MD5::md5_hex( $entr->get_value( "cn" ) ) );
	$user->set_value( "lshtmid", Digest::MD5::md5_hex( $entr->get_value( "cn" ) ) );
	$user->set_value( "dept", $entr->get_value( "LSHTMeDirCtx" ) );
	$user->commit();

	$ldap->unbind if $ldap;

	return $username;	

}

# Maximum time (in seconds) before a user must log in again
# $c->{user_session_timeout} = undef; 

# Time (in seconds) to allow between user actions before logging them out
# $c->{user_inactivity_timeout} = 86400 * 7;

# Set the cookie expiry time
# $c->{user_cookie_timeout} = undef; # e.g. "+3d" for 3 days
