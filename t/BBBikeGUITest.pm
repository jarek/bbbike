# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2003,2006,2012,2015,2017 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

#
# Usage:
#   cd .../bbbike
#   env LANG=en_US.UTF-8 BBBIKE_GUI_TEST_MODULE=BBBikeGUITest perl -It ./bbbike -public
# or
#   env BBBIKE_TEST_GUI=1 prove t/bbbikeguitest-de.t

package BBBikeGUITest;

use strict;
use vars qw($VERSION);
$VERSION = 2.00;

use Time::HiRes ();
use Test::More qw(no_plan);

use BBBikeUtil qw(first);
use Strassen::Util;
use VectorUtil;

my($top, $c);
my $start_time = $ENV{BBBIKE_TEST_STARTTIME};

my %qr = %{
           {
	    'en_US.UTF-8' => +{
			       streets => qr{^Streets$},
			       start   => qr{^Start$},
			       dest    => qr{^Destination$},
			      },
	    'de_DE.UTF-8' => +{
			       streets => qr{^Stra.*en$}, # XXX damn unicode!
			       start   => qr{^Start$},
			       dest    => qr{^Ziel$},
			      },
	   }->{$ENV{LANG}}
          };

sub start_guitest {
    my $end_time = Time::HiRes::time();
    diag "Starting GUI test, start duration was " . sprintf("%.3f", $end_time-$start_time) . " seconds...\n";

    $top = $main::top;
    $c   = $main::c;

    pass "Actually starting GUI test";

 SKIP: {
	skip "No cursor control tests for now...", 1;

	skip "Tk::CursorControl not installed", 1
	    if !eval { require Tk::CursorControl };

	my $cc = $top->CursorControl;
	$cc->warpto($c);
	$c->eventGenerate("<Key-S>");
	ok(1);
    }

    main::plot("str", "s", -draw => 1);
    $top->update;
    pass("Streets plotted");

    my(@t) = $c->find(withtag => "Dudenstr.");
    cmp_ok(scalar(@t), ">", 0, "Found Dudenstr");
    my @c = $c->coords($t[0]);
    my($x,$y) = @c[0,1];
    @t = eval { main::nearest_line_points($x,$y,$c->gettags($t[0])) };
    is($t[0], 0, "First index in Dudenstr.");
    my($tx,$ty) = main::transpose(@{ $t[2] });
    cmp_ok(abs($tx-$x), "<", 1)
	or diag "result from nearest_line_points: @t";
    cmp_ok(abs($ty-$y), "<", 1)
	or diag "result from nearest_line_points: @t";

    $top->after(500, sub { wait_for_chooser_window(0) });
}

sub wait_for_chooser_window {
    my($iteration) = @_;

    my $chooser_window;
    my %seen_toplevels;
    $top->Walk(sub {
    		   my $w = shift;
    		   if ($w->isa('Tk::Toplevel')) {
		       my $title = $w->title;
		       if ($title =~ $qr{streets}) {
			   $chooser_window = $w;
		       } else {
			   $seen_toplevels{$title}++;
		       }
    		   }
    	       });
    if ($chooser_window) {
	ok $chooser_window, 'Found chooser window';
	continue_guitest_with_chooser_window($chooser_window);
    } else {
	$iteration++;
	if ($iteration > 50) { # on a typical desktop system, BBBike should start withing 2-3 seconds. On travis-ci it's slower, up to 10 seconds.
	    fail "Cannot find chooser window after $iteration iterations. Current toplevels: " . join("\n", sort keys %seen_toplevels);
	    exit_app();
	}
	$top->after(500, sub { wait_for_chooser_window($iteration) });
    }
}

sub continue_guitest_with_chooser_window {
    my($chooser_window) = @_;

    my $chooser_entry;
    my $chooser_start;
    my $chooser_goal;
    $chooser_window->Walk(sub {
			      my $w = shift;
			      if ($w->isa('Tk::Entry')) {
				  $chooser_entry = $w;
			      } elsif ($w->isa('Tk::Button')) {
				  if ($w->cget('-text') =~ $qr{start}) {
				      $chooser_start = $w;
				  } elsif ($w->cget('-text') =~ $qr{dest}) {
				      $chooser_goal = $w;
				  }
			      }
			  });
    ok $chooser_entry, 'Found chooser entry';
    ok $chooser_start, 'Found chooser start button';
    ok $chooser_goal, 'Found chooser goal button';

    $chooser_entry->insert("end", "Dudenstr");
    $chooser_start->invoke;
    $chooser_entry->delete(0, "end");
    $chooser_entry->insert("end", "Alexanderplatz");
    $chooser_goal->invoke;

    cmp_ok scalar(@main::realcoords), ">=", 10, 'More than 10 points in route';
    ok VectorUtil::point_in_polygon($main::realcoords[0], [[8168,8821], [8171,8752], [9262,8745], [9256,8831]]), "Start is near Dudenstr.";
    cmp_ok Strassen::Util::strecke($main::realcoords[-1], [10970,12822]), "<", 100, "Goal is near Alexanderplatz";
    #require Data::Dumper; print STDERR "Line " . __LINE__ . ", File: " . __FILE__ . "\n" . Data::Dumper->new([\@main::realcoords],[qw()])->Indent(1)->Useqq(1)->Dump; # XXX

    {
	# The following code tries to find the relevant labels and
	# buttons in the grid next to the km frame and does checks
	# on them

	my $km_button; # reference "point": the km title (which is a button)
	$top->Walk(sub {
		       return if $km_button;
		       my $w = shift;
		       if ($w->isa('Tk::Button') && $w->cget('-text') eq 'km') {
			   $km_button = $w;
		       }
		   });
	if (!$km_button) {
	    fail "Cannot find km button";
	} else {
	    my $km_frame = $km_button->parent;
	    my $dist_info_frame = $km_frame->parent;
	    # Get all children starting from the km_frame and following
	    my @dist_info_children = $dist_info_frame->children;
	    while (@dist_info_children && $dist_info_children[0] != $km_frame) {
		shift @dist_info_children;
	    }
	    if (!@dist_info_children) {
		fail "Strange: cannot find $km_frame in children";
	    } else {
		my @w_table; # "table" of widgets, starting at km and ending at the second power
		for my $x (0..5) {
		    my $f = $dist_info_children[$x];
		    if (!$f) {
			fail "Cannot find frame index $x";
		    } elsif (!$f->isa('Tk::Frame')) {
			fail "Widget index $x is not a frame, but a $f";
		    } else {
			for my $cw ($f->children) {
			    next if !$cw->isa('Tk::Label') && !$cw->isa('Tk::Button');
			    push @{ $w_table[$x] }, $cw->cget('-text');
			    last if @{ $w_table[$x] } >= 2;
			}
		    }
		}

		is $w_table[0][0], 'km';
		like $w_table[0][1], qr{^\d+\.\d+$}, 'km looks like a float';
		cmp_ok $w_table[0][1], '>=', 5, 'expected min distance'; # should be ca. 5.3 km
		cmp_ok $w_table[0][1], '<=', 7, 'expected max distance';

		is $w_table[1][0], '%';
		like $w_table[1][1], qr{^\d+$}, '% looks like an integer';
		cmp_ok $w_table[1][1], '>=', 10, 'expected min percentage'; # should be ca. 13 %
		cmp_ok $w_table[1][1], '<=', 30, 'expected max percentage';

		is $w_table[2][0], '15 km/h';
		like $w_table[2][1], qr{^\d+:\d+ h$}, 'looks like a time'; # should be 0:19 h or so

		is $w_table[3][0], '20 km/h';
		like $w_table[3][1], qr{^\d+:\d+ h$}, 'looks like a time';

		like $w_table[4][0], qr{^\d+ W$}, 'looks like a power spec'; # should be 30 W or so
		like $w_table[4][1], qr{^\d+:\d+ h$}, 'looks like a time';

		like $w_table[5][0], qr{^\d+ W$}, 'looks like a power spec';
		like $w_table[5][1], qr{^\d+:\d+ h$}, 'looks like a time';

	    }
	}
    }

    remove_streets_layer();
    exit_app();
}

sub remove_streets_layer {
    main::plot("str", "s", -draw => 0);
    $top->update;
    {
	my @items = $c->find(withtag => "Dudenstr.");
	is @items, 0, "Street layer was removed, no more streets";
    }
}

sub exit_app {
    main::exit_app_noninteractive();
    pass 'Application exited';
}

1;

__END__
