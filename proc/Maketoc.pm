#!/usr/bin/perl
#
# Simple Webber processor for TOC generation
#
# (c) RedIRIS 2000
#
package Maketoc;

my $name="Maketoc";
my $version="1.0";


#DEBUG-INSERT-START

#-------------------------------------------------------------------------
# Function: debug
# Version 2.0
# Permite el "debug por niveles independientes"
 
#-------------------------------------------------------------------------
sub debug {
        my @lines = @_ ;
# Por el tema de strict 
        no strict "subs" ;
	my $level = $lines[0] ;
	unshift @lines , $name;
        if (defined main::debug_print) { main::debug_print (@lines) ; }
       else {
          my $level = shift @lines ;
        my $line= join '', @lines ;
        chomp $line ;
        print STDERR "$name: $line\n" ;
        }
use strict "subs" ;
# Joder mierda del strict 
}
# End Funcion debug



#DEBUG-INSERT-END






#
# Default configuration
#
   my $iampreD=0;
   my $pretocD="<h1><center>Table of Contents</center></h1></a><hr><p>\n";
   my $postocD="<hr><p>\n";
   my $numberD=0;
   my $anchorD="<p><a href=\"#TOC\">Contents</a><br>";
   my @tagsD= ("H1");

sub info {
   print "$name v$version: TOC generation\n";
}

sub help {
   print <<FINAL
$name 

Webber processor, version $version
Prepends a TOC to an HTML page.
This progran must run inside Webber.
It modifies the following Webber variables:
 #wbbOut:      The TOC is appended and, depending of the value of
               #maketoc.ispre, the value of #wbbIn (modified with the anchors
               of the TOC) is also appended.
 #wbbIn:       Remains unchanged (if #maketoc.ispre is not set to 1). 
               Updated to contain the anchors of the TOC (if #maketoc.ispre is
               set to 1).
 #maketoc.TOC: Holds the TOC generated by the processor.

Depending on the value of #maketoc.ispre, it may be used as (one of) the last
pre-processor(s) (for #maketoc.ispre=1), or as (one of) the first processor(s)
(for #maketoc.ispre=0).

$name uses the following Webber variables:

 #maketoc.ispre:  If set to 1, the anchors of the TOC are included by modifying
                  #wbbIn. Otherwise, the anchors are included in a copy of 
                  #wbbIn that is appended to #wbbOut after the TOC.
 #maketoc.pretoc: Text included before the TOC
 #maketoc.postoc: Text included after the TOC
 #maketoc.number: If set to 1, numbers are automatically inserted into the TOC
                  and the headers.
 #maketoc.tags:   A blank-separated list of the tags used for building the TOC.
                  Order is important, since the first tag will be considered of
                  level 1, the second tag of level 2, and so on.
 #maketoc.preN:   Text to be prepended for TOC entries of level N.
 #maketoc.postN:  Text to be appended for TOC entries of level N.
 #maketoc.anchor: A text to be added to the contents of the TOC anchors
 
By default, the following values are assumed:

 #maketoc.ispre:  $iampreD
 #maketoc.pretoc: $pretocD
 #maketoc.postoc: $postocD
 #maketoc.number: $numberD
 #maketoc.tags:   $tagsD[0]
 #maketoc.anchor: $anchorD
FINAL
}

sub maketoc {
   local $var = $_[0];
   if (exists $$var{"maketoc.ispre"}) { $iampre = $$var{"maketoc.ispre"}; }
   else { $iampre = $iampreD; }
   if (exists $$var{"maketoc.pretoc"}) { $pretoc = $$var{"maketoc.pretoc"}; }
   else { $pretoc = $pretocD; }
   if (exists $$var{"maketoc.postoc"}) { $postoc = $$var{"maketoc.postoc"}; }
   else { $postoc = $postocD; }
   if (exists $$var{"maketoc.number"}) { $number = $$var{"maketoc.number"}; }
   else { $number = $numberD; }
   if (exists $$var{"maketoc.tags"}) { 
      @tags = split /\s/, $$var{"maketoc.tags"};
   }
   else { @tags = @tagsD; }
   if (exists $$var{"maketoc.anchor"}) { $anchor = $$var{"maketoc.anchor"}; }
   else { $anchor = $anchorD; }
   my $i, $j;
   my $ftoc;
   my @pre, @post, @tnum;
   for $i (0 .. $#tags) {
      $j = "maketoc.pre".($i+1);
      $pre[$i] = $$var{$j} if (exists $$var{$j});
      $j = "maketoc.post".($i+1);
      $post[$i] = $$var{$j} if (exists $$var{$j});
      $tnum[$i] = 0 if ($number eq "1");
   }

   my $tt, $tv, $ti = 0, $lv = 0;
   my @toc, @tdata;
   foreach $tt (@tags) {
      @tdata = ($$var{"wbbIn"} =~ /<$tt>.*?<\/$tt>/gim);
      foreach $tv (@tdata) {
         $toc[$ti][0] = $lv;
         $toc[$ti++][1] = $tv;
      }
      ++$lv;
   }
   @toc = sort {
      my $pa = index $$var{"wbbIn"}, @$a[1];
      my $pb = index $$var{"wbbIn"}, @$b[1];
      $pa <=> $pb;
   } @toc;
      
   for $i (0 .. $#toc) {
      $toc[$i][1] =~ /<$tags[$toc[$i][0]]>(.*)<\/$tags[$toc[$i][0]]>/im;
      if ($number ne "1") { $ttv = $1; }
      else {
         $ttv = "";
         for $j (0 .. $toc[$i][0] - 1) { $ttv .= $tnum[$j]."."; }
         $ttv .= join '',(++$tnum[$toc[$i][0]]),". <a href=\"#TOCITEM",
                         $i,"\">",$1,"</a>";
      }
      $ftoc .= join '',$pre[$toc[$i][0]],$ttv,$post[$toc[$i][0]],"\n";
   }

   $ftoc = join '',"<a name=\"TOC\"></a>",$pretoc,$ftoc,$postoc;
   $$var{"maketoc.TOC"} = "<!-- Webber proc $name v$version -->\n".$ftoc;
   $$var{"wbbOut"} .= $$var{"maketoc.TOC"};

   if ($number eq "1") { for $i (0 .. $#tags) { $tnum[$i] = 0; } }
   $ftoc = $$var{"wbbIn"};
   for $i (0 .. $#toc) {
      if ($number ne "1") {
         $ftoc =~ s%$toc[$i][1]%<a name="TOCITEM$i">$anchor</a>$toc[$i][1]%;
      }
      else {
         $toc[$i][1] =~ /<$tags[$toc[$i][0]]>(.*)<\/$tags[$toc[$i][0]]>/im;
         $ttv = "";
         for $j (0 .. $toc[$i][0] - 1) { $ttv .= $tnum[$j]."."; }
         $ttv .= join '',(++$tnum[$toc[$i][0]]),". ",$1;
         $ttv = join '',"<",$tags[$toc[$i][0]],">",$ttv,
                        "</",$tags[$toc[$i][0]],">";
         $ftoc =~ s%$toc[$i][1]%<a name="TOCITEM$i">$anchor</a>$ttv%;
      }
   }
   if ($iampre eq "1") { $$var{"wbbIn"} = $ftoc; }
   else { $$var{"wbbOut"} .= $ftoc; }
}

if ($0 =~ /$name/) { &help; die ("\n"); }

1;
