#!/usr/bin/perl -Tw

use strict;

use Image::Magick;
use Math::Tau;

my $height=500;
my $width=500;

my $zoom=1;
my $xzoom=$zoom;
my $yzoom=$zoom;
my $leftmargin=0;
my $rightmargin=0;
my $topmargin=0;
my $bottommargin=0;
my $imagewidth=$width*$xzoom+$leftmargin+$rightmargin;
my $imageheight=$height*$yzoom+$topmargin+$bottommargin;

sub rgba {return sprintf("#"."%02x"x4,@_)}
sub rgb  {return sprintf("#"."%02x"x3,@_)}
sub gradient 
{
    my ($color1, $color2,$n) = @_;
    my $rstep = ($color2->[0] - $color1->[0]) / ($n - 1);
    my $gstep = ($color2->[1] - $color1->[1]) / ($n - 1);
    my $bstep = ($color2->[2] - $color1->[2]) / ($n - 1);
    my @result;
    foreach my $i (0..$n) 
    {
	push @result, [int($color1->[0] + $i * $rstep),
		       int($color1->[1] + $i * $gstep),
		       int($color1->[2] + $i * $bstep)];
    }
    return @result;
}


sub gcd {
    my ($a, $b) = @_;
    ($a,$b) = ($b,$a) if $a > $b;
    while ($a) {
	($a, $b) = ($b % $a, $a);
    }
    return $b;
}
# XXX Conf here

my $n_points=pop()||11;
my $step=pop()||5;


my $radius = 200;
my $center=[$width/2, $height/2];
my @points=(); # array of points to connect.
for(my $i=0; $i<$n_points; $i++)
{
    my $angle=tau()*$i/$n_points;
    my $new_point=[@$center]; 
    $new_point->[0]+=$radius*cos($angle);
    $new_point->[1]+=$radius*-sin($angle); # make the point order go in the positive direction in the image.
    $points[$i]=$new_point;
}


# use List::Util;
# @points=List::Util::shuffle(@points);

my $points_string=join" ", map "$_->[0],$_->[1]", @points;
#print $points_string;
# print "($_->[0], $_->[1])\n" for @points;

#$image->Draw(primitive=>"polygon", points=>$points_string, strokewidth=>3);

#my $t= 3.7; # how many chords to draw

my $fpc=11; # frames per chord
my $t=0;
my $prev_point=$points[0];
foreach my $frame (0..$fpc*$n_points)
{
    my $color = rgba(255,255,100,255);
    my $blur_color = rgba(255,255,100,168);
    my $vertex_radius=6;
    print "frame $frame\n";
#    $image->Draw(primitive=>"polygon", points=>$points_string, antialias=>"true", strokewidth=>3);
#    $image->Draw(primitive=>"polygon", points=>$points_string, antialias=>"true", strokewidth=>3);
    my $image = Image::Magick->new();
    $image->Set(size=>"${imagewidth}x${imageheight}");
    $image->ReadImage('canvas:black');
    $image->Set(alpha=>"on");
    $image->Set(AntiAlias=>"True");
    $image->ReadImage("canvas:black");
    foreach my $vertex (@points)
    {
	my $vertex_center_color = rgba(0,0,0,255); #first, draw the outline in this color
	my $coords="$vertex->[0],$vertex->[1] $vertex->[0],@{[$vertex->[1]+$vertex_radius]}";
	$image->Draw(primitive=>"circle", stroke=>$color, fill=>$vertex_center_color, points=>$coords);
    }
    my @squiggle=();
    push @squiggle, $points[($_*$step)%$n_points] for 0..int($t); # visited vertices

    foreach my $vertex (@squiggle)
    {
	my $vertex_center_color = $color; # fill visited vertices with this color 
	my $coords="$vertex->[0],$vertex->[1] $vertex->[0],@{[$vertex->[1]+$vertex_radius]}";
	$image->Draw(primitive=>"circle", stroke=>$color, fill=>$vertex_center_color, points=>$coords);
    }

    my $remainder=$t-int($t);
    print "$remainder\n";
    my $last_vertex=$points[($step*int($t))%$n_points];
    my $destination_vertex=$points[($step*(int($t)+1))%$n_points];
    my $final_point=[map {$destination_vertex->[$_]*$remainder + $last_vertex->[$_]*(1-$remainder)} (0,1)];
    
    my $linewidth = 3;
    my $endpoints=join(" ", map "$_->[0],$_->[1]", @squiggle, $final_point);
    print $endpoints, "\n";
    $image->Draw(primitive=>"polyline", stroke=>$color, strokewidth=>1.5, antialias=>"true", points=>$endpoints); 

    foreach my $vertex (@squiggle)
    {
	my $vertex_center_color = $color; # fill visited vertices with this color 
	my $coords="$vertex->[0],$vertex->[1] $vertex->[0],@{[$vertex->[1]+$vertex_radius]}";
	$image->Draw(primitive=>"circle", stroke=>$color, fill=>$vertex_center_color, points=>$coords);
    }

    if(gcd($step, $n_points) > 1)
    {
	my $turtle_size=5;#+3*sin($remainder*8);
#	$image->Draw(primitive=>"circle", fill=>$color, points=>"$final_point->[0],$final_point->[1] $final_point->[0],@{[$final_point->[1]+$turtle_size]}");
	# motion blur
	my $blur_length=.5;
	my @blur_points=($final_point,$prev_point);
	$image->Draw(primitive=>"polyline", stroke=>$blur_color, points=>"$final_point->[0],$final_point->[1] $prev_point->[0],$prev_point->[1]", strokewidth=>$turtle_size*2);
        $prev_point=$final_point;
    }
    
    $image->set(filename=>sprintf("%03d_over_%04d_frame_%04d.png", $step, $n_points, $frame));
    $image->Write();
    $t+=1.0/$fpc;
}

