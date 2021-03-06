# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2013 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

package BBBikeMapserver::MkRouteMap;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';

use Getopt::Long qw(GetOptionsFromArray);

my @known_scopes = qw(INNERCITY CITY REGION WIDEREGION POTSDAM);

my @known_scopes_lc    = map { lc } @known_scopes;
my $known_scopes_rx    = "(" . join("|", @known_scopes) . ")";
my $known_scopes_lc_rx = lc $known_scopes_rx;
$known_scopes_rx       = qr($known_scopes_rx);
$known_scopes_lc_rx    = qr($known_scopes_lc_rx);

my %scope_aliases = ('brb'	=> 'region',
		     'b'	=> 'city',
		     'inner-b'	=> 'innercity',
		     'wide'	=> 'wideregion',
		     'p'	=> 'potsdam',
		    );

sub run {
    my $opts = shift || [];

    my $routeshapefile;
    my $routecoords;
    my $force;
    my $start;
    my $goal;
    my $marker_point;
    my $title_point;
    my $title_text;
    my $scope;
    my $addlayer_string;
    my $addlayer_file;
    my(@addlayer_def, %addlayer_def);
    if (!GetOptionsFromArray
	($opts,
	 "routeshpfile|routeshapefile=s" => \$routeshapefile,
	 "addlayer=s" => \$addlayer_string,
	 "addlayerfile=s" => \$addlayer_file,
	 "addlayerdef=s\@" => \@addlayer_def,
	 "routecoords=s" => \$routecoords,
	 "start=s" => \$start,
	 "goal=s" => \$goal,
	 "markerpoint=s" => \$marker_point,
	 "titlepoint=s" => \$title_point,
	 "titletext=s" => \$title_text,
	 "force!" => \$force,
	 "scope=s" => \$scope,
	)) {
	die "usage!";
    }

    my $oldmapfile = shift(@$opts) || die "Old map file?";
    my $newmapfile = shift(@$opts) || die "New map file?";

    if (defined $scope && exists $scope_aliases{$scope}) {
	$scope = $scope_aliases{$scope};
    }
    if (defined $scope && !grep { $_ eq $scope } @known_scopes_lc) {
	die "Unknown -scope parameter <$scope>: can handle only @known_scopes_lc @{[ keys %scope_aliases ]}\n";
    }

    if (defined $start) {
	$start =~ s/,/ /g;
    }
    if (defined $goal) {
	$goal =~ s/,/ /g;
    }
    if (defined $marker_point) {
	$marker_point =~ s/,/ /g;
    }
    if (defined $routecoords) {
	$routecoords =~ s/,/ /g;
    }

    for (@addlayer_def) {
	my($after, $file) = split /,/, $_, 2;
	if (exists $addlayer_def{$after}) {
	    warn "Overwriting layer definition $addlayer_def{$after} after $after with $file\n";
	}
	$addlayer_def{$after} = $file;
    }

    my $in_section = '';

    open my $OLD, $oldmapfile
	or die "Can't open $oldmapfile: $!";
    if (!$force && -e $newmapfile) {
	die "$newmapfile exists already";
    }
    open my $NEW, ">", $newmapfile
	or die "Can't write to $newmapfile: $!";
    while (<$OLD>) {
	if ($in_section eq 'route') {
	    if (/\#\#\#\s+END\s+ROUTE/) {
		$in_section = '';
	    } else {
		if (/\#\#\#\s+ROUTESHAPEFILE\s+\#\#\#/) {
		    if ($routeshapefile) {
			s/\#\#\#\s+ROUTESHAPEFILE\s+\#\#\#/$routeshapefile/g;
			s/^\#//;
		    }
		} elsif (/\#\#\#\s+ROUTECOORDS\s+\#\#\#/) {
		    if ($routecoords) {
			s/\#\#\#\s+ROUTECOORDS\s+\#\#\#/$routecoords/g;
			s/^\#//;
		    }
		} elsif (defined $routeshapefile || defined $routecoords) {
		    s/^\#//;
		}
	    }
	} elsif ($in_section =~ /((?:start|goal)flag)/) {
	    my $section = $1;
	    my $uc_section = uc($1);
	    if (/\#\#\#\s+END\s+$uc_section/) {
		$in_section = '';
	    } else {
		my $points = ($section eq 'startflag' ? $start : $goal);
		s/\#\#\#\s+(START|GOAL)FLAGPOINTS\s+\#\#\#/$points/g;
		s/^\#//;
	    }
	} elsif ($in_section eq 'marker') {
	    if (/\#\#\#\s+END\s+MARKER/) {
		$in_section = '';
	    } else {
		s/\#\#\#\s+MARKERPOINT\s+\#\#\#/$marker_point/g;
		s/^\#//;
	    }
	} elsif ($in_section eq 'title') {
	    if (/\#\#\#\s+END\s+TITLE/) {
		$in_section = '';
	    } else {
		s/\#\#\#\s+TITLEPOINT\s+\#\#\#/$title_point/g;
		s/\#\#\#\s+TITLETEXT\s+\#\#\#/$title_text/g;
		s/^\#//;
	    }
	} elsif ($in_section =~ /^refmap_$known_scopes_lc_rx$/) {
	    my $this_section = $1;
	    if (/\#\#\#\s+END\s+REFMAP\s+$known_scopes_rx/) {
		$in_section = '';
	    } else {
		s/^\#// if defined $scope && $scope eq $this_section;
	    }
	} elsif ($in_section eq 'addlayers') {
	    $_ = "";
	    if (defined $addlayer_string) {
		$_ .= $addlayer_string;
	    }
	    if (defined $addlayer_file) {
		open(my $fh, $addlayer_file) or die "Can't open $addlayer_file: $!";
		local $/ = undef;
		$_ .= <$fh>;
	    }
	    # END ADDITIONAL LAYERS is only a dummy
	    $in_section = '';
	} elsif ($in_section =~ /^addlayerdef\s+(.*)/) {
	    $_ = "";
	    my $after = $1;
	    my $file = $addlayer_def{$after};
	    if (defined $file) {
		open(my $fh, $file) or die "Can't open $file: $!";
		local $/ = undef;
		$_ .= <$fh>;
	    }
	    # END AFTER ... is only a dummy
	    $in_section = '';
	} elsif (/\#\#\#\s+BEGIN\s+ROUTE/) {
	    $in_section = 'route';
	} elsif (/\#\#\#\s+BEGIN\s+((?:START|GOAL)FLAG)/) {
	    my $section = lc($1);
	    if (($section eq 'startflag' && defined $start) ||
		($section eq 'goalflag' && defined $goal)) {
		$in_section = $section;
	    }
	} elsif (/\#\#\#\s+BEGIN\s+MARKER/) {
	    if (defined $marker_point) {
		$in_section = 'marker';
	    }
	} elsif (/\#\#\#\s+BEGIN\s+TITLE/) {
	    if (defined $title_point && defined $title_text) {
		$in_section = 'title';
	    }
	} elsif (/\#\#\#\s+BEGIN\s+REFMAP\s+$known_scopes_rx/) {
	    $in_section = 'refmap_' . lc($1);
	} elsif (/\#\#\#\s+BEGIN\s+ADDITIONAL\s+LAYERS/) {
	    $in_section = "addlayers";
	} elsif (/\#\#\#\s+BEGIN\s+AFTER\s+(.*)/) {
	    $in_section = "addlayerdef " . lc($1);
	    next;		# XXX oben auch nexts einfuegen?
	}
	print $NEW $_;
    }

    if ($in_section ne '') {
	die "### END for $in_section missing";
    }
}

1;

__END__
