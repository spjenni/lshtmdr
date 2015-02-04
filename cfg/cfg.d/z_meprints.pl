######################################################################
#
#  MePrints configuration - v1.4.3
#
#  All About MEPrints is a JISC rapid innovations project to build a
#  user profile system for EPrints. The extension we have developed is
#  called MePrints. This configuration file lets you control how the
#  MePrints extension works in your repository.
#
# For an overview of MePrints, see:
# http://wiki.eprints.org/w/MePrintsOverview 
#
# For technical instructions, including troubleshooting, see:
# http://wiki.eprints.org/w/MePrintsInstall
#
######################################################################


# Useful variable for devs
$c->{meprints_enabled} = 1;

# Fixes position of the Login link to be always first:
$c->{plugins}->{"Screen::Login"}->{appears}->{key_tools} = 1;

# Maps the default EPrints' Profile page to MePrints'
$c->{plugins}->{"Screen::User::View"}->{appears}->{key_tools} = undef;
$c->{plugin_alias_map}->{"Screen::User::View"} = "Screen::User::Homepage";

# Use MePrints' homepage as first screen after logging in
$c->{plugins}->{"Screen::FirstTool"}->{params}->{default} = "User::Homepage";

# Allow repo.ac.uk/profile/XYZ urls
#$c->{rewrite_exceptions} = [] unless( defined $c->{rewrite_exceptions} );
#push( @{$c->{rewrite_exceptions}}, "/profile/" );

# Set to "1" to use username eg repository.ac.uk/profile/sf2 instead of userid repository.ac.uk/profile/1234
$c->{meprints_profile_with_username} = 0;

# Widget layout for all public profile pages.
# This layout can only be changed here.
# The special __SEPARATOR__ token indicates where the 
# widgets should be split across columns (note: only
# 2 column layout possible)
$c->{user_profile_defaults} = [
	'LatestEPrints',
	'__SEPARATOR__',
	'TopTen',
];

# use value "public" or "private"
$c->{default_profile_behavior} = "private";

# default: uses the user's name as the title of the page
$c->{meprints}->{profile}->{use_name_as_title} = 1;

# Default widget layout for user homepages.
# Users can customise their widget layout by adding,
# removing and moving widgets (the individual user
# layout is stored in the homepage_preferences field
# defined below).
# The special __SEPARATOR__ token indicates where the 
# widgets should be split across columns (note: only
# 2 column layout possible)
$c->{user_homepage_defaults} = [
	'QuickUpload',
	'LatestEPrints',
	'__SEPARATOR__',
	'TopTen',
	'EPrintsIssues'
];

$c->{irstats_widget}= {
	view_name => "MonthlyDownloadsGraph",
	period=> "-6m",
	chart_width => '325',
	irstats_url=>$c->{base_url}.'/irstats/graphs/'
};

# default sizes for user profile pictures
$c->{plugins}{"Screen::User::UploadPicture"}{params}{sizes} = {
	preview => "120x160", 
	small => "30x40",
};

# Add user profile search. This will only search public
# user profiles.
$c->{datasets}->{user}->{search}->{user_public} = 
{
        search_fields => [
                { meta_fields => [ "name" ] },
                { meta_fields => [ "username" ] },
                { meta_fields => [ "expertise" ] },
                { meta_fields => [ "qualifications" ] },
                { meta_fields => [ "dept" ] },
                { meta_fields => [ "org" ] },
	],

        citation => "default",
        page_size => 20,
        order_methods => {
                "byname"         =>  "name/joined",
                "byjoin"         =>  "joined/name",
                "byrevjoin"      =>  "-joined/name",
                "bytype"         =>  "usertype/name",
        },
        default_order => "byname",
        show_zero_results => 1,
};


# Public User Search disabled by default
#
#push @{$c->{plugins}->{"Search::Internal"}->{params}->{search}}, 'user_public/user';

# If you don't want everyone to search for users on your system, simply comment out the line below
# Alternatively, you may allow users/editors/admins to search for users, in which case you need to adjust the user_roles to your liking.
#push @{$c->{public_roles}}, "+user/search";



# User browse pages (disabled by default)
#
# "Browse by expertise"
#@{$c->{browse_views}} = (@{$c->{browse_views}}, (
#
#        {
#                id => "user_expertise",
#		dataset => "public_profile_users",
#                menus => [
#                        {
#                                fields => [ "expertise" ],
#				hideempty => 1,
#                                reverse_order => 1,
#                                allow_null => 0,
#                                new_column_at => [10,10],
#                        }
#                ],
#                order => "name",
#                variations => [	"DEFAULT", "dept" ],
#        }
#));

# "Browse by department"
#@{$c->{browse_views}} = (@{$c->{browse_views}}, (
#        {
#                id => "user_dept",
#		dataset => "public_profile_users",
#                menus => [
#                        {
#                                fields => [ "dept" ],
#				hideempty => 1,
#                                reverse_order => 1,
#                                allow_null => 0,
#                                new_column_at => [10,10],
#                        }
#                ],
#                order => "name",
#        },
#));



# Add extra metadata fields for user profiles
@{ $c->{fields}->{user} } = ( @{ $c->{fields}->{user} }, (
	{
	    	'name' => 'homepage_preferences',
		'type' => 'text',
		'multiple' => 1,
	    	'show_in_html' => 0,
	},
	{
		'name' => 'jobtitle',
		'type' => 'text',
	},
	{
		'name' => 'expertise',
		'type' => 'text',
		'multiple' => 1,
		'input_cols' => 30,
		'input_boxes' => 6,
# sf2 - if you use the user_expertise browse view, you may want to enable this for automatic linking of expertise to the relevant browse view page:
#		'browse_link' => 'user_expertise',
	},
	{
		'name' => 'biography',
		'type' => 'longtext',
		'render_value' => 'EPrints::MePrints::render_first_n_chars',
	},
	{
		'name' => 'qualifications',
		'type' => 'longtext',
		'render_value' => 'EPrints::MePrints::render_first_n_chars',
	},
	{
		'name' => 'real_profile_visibility',
		'type' => 'set',
		'options' => [
			   'public',
			   'private'
			 ],
		'input_style' => 'radio',
	},
	{
		'name' => 'user_profile_visibility',
		'type' => 'set',
		'options' => [
			   'public',
			   'private'
			 ],
		'input_style' => 'radio',
	},
));

# Add virtual dataset of users who have opted to have their
# profile page publically viewable. This is used by the 
# user profile search and browse views.
$c->{datasets}->{public_profile_users} = {
        name => "public_profile_users",
        virtual => 1,
        class => "EPrints::DataObj::User",
        confid => "user",
        sqlname => "user",
        index => 1,
        filters => [{
                meta_fields => ['real_profile_visibility'],
                value => 'public',
                describe => 0
        }],
        dataset_id_field => 'real_profile_visibility'
};

# Handler to server (external) profile pages
$c->add_trigger( EP_TRIGGER_URL_REWRITE, sub
{
        my( %args ) = @_;

	my( $uri, $rc, $request ) = @args{ qw( uri return_code request ) };
        
	if( defined $uri && ($uri =~ m#^/profile/(.*)$# ) )	#
	{
                $request->handler('perl-script');
                $request->set_handlers(PerlResponseHandler => [ 'EPrints::Plugin::MePrints::MePrintsHandler' ] );
		${$rc} = EPrints::Const::OK;
	}

        return EP_TRIGGER_OK;

}, priority => 100 );

# Handler to regenerate the user's profile page when their metadata is updated
$c->add_dataset_trigger( "user", EPrints::Const::EP_TRIGGER_AFTER_COMMIT, sub { 
        my( %params ) = @_; 

        my $repo = $params{repository}; 
        my $user = $params{dataobj}; 
        my $changed = $params{changed}; 

        if( scalar( keys %{$changed||{}} ) ) 
        { 
                $user->remove_static(); 
        } 
} ); 

# update the profile visibility
$c->add_dataset_trigger( "user", EPrints::Const::EP_TRIGGER_BEFORE_COMMIT, sub { 
        my( %params ) = @_; 

        my $repo = $params{repository}; 
        my $user = $params{dataobj}; 
        
	my $profile_visibility = $repo->config( "default_profile_behavior" );

	if( $user->is_set( "user_profile_visibility" ) )
	{
		$profile_visibility = $user->value( "user_profile_visibility" );
	}

	$user->set_value( "real_profile_visibility", $profile_visibility );

} ); 

# delete profile page if user account is removed
$c->add_dataset_trigger( "user", EPrints::Const::EP_TRIGGER_REMOVED, sub { 
        my( %params ) = @_; 

	$params{dataobj}->remove_static(); 

} );

{

package EPrints::MePrints;

my $DEFAULT_N_CHARS = 800;

sub render_first_n_chars
{
        my( $session , $field , $value, $alllangs, $nolink, $object ) = @_;
	
	my $chunk = $session->make_doc_fragment;
	return $chunk unless( EPrints::Utils::is_set( $value ) );

	my $id = "meprints_render_".$field->get_name;
	my $div = $session->make_element( "div", id => $id, class => "meprints_short_rendering" );
	$chunk->appendChild( $div );

	if( length( $value ) <= $DEFAULT_N_CHARS )
	{
		$div->appendChild( $session->make_text( $value ) );
	}
	else
	{
		my $first_n = substr( $value, 0, $DEFAULT_N_CHARS );
		$div->appendChild( $session->make_text( $first_n ) );

		my $link = $session->make_element( "a", 
				href => "#",
				onclick => "\$('$id').style.display = 'none';\$('$id"."_all"."').style.display = 'block';return false;",
				class => "meprints_link_more" );
		
		$link->appendChild( $session->html_phrase( "meprints:link:more" ) );
		$div->appendChild( $link );

		my $long_div = $session->make_element( "div", id => $id."_all", style => "display:none;" );
		$chunk->appendChild( $long_div );
		$long_div->appendChild( $session->make_text( $value ) );
	}

	return $chunk;
}

}

# Bazaar Configuration
$c->{plugins}{"MePrints"}{params}{disable} = 0;
$c->{plugins}{"MePrints::Layout"}{params}{disable} = 0;
$c->{plugins}{"MePrints::Layout:Embed"}{params}{disable} = 0;
$c->{plugins}{"MePrints::Layout::TwoColumn"}{params}{disable} = 0;
$c->{plugins}{"MePrints::MePrintsHandler"}{params}{disable} = 0;
$c->{plugins}{"MePrints::Render::Box"}{params}{disable} = 0;
$c->{plugins}{"MePrints::Render::Simple"}{params}{disable} = 0;
$c->{plugins}{"MePrints::Widget"}{params}{disable} = 0;
$c->{plugins}{"MePrints::Widget::AlignedThumbnail"}{params}{disable} = 0;
$c->{plugins}{"MePrints::Widget::Details"}{params}{disable} = 0;
$c->{plugins}{"MePrints::Widget::EPrintsIssues"}{params}{disable} = 0;
$c->{plugins}{"MePrints::Widget::IRStats::DownloadGraph"}{params}{disable} = 0;
$c->{plugins}{"MePrints::Widget::LatestEPrints"}{params}{disable} = 0;
$c->{plugins}{"MePrints::Widget::LatestInbox"}{params}{disable} = 0;
$c->{plugins}{"MePrints::Widget::QuickLinks"}{params}{disable} = 0;
$c->{plugins}{"MePrints::Widget::QuickUpload"}{params}{disable} = 0;
$c->{plugins}{"MePrints::Widget::Thumbnail"}{params}{disable} = 0;
$c->{plugins}{"MePrints::Widget::TopTen"}{params}{disable} = 0;
$c->{plugins}{"Screen::User::EditLink"}{params}{disable} = 0;
$c->{plugins}{"Screen::User::Homepage"}{params}{disable} = 0;
$c->{plugins}{"Screen::User::UploadPicture"}{params}{disable} = 0;
$c->{plugins}{"Screen::EPMC::MePrints"}{params}{disable} = 0;
$c->{plugins}{"Screen::Admin::RegenMePrints"}{params}{disable} = 0;

