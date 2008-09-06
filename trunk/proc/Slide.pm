#!/usr/bin/perl
#
# A Webber processor to build slide-show pages
# 
# (c) RedIRIS 2000
#
package Slide;
use Time::localtime;

my $name ="Slide" ;
my $version= "1.0" ;

sub info {
   print "$name v$version: Build slide-show pages" ;
}

sub help {
   print <<FINAL
$name

Webber processor, version $version
Builds and links a set of pages in a slide-show style.
Target file names are assumed to have the following structure:
	<PREFIX>N<POSTFIX>
Where <PREFIX> and <POSTFIX> are arbitrary strings, without numbers inside
them, and N is the number of the slide. The strings for <PREFIX> and
<POSTFIX> must be the same for all the slides. It is also assumed that all
slide files live in the same directory (or location into the server).
This progran must run inside Webber.
It modifies the Webber variable identified by #slide.dst, as defined below.

$name uses the following Webber variables:
 
 #slide.dst:          Identifies the name of the Webber variable where the
                      processor will include its output. The output is
                      concatenated with the previous value of the variables. By
                      default, "wbbOut" is used.
 #slide.first:        The number for the first slide to be processed. 1 by
                      default.
 #slide.last:         The number for the last slide to be processed. 100 by
                      default.
 #slide.next_button:  The name of the image to be used for pointing to the next
                      slide. Defaults to "next.gif".
 #slide.prev_button:  The name of the image to be used for pointing to the 
                      previous slide. Defaults to "prev.gif".
 #slide.first_button: The name of the image to be used for pointing to the first
                      slide. Defaults to "first.gif".
 #slide.last_button:  The name of the image to be used for pointing to the last
                      slide. Defaults to "last.gif".
 #slide.header:       Header to be included prior to the contents of the slide.
                      Defaults to "<h3>Slide #slide.num of #slide.last</h3>".
 #slide.image_header: A header to be included prior to the image (if any) shown
                      in the slide. Defaults to ""
 #slide.image:        The name of the image to be shown inside the slide.
 #slide.image_width:  The width the image will be rendered with.
 #slide.image_height: The height the image will be rendered with.
 #slide.text_header:  A eader to be included prior to the text (if any) shown
                      in the slide. Defaults to "<h3>Notes</h3>".
 #slide.text:         The text to be shown inside the slide.
 #slide.num:          It set to the number of the slide being processed, for
                      further use of any other processor.
FINAL
}

sub slide {
   my $lin="";
   my $var = $_[0];
   my $place="wbbOut";
   my $pre = "";
   my $num = 0;
   my $pos = "";
   my $next = "";
   my $prev = "";
   my $prevb = "prev.gif";
   my $nextb = "next.gif";
   my $first = 1;
   my $firstn = "";
   my $firstb = "first.gif";
   my $last = 100;
   my $lastn = "";
   my $lastb = "last.gif";

   $lin .= "\n<!-- Webber proc $name v$version -->\n";

   if (defined $$var{'slide.dst'}) { $place = $$var{'slide.dst'}; }
   if ($$var{'wbbTargetName'} =~ /([\D]*)([\d]+)([\D]*)/) {
      $num = $2;
      $pre = $1;
      $pos = $3;
      $next = $1.($num+1).$3;
      $prev = $1.($num-1).$3;
   }
   $$var{'slide.num'} = $num;
   if (defined $$var{'slide.next_button'}) {
      $nextb = $$var{'slide.next_button'};
   }
   if (defined $$var{'slide.prev_button'}) {
      $prevb = $$var{'slide.prev_button'};
   }
   if (defined $$var{'slide.first'}) {
      $first = $$var{'slide.first'};
      $firstn = $pre.$first.$pos;
   }
   if (defined $$var{'slide.first_button'}) {
      $firstb = $$var{'slide.first_button'};
   }
   if (defined $$var{'slide.last'}) {
      $last = $$var{'slide.last'}; 
      $lastn = $pre.$last.$pos; 
   }
   if (defined $$var{'slide.last_button'}) {
      $lastb = $$var{'slide.last_button'};
   }

# Nav buttons
#
   $lin .="<center>\n" ;
   $lin .="<a href=\"$firstn\"><img src=\"$firstb\" alt=\"first\" border=\"0\"></a>&nbsp;&nbsp;\n";
   if ($num > $first){ $lin .= "<a href=\"$prev\"><img src=\"$prevb\" alt=\"prev\" border=\"0\"></a>&nbsp;&nbsp;\n"; }
   if ($num < $last){ $lin .= "<a href=\"$next\"><img src=\"$nextb\" alt=\"next\" border=\"0\"></a>&nbsp;&nbsp;\n"; }
   $lin .="<a href=\"$lastn\"><img src=\"$lastb\" alt=\"last\" border=\"0\"></a>\n";
   if (defined $$var{'slide.header'}) { $lin .= "$$var{'slide.header'}\n"; }
   else {
      $lin .="<h3>Slide $num of $last</h3>\n"; }
   $lin .= "</center>\n<br>\n";
	
# Image
#
   if (defined $$var{'slide.image'}) {
      my $iw = "";
      my $ih = "";
      if (defined $$var{'slide.image_header'}) {
         $lin .="$$var{'slide.image_header'}\n";
      }
      if (defined $$var{'slide.image_width'}) {
         $iw = " width = \"$$var{'slide.image_width'}\"";
      }
      if (defined $$var{'slide.image_height'}) {
         $ih = " height = \"$$var{'slide.image_height'}\"";
      }
      $lin .="<center><a href=\"$$var{'slide.image'}\"><img src=\"$$var{'slide.image'}\" $iw $ih></a></center>\n";
   }

# Text
#
   if (defined $$var{'slide.text'}) {
      if (defined $$var{'slide.text_header'}) {
         $lin .="$$var{'slide.text_header'}\n";
      }
      else { $lin .= "<h3>Notes</h3>"; }
      $lin .="$$var{'slide.text'}\n";
   }

# Update destination variable
#
   $$var{$place} .= $lin;
} 

if ($0 =~ /$name/) { &help; die ("\n"); }

1;
