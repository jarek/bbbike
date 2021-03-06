#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: common.pl,v 1.7 2007/03/31 20:11:03 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2002,2003,2006 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://bbbike.de
#

*search_c = ($algorithm eq 'C-A*-2'
	     ? \&Strassen::Inline2::search_c
	     : \&Strassen::Inline::search_c
	    );

# Yitzhak-Rabin/Bellevueallee => UdL/Glinkastr.
# This used to be "Entlastungsstraße", but this street does not exist anymore
# check for handicap_s feature
TEST5:
{
    require Strassen::Dataset;
    my $sd = Strassen::Dataset->new;
    my $handicap_net = $sd->get_net("str", "h", "city");
    my $handicap_penalty = {q0 => 1,
			    q1 => 2,
			    q2 => 3,
			    q3 => 4};

    require BBBikeRouting;
    my $routing = BBBikeRouting->new->init_context;
    $routing->Start->Street("Yitzhak-Rabin/Scheidemann");
    $routing->resolve_position($routing->Start);
    ok(defined $routing->Start->Coord, "Start coord defined");
    $routing->Goal->Street("Unter den Linden/Glinka");
    $routing->resolve_position($routing->Goal);
    ok(defined $routing->Goal->Coord, "Goal coord defined");

    my(@arr) = search_c(
        $net, $routing->Start->Coord, $routing->Goal->Coord,
	-penaltysub => sub {
	    my($next_node, $last_node, $pen) = @_;
	    if (defined $last_node and
		exists $handicap_net->{$last_node}{$next_node}) {
		$pen *= $handicap_penalty->{$handicap_net->{$last_node}{$next_node}}; # Handicapzuschlag
	    }
	    $pen;
        },
    );

    ok(scalar @arr, "Path result");
}

# Lützowufer => Schöneberger Ufer
# check for wegfuehrungen
TEST6:
{
    require BBBikeRouting;
    my $routing = BBBikeRouting->new->init_context;
    $routing->Start->Street("Lützowufer/Budapester");
    $routing->resolve_position($routing->Start);
    ok(defined $routing->Start->Coord, "Start coord defined");
    $routing->Goal->Street("Schöneberger Ufer/Kluckstr.");
    $routing->resolve_position($routing->Goal);
    ok(defined $routing->Goal->Coord, "Goal coord defined");

    my(@arr) = search_c(
        $net, $routing->Start->Coord, $routing->Goal->Coord,
    );

    my $path = $arr[0];
    my @route = $net->route_to_name($path);
    like($route[0]->[0], qr/Lützowufer/, "Expected street");
    like($route[1]->[0], qr/Schillstr\./, "Expected street");
}

# Potsdamer Str. => Heidestr.
# formerly check for einbahn
TEST7:
{
    require BBBikeRouting;
    my $routing = BBBikeRouting->new->init_context;
    $routing->Start->Street("Ben-Gurion/Potsdamer");
    $routing->resolve_position($routing->Start);
    ok(defined $routing->Start->Coord, "Start coord defined");
    $routing->Goal->Street("Invalidenstr./Heidestr.");
    $routing->resolve_position($routing->Goal);
    ok(defined $routing->Goal->Coord, "Goal coord defined");

    my(@arr) = search_c(
        $net, $routing->Start->Coord, $routing->Goal->Coord,
    );

    my $path = $arr[0];
    my @route = $net->route_to_name($path);
    like($route[0]->[0], qr/Ben-Gurion/, "Expected street");
    like($route[1]->[0], qr/Bellevueallee/, "Expected street");
}

# check for einbahn (Burgherrenstr.)
TEST8:
{
    require BBBikeRouting;
    my $routing = BBBikeRouting->new->init_context;
    $routing->Start->Street("Schulenburgring/Burgherren");
    $routing->resolve_position($routing->Start);
    ok(defined $routing->Start->Coord, "Start coord defined");
    $routing->Goal->Street("Burgherrenstr/Dudenstr");
    $routing->resolve_position($routing->Goal);
    ok(defined $routing->Goal->Coord, "Goal coord defined");

    my(@arr) = search_c(
        $net, $routing->Start->Coord, $routing->Goal->Coord,
    );

    my $path = $arr[0];
    my @route = $net->route_to_name($path);
    like($route[0]->[0], qr/Schulenburgring/, "Expected street");
    like($route[1]->[0], qr/Mussehlstr/, "Expected street");
}

$algorithm = $algorithm if 0; # peacify -w
__END__
