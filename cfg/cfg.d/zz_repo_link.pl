#Repository Link
#EPrints Plugin to dynamically link items in different EPrints repositories
#Rory McNicholl, ULCC, 2015

#Repository link configuration file

# How?

# The Repository link plugin will allow depositors to search other enabled 
# repositoies from the workflow and save links in the master repository to 
# associated items in other repositories. Those other enabled repositories
# (satellite repositories) will be able to check the master repository and
# display reciprocal links to the master repository thus closing the loop
# of association

# The plugin/package is designed to be installed on both the master and
# satellite repositories though it will work differently on each. 

######################################################################################
# To this end, you should set the master parameter below to 1 only on one repository #
######################################################################################

# So far only used with a single satellite, however with some work on the 
# response handling in /users/lookup/repo_links this could potentially be deployed on 
# multiple satellite repositories

	

$c->{repo_link} = {
		#Is this master (or local) repository or a satellite (or remote) repository?
		#The master repo will store the repository links
		#The metadata structure of the satellite repository will be unchanged
		master => 1, 		

		#Once this config file file is loaded on the master repository
		#You will need to update the database structure.. (or can I do that?)

		#Minimum characters to trigger the lookup of satellite repository from workflow
		min_chars => 5,
		
		#The hostname that will be used to contact master from satellite 
		master_repo_host => 'w01.lshtmdrtest.da.ulcc.ac.uk',
		#The port that will be used to contact the master from satellite
		#master_repo_port => 8081,
		#The auto-complete script used to contact the satellite repositories from the workflow
		#NB This and the workflow paste below could be potentially replaced by a direct ajax 
		#call to a cross-domain enabled search_script on the satellite(s)
		lookup_script => "/users/lookup/repo_link",

		#The config for the satellite repositories (see below)
		remote_repos => [],

};

$c->{repo_link}->{remote_repos} = [	
	{
		repo_uri => 'researchonline.lshtm.ac.uk',
		#repo_port => 8080,
		search_script => "/cgi/lookup/title_search"
	},
];
=comment
###################################################################################################
###### Much as we would love to do this all automatically, we can't so...
###### In the MASTER repository - Add the following to cfg/workflow/eprint/default.xml

<component>
	<field ref="repo_link" input_lookup_url="{$config{rel_cgipath}}{$config{repo_link}{lookup_script}}" input_lookup_params="id={eprintid}"/>
</component>

###### In the SATELLITE repository - Add the following to cfg/citation/eprint/summary_page.xml

<div class="repo_links"></div>

###### Do this in the location you want the reciprocal links to the master repository to appear

###### In BOTH/ALL repositories - Add the following to relevant template/default.xml above <epc:pin ref="head"/>

<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js">// <!-- No script --></script>

or for local jquery:

<script src="/javascript/jquery.min.js">// <!-- No script --></script>


###################################################################################################
=cut

## Not used, see below
#my $jquery_priority = 1000;

if($c->{repo_link}->{master}){

#	$jquery_priority = 2000;

	# Add the repo_link compound field to master
	$c->add_dataset_field(
		"eprint",
		{
			name   => 'repo_link',
			type   => 'compound',
			multiple=> 1,
			fields => [
				{
					sub_name   => 'title',
					type       => 'text',
					input_cols => 60,

				},
				{
					sub_name => 'link',
					type     => 'url',
					input_cols => 40,
				},
			],

		},
		reuse => 1
	);
	# Add search field to master 
	# (required to make the export of the repo_link_link search work... unless there is a less intrusive way)
	push @{$c->{search}->{advanced}->{search_fields}}, {meta_fields=>["repo_link_link"]};

}

#EPrints seems to have issues with inserting things to the head in the right order so until that is sorted leave the below commented out

#TODO : this doesn't work properly because 
	#priority < 1000 inserts before for static, but not for workflow (good for static...except breaks workflow)
	#priority > 1000 inserts before auto for workflow, but after for static (good for master.... except is breaks the summary_page)

=comment
#####Insert jquery lib ahead of auto.js

$c->add_trigger( EP_TRIGGER_DYNAMIC_TEMPLATE, sub {
	my %params = @_;

	my $repo = $params{repository};
	my $pins = $params{pins};
	my $xhtml = $repo->xhtml;

	my $head = $repo->xml->create_document_fragment;

	# Top
	$head->appendChild( $repo->xml->create_element( "script",
#CDN
#			src => "//ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js",
#local
			src => "/javascript/jquery.min.js", #local jquery
		) );
	$head->appendChild( $repo->xml->create_text_node( "\n    " ) );

	if( defined $pins->{'utf-8.head'} )
	{
		$pins->{'utf-8.head'} .= $xhtml->to_xhtml( $head );
	}
	if( defined $pins->{head} )
	{
		$head->appendChild( $pins->{head} );
		$pins->{head} = $head;
	}
	else
	{
		$pins->{head} = $head;
	}

	return;
}, priority => $jquery_priority);

=cut
