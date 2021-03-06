#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: strassen-bench.pl,v 1.4 2003/10/09 07:26:11 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2003 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

# Compare some splitting methods for a bbd line

use Benchmark;
use strict;
use Test;
use Data::Compare;
use Data::Dumper;

*doit = (defined &Benchmark::cmpthese ? \&Benchmark::cmpthese : \&Benchmark::timethese);

BEGIN { plan tests => 3*4 }

use vars qw($line);
my $short_line = "K�nigstr. (Zehlendorf)	NN 525,3008 694,3113";
my $medium_line = "St�lpchensee	F:W -7126,196 -7113,157 -7149,127 -7167,55 -7189,-46 -7180,-127 -7181,-189 -7219,-229 -7253,-240 -7286,-206 -7350,-215 -7365,-183 -7402,-159 -7431,-88 -7390,32 -7365,132 -7298,220 -7242,248 -7195,229 -7164,230 -7131,199";
my $long_line = "Lausitzer Nei�e	W1 E10442,7849 E10457,7872 E10460,7883 E10453,7900 E10455,7925 E10447,7940 E10432,7956 E10414,7963 E10407,7984 E10413,8024 E10404,8043 E10396,8074 E10385,8092 E10373,8102 E10372,8116 E10380,8132 E10375,8144 E10355,8157 E10337,8177 E10320,8178 E10316,8182 E10321,8200 E10312,8206 E10292,8201 E10282,8202 E10277,8221 E10259,8233 E10252,8291 E10232,8302 E10227,8325 E10217,8332 E10197,8337 E10163,8375 E10138,8380 E10123,8385 E10109,8410 E10125,8432 E10126,8446 E10116,8447 E10111,8433 E10104,8433 E10098,8441 E10107,8462 E10103,8472 E10091,8475 E10081,8464 E10072,8467 E10058,8481 E10061,8496 E10060,8512 E10068,8525 E10060,8540 E10062,8577 E10083,8589 E10094,8617 E10096,8633 E10109,8657 E10125,8664 E10139,8663 E10145,8669 E10158,8670 E10168,8674 E10192,8672 E10207,8676 E10213,8691 E10240,8697 E10248,8712 E10255,8740 E10270,8757 E10270,8781 E10276,8800 E10278,8851 E10266,8864 E10269,8878 E10287,8888 E10305,8894 E10310,8903 E10306,8910 E10288,8916 E10299,8941 E10288,8976 E10293,8990 E10304,8999 E10328,9058 E10351,9072 E10362,9087 E10373,9108 E10407,9152 E10433,9166 E10473,9198 E10496,9214 E10520,9242 E10535,9249 E10552,9246 E10567,9267 E10559,9285 E10566,9302 E10592,9314 E10600,9339 E10613,9352 E10616,9375 E10629,9388 E10624,9419 E10614,9428 E10610,9442 E10616,9453 E10627,9469 E10624,9484 E10626,9507 E10626,9521 E10630,9534 E10622,9558 E10630,9570 E10637,9584 E10655,9601 E10661,9617 E10658,9632 E10666,9649 E10665,9666 E10657,9676 E10653,9688 E10638,9701 E10628,9706 E10627,9719 E10621,9731 E10595,9743 E10588,9751 E10584,9762 E10561,9787 E10557,9797 E10550,9831 E10543,9843 E10526,9862 E10522,9872 E10512,9894 E10505,9899 E10503,9913 E10518,9947 E10537,9950 E10547,9959 E10558,9969 E10561,9983 E10569,9995 E10564,10009 E10561,10028 E10561,10053 E10563,10068 E10577,10081 E10583,10098 E10609,10103 E10634,10113 E10663,10108 E10672,10112 E10677,10126 E10688,10130 E10707,10131 E10726,10135 E10744,10132 E10763,10136 E10773,10130 E10786,10134 E10794,10143 E10814,10150 E10828,10171 E10834,10188 E10843,10190 E10858,10182 E10872,10189 E10904,10200 E10909,10206 E10912,10218 E10924,10224 E10933,10242 E10945,10245 E10969,10270 E10988,10270 E11006,10263 E11020,10268 E11032,10290 E11042,10292 E11057,10289 E11072,10278 E11089,10276 E11114,10299 E11130,10303 E11155,10293 E11182,10292 E11201,10302 E11212,10310 E11212,10342 E11220,10346 E11256,10346 E11288,10349 E11310,10382 E11319,10394 E11316,10408 E11320,10421 E11339,10439 E11350,10472 E11356,10481 E11379,10504 E11380,10524 E11366,10553 E11356,10545 E11347,10544 E11334,10557 E11336,10569 E11355,10583 E11353,10603 E11362,10626 E11353,10659 E11338,10665 E11337,10675 E11368,10714 E11368,10737 E11347,10735 E11337,10741 E11340,10749 E11360,10762 E11360,10778 E11358,10792 E11371,10811 E11372,10828 E11392,10835 E11404,10846 E11423,10855 E11417,10872 E11404,10879 E11404,10899 E11383,10913 E11368,10920 E11372,10938 E11392,10933 E11401,10945 E11402,10961 E11411,10992 E11408,11005 E11407,11022 E11420,11035 E11424,11061 E11439,11075 E11442,11089 E11458,11090 E11466,11101 E11462,11114 E11485,11134 E11498,11135 E11508,11150 E11521,11158 E11522,11166 E11513,11178 E11533,11193 E11539,11215 E11532,11227 E11541,11235 E11560,11233 E11589,11255 E11592,11269 E11603,11270 E11598,11306 E11609,11320 E11609,11346 E11619,11359 E11634,11370 E11634,11383 E11623,11387 E11626,11399 E11619,11428 E11625,11453 E11606,11458 E11600,11473 E11585,11477 E11581,11499 E11590,11504 E11597,11492 E11609,11508 E11624,11512 E11630,11523 E11615,11542 E11603,11536 E11597,11544 E11599,11566 E11587,11567 E11585,11576 E11594,11583 E11578,11608 E11565,11615 E11567,11648 E11564,11662 E11569,11681 E11547,11688 E11545,11700 E11554,11704 E11555,11716 E11538,11738 E11542,11762 E11554,11766 E11563,11776 E11548,11796 E11539,11794 E11532,11810 E11547,11855 E11535,11874 E11528,11905 E11537,11923 E11533,11939 E11500,11955 E11504,11986 E11524,12009 E11528,12025 E11513,12055 E11499,12058 E11497,12068 E11517,12115 E11513,12147 E11520,12165 E11490,12196 E11473,12192 E11466,12199 E11474,12213 E11464,12229 E11469,12236 E11463,12250 E11469,12260 E11479,12271 E11476,12290 E11482,12297 E11471,12299 E11476,12311 E11475,12319 E11481,12325 E11481,12335 E11469,12334 E11471,12352 E11459,12353 E11467,12398 E11472,12408 E11459,12411 E11458,12419 E11450,12419 E11448,12428 E11437,12433 E11437,12445 E11447,12448 E11443,12457 E11446,12467 E11431,12476 E11434,12487 E11421,12505 E11422,12515 E11427,12523 E11420,12525 E11429,12546 E11418,12548 E11411,12564 E11394,12567 E11391,12589 E11383,12584 E11380,12597 E11379,12609 E11385,12617 E11372,12644 E11378,12648 E11375,12667 E11366,12676 E11355,12677 E11362,12688 E11353,12686 E11354,12701 E11346,12695 E11344,12705 E11338,12709 E11340,12715 E11352,12727 E11348,12735 E11347,12757 E11339,12765 E11338,12787 E11328,12798 E11328,12820 E11311,12828 E11298,12823 E11290,12827 E11282,12840 E11282,12861 E11292,12875 E11290,12885 E11289,12913 E11292,12921 E11290,12927 E11295,12942 E11290,12951 E11249,12961 E11242,12967 E11246,12980 E11242,12991 E11232,13001 E11235,13010 E11246,13017 E11240,13025 E11228,13028 E11223,13032 E11222,13059 E11217,13068 E11212,13081";


for $line ($short_line, $medium_line, $long_line) {
    ok(Compare(split_impl(), index_impl()), 1,
       Data::Dumper->new([split_impl(), index_impl()],[])->Indent(1)->Dump
      );
    ok(Compare(split_impl(), index2_impl()), 1,
       Data::Dumper->new([split_impl(), index2_impl()],[])->Indent(1)->Dump
      );
    ok(Compare(split_impl(), rx_impl()), 1,
       Data::Dumper->new([split_impl(), rx_impl()],[])->Indent(1)->Dump
      );
    ok(Compare(split_impl(), splitindex_impl()), 1,
       Data::Dumper->new([split_impl(), splitindex_impl()],[])->Indent(1)->Dump
      );

    doit(-1,
	 {'split'  => \&split_impl,
	  'splitindex'  => \&splitindex_impl,
	  'index'  => \&index_impl,
	  'index2' => \&index2_impl,
	  'rx' => \&rx_impl,
	 }
	);
}

sub split_impl {
    my($name, $line) = split /\t/, $line, 2;
    my @s = split /\s+/, $line;
    my $category = shift @s;
    [$name, \@s, $category];
}

sub splitindex_impl {
    my $tab_inx = index($line, "\t");
    my @s = split /\s+/, substr($line, $tab_inx+1);
    my $category = shift @s;
    [substr($line, 0, $tab_inx), \@s, $category];
}

sub index_impl {
    my $tab_inx = index($line, "\t");
    my $spc_inx = index($line, " ", $tab_inx+1);
    my @s = split /\s+/, substr($line, $spc_inx+1);
    [substr($line, 0, $tab_inx),
     \@s,
     substr($line, $tab_inx+1, $spc_inx-$tab_inx-1)
    ]
}

sub index2_impl {
    my $tab_inx = index($line, "\t");
    my $spc_inx = index($line, " ", $tab_inx+1);
    my $category = substr($line, $tab_inx+1, $spc_inx-$tab_inx-1);
    my @s;
    while(1) {
	my $next_inx = index($line, " ", $spc_inx+1);
	if ($next_inx > -1) {
	    push @s, substr($line, $spc_inx+1, $next_inx-$spc_inx-1);
	    $spc_inx = $next_inx;
	} else {
	    push @s, substr($line, $spc_inx+1);
	    last;
	}
    }
    [substr($line, 0, $tab_inx),
     \@s,
     $category
    ]
}

sub rx_impl {
    my($name, $cat) = $line =~ /^([^\t]*)\t(\S+)/g;
    my(@s) = substr($line, length($name)+1+length($cat)) =~ /(?:\s+(\S+))/g;
    [$name, \@s, $cat];
}

__END__

Ergebnisse mit perl5.8.0:

Benchmark: running index, index2, rx, split, splitindex for at least 1 CPU seconds...
     index:  2 wallclock secs ( 1.05 usr +  0.00 sys =  1.05 CPU) @ 10037.10/s (n=10586)
    index2:  1 wallclock secs ( 1.07 usr +  0.00 sys =  1.07 CPU) @ 4592.12/s (n=4915)
        rx:  1 wallclock secs ( 1.06 usr +  0.00 sys =  1.06 CPU) @ 6167.53/s (n=6553)
     split:  1 wallclock secs ( 1.05 usr +  0.00 sys =  1.05 CPU) @ 10112.00/s (n=10586)
splitindex:  1 wallclock secs ( 1.04 usr +  0.00 sys =  1.04 CPU) @ 10188.03/s (n=10586)
              Rate     index2         rx      index      split splitindex
index2      4592/s         --       -26%       -54%       -55%       -55%
rx          6168/s        34%         --       -39%       -39%       -39%
index      10037/s       119%        63%         --        -1%        -1%
split      10112/s       120%        64%         1%         --        -1%
splitindex 10188/s       122%        65%         2%         1%         --

======================================================================

More results under RedHat 8.0, Intel Pentium 4 2.4MHz, perl 5.8.0:

short line:

Benchmark: running index, index2, rx, split, splitindex for at least 1 CPU seconds...
     index:  1 wallclock secs ( 1.08 usr +  0.00 sys =  1.08 CPU) @ 159287.96/s (n=172031)
    index2:  1 wallclock secs ( 1.11 usr +  0.00 sys =  1.11 CPU) @ 119218.02/s (n=132332)
        rx:  1 wallclock secs ( 1.11 usr +  0.00 sys =  1.11 CPU) @ 110701.80/s (n=122879)
     split:  1 wallclock secs ( 1.09 usr +  0.00 sys =  1.09 CPU) @ 143478.90/s (n=156392)
splitindex:  1 wallclock secs ( 1.10 usr +  0.00 sys =  1.10 CPU) @ 156392.73/s (n=172032)
               Rate         rx     index2      split splitindex      index
rx         110702/s         --        -7%       -23%       -29%       -31%
index2     119218/s         8%         --       -17%       -24%       -25%
split      143479/s        30%        20%         --        -8%       -10%
splitindex 156393/s        41%        31%         9%         --        -2%
index      159288/s        44%        34%        11%         2%         --

----------------------------------------------------------------------
Medium line:

Benchmark: running index, index2, rx, split, splitindex for at least 1 CPU seconds...
     index:  1 wallclock secs ( 1.03 usr +  0.00 sys =  1.03 CPU) @ 43952.43/s (n=45271)
    index2:  1 wallclock secs ( 1.08 usr +  0.00 sys =  1.08 CPU) @ 20958.33/s (n=22635)
        rx:  2 wallclock secs ( 1.12 usr +  0.00 sys =  1.12 CPU) @ 29538.39/s (n=33083)
     split:  1 wallclock secs ( 1.00 usr +  0.00 sys =  1.00 CPU) @ 43007.00/s (n=43007)
splitindex:  1 wallclock secs ( 1.08 usr +  0.00 sys =  1.08 CPU) @ 44246.30/s (n=47786)
              Rate     index2         rx      split      index splitindex
index2     20958/s         --       -29%       -51%       -52%       -53%
rx         29538/s        41%         --       -31%       -33%       -33%
split      43007/s       105%        46%         --        -2%        -3%
index      43952/s       110%        49%         2%         --        -1%
splitindex 44246/s       111%        50%         3%         1%         --

----------------------------------------------------------------------
Long line:

Benchmark: running index, index2, rx, split, splitindex for at least 1 CPU seconds...
     index:  1 wallclock secs ( 1.07 usr +  0.00 sys =  1.07 CPU) @ 2643.93/s (n=2829)
    index2:  2 wallclock secs ( 1.12 usr +  0.01 sys =  1.13 CPU) @ 1080.53/s (n=1221)
        rx:  1 wallclock secs ( 1.08 usr +  0.00 sys =  1.08 CPU) @ 1776.85/s (n=1919)
     split:  1 wallclock secs ( 1.11 usr +  0.00 sys =  1.11 CPU) @ 2548.65/s (n=2829)
splitindex:  1 wallclock secs ( 1.07 usr +  0.00 sys =  1.07 CPU) @ 2643.93/s (n=2829)
             Rate     index2         rx      split splitindex      index
index2     1081/s         --       -39%       -58%       -59%       -59%
rx         1777/s        64%         --       -30%       -33%       -33%
split      2549/s       136%        43%         --        -4%        -4%
splitindex 2644/s       145%        49%         4%         --         0%
index      2644/s       145%        49%         4%         0%         --

----------------------------------------------------------------------
