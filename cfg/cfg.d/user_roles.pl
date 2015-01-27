
######################################################################
#
# User Roles
#
#  Here you can configure which different types of user are 
#  parts of the system they are allowed to use.
#
######################################################################

if (  (defined $c->{repository_frozen} && $c->{repository_frozen})
   || (defined $c->{repository_deep_frozen} && $c->{repository_deep_frozen}) ) {

  $c->{user_roles}->{user} = [qw{
  	general
  }];
  
  $c->{user_roles}->{editor} = [qw{
  	general
  	view-status
  	staff-view
  }];
  
  $c->{user_roles}->{minuser} = [qw{
  	general
  	lock-username-to-email
  }];
}
else {
  $c->{user_roles}->{user} = [qw{
  	general
  	edit-own-record
  	saved-searches
  	set-password
  	deposit
  	change-email
  }];
  
  $c->{user_roles}->{editor} = [qw{
  	general
  	edit-own-record
  	saved-searches
  	set-password
  	deposit
  	change-email
  	editor
  	view-status
  	staff-view
  }];
  
  $c->{user_roles}->{minuser} = [qw{
  	general
  	edit-own-record
  	saved-searches
  	set-password
  	lock-username-to-email
  }];
}

if ( defined $c->{repository_deep_frozen} && $c->{repository_deep_frozen} ) {
  $c->{user_roles}->{admin} = [qw{
  	general
  	view-status
  	staff-view
  }];
}
else {
  $c->{user_roles}->{admin} = [qw{
  	general
  	edit-own-record
  	saved-searches
  	set-password
  	deposit
  	change-email
  	editor
  	view-status
  	staff-view
  	admin
  	edit-config
  }];
}

# Note -- nobody has the very powerful "toolbox" or "rest" roles, by default!

# Use this to set public privilages. 
$c->{public_roles} = [qw{
	+eprint/archive/rest/get
	+subject/rest/get
}];

# If you want to add additional roles to the system, you can do it here.
# These can be useful to create "hats" which can be given to a user via
# the roles field. You can also override the default roles.
#
#$c->{roles}->{"approve-hat"} = [
#	"eprint/buffer/view:editor",
#	"eprint/buffer/summary:editor",
#	"eprint/buffer/details:editor",
#	"eprint/buffer/move_archive:editor",
#];


