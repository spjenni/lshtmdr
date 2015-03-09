=head1 NAME

EPrints::Plugin::InputForm::Surround::Default

=cut

package EPrints::Plugin::InputForm::Surround::Default_lshtm;

use strict;

our @ISA = qw/ EPrints::Plugin /;


sub render_title
{
	my( $self, $component ) = @_;

	my $title = $component->render_title( $self );

	if( $component->is_required )
	{
		$title = $self->{session}->html_phrase( 
			"sys:ep_form_required",
			label=>$title );
	}

	return $title;
}


sub render
{
	my( $self, $component ) = @_;

	my $comp_name = $component->get_name();

	my $surround = $self->{session}->make_element( "div",
		class => "ep_sr_component_lshtm",
		id => $component->{prefix} );

	$surround->appendChild( $self->{session}->make_element( "a", name=>$component->{prefix} ) );
	foreach my $field_id ( $component->get_fields_handled )
	{
		$surround->appendChild( $self->{session}->make_element( "a", name=>$field_id ) );
	}

	my $barid = $component->{prefix}."_titlebar";
	my $title_bar_class="";
	my $content_class="";
	
	if( $component->is_collapsed )
	{
		$title_bar_class = "ep_no_js";
		$content_class = "ep_no_js";
	}
	
	# style for title bar
	my $title_bar = $self->{session}->make_element( "div", class=>"ep_sr_title_bar_lshtm $title_bar_class", id=>$barid );
	my $title_div = $self->{session}->make_element( "div", class=>"ep_sr_title_lshtm" );

	my $content = $self->{session}->make_element( "div", id => $component->{prefix}."_content", class=>"$content_class ep_sr_content_lshtm" );
	my $content_inner = $self->{session}->make_element( "div", id => $component->{prefix}."_content_inner" );
	$surround->appendChild( $title_bar );

	$content->appendChild( $content_inner );

	$title_bar->appendChild( $title_div );

	# Help rendering
	if( $component->has_help && !$component->{no_help} )
	{
		$self->_render_help( $component, $title_bar, $content_inner );
	}

	my $imagesurl = $self->{session}->get_repository->get_conf( "rel_path" );
	$content_inner->appendChild( $component->render_content( $self ) );
	
	if( $component->is_collapsed )
	{
		my $colbarid = $component->{prefix}."_col";
		my $col_div = $self->{session}->make_element( "div", class=>"ep_sr_collapse_bar_lshtm ep_only_js ep_toggle", id => $colbarid );

		my $contentid = $component->{prefix}."_content";
		my $main_id = $component->{prefix};
		my $col_link =  $self->{session}->make_element( "a", class=>"ep_sr_collapse_link", onclick => "EPJS_blur(event); EPJS_toggleSlideScroll('${contentid}',false,'${main_id}');EPJS_toggle('${colbarid}',true);EPJS_toggle('${barid}',false);return false", href=>"#" );

		$col_div->appendChild( $col_link );
		$col_link->appendChild( $self->{session}->make_element( "img", alt=>"+", src=>"$imagesurl/display_images/plus_lshtm.png", border=>0 ) );
		$col_link->appendChild( $self->{session}->make_text( " " ) );
		$col_link->appendChild( $component->render_title( $self ) );
		$surround->appendChild( $col_div );

		# alternate title to allow it to re-hide
		my $recol_link =  $self->{session}->make_element( "a", onclick => "EPJS_blur(event); EPJS_toggleSlideScroll('${contentid}',false,'${main_id}');EPJS_toggle('${colbarid}',true);EPJS_toggle('${barid}',false);return false", href=>"#", class=>"ep_only_js ep_toggle ep_sr_collapse_link" );
		$recol_link->appendChild( $self->{session}->make_element( "img", alt=>"-", src=>"$imagesurl/display_images/minus_lshtm.png", border=>0 ) );
		$recol_link->appendChild( $self->{session}->make_text( " " ) );
		
		#nb. clone the title as we've already used it above.
		$recol_link->appendChild( $self->render_title( $component ) );
		$title_div->appendChild( $recol_link );

		my $nojstitle = $self->{session}->make_element( "div", class=>"ep_no_js" );
		$nojstitle->appendChild( $self->render_title( $component ) );
		$title_div->appendChild( $nojstitle );

	}
	else
	{
		$title_div->appendChild( $self->render_title( $component ) );
	}

	
	$surround->appendChild( $content );
	return $surround;
}

# this adds an expand/hide icon to the title bar that enables showing/hiding
# help and adds the help text to the content_inner

sub _render_help
{
	my( $self, $component, $title_bar, $content_inner ) = @_;

	my $session = $self->{session};

	my $prefix = $component->{prefix}."_help";

	my $help = $component->render_help( $self );

	# add the help text to the main part of the component
	my $hide_class = !$component->{no_toggle} ? "ep_no_js" : "";
	my $div = $session->make_element( "div", class => "ep_sr_help $hide_class", id => $prefix );
	$content_inner->appendChild( $div );
	my $div_inner = $session->make_element( "div", id => $prefix."_tooltip_inner" );
	$div_inner->appendChild( $help );
	$div->appendChild( $div_inner );

	# don't render a toggle button (help toggle)
	if( $component->{no_toggle} )
	{
		return;
	}

	my $action_div = $session->make_element( "div", class => "ep_only_js", id=>$prefix."_tooltip" );
	$action_div->appendChild( $self->html_phrase( "icon_help" ) );
	$title_bar->appendChild( $action_div);
	
	
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
