#!/usr/bin/perl
#
# Webber processor for creating HTML from media wiki
#

package MediaWiki ;

#-------------------------------------------------------------------------
# Function: debug 
#-------------------------------------------------------------------------
sub debug {
        my @lines = @_ ;
        if (defined (&wbbdebug)) { wbbdebug (@lines) ; }
        elsif (defined main::debug) { main::debug (@lines) ; }
        else {
          my $level = shift @lines ;
        my $line= join '', @lines ;
        chomp $line ;
        print STDERR "$line\n" ;
        }
}
# End Funcion debug



my $name=	"MediaWiki";
my $version=	"1.0";

my %defs = (
	'mediawiki.vars' => 'wbbOut:wbbOut wbbIn:wbbIn' ,
	) ;

sub info {
   print "$name v$version:  TRranform a wbb Var from MediaWiki to HTML \n";
}

sub help
{
   print <<FINAL
$name 

Webber processor, version $version
This program must run inside Webber.
This processor modified the a list of webber vars , changing the mediawiki 
to  XHTML 

$name can be used in any list of processors

$name uses the following Webber variables:
 #mediawiki.vars : vars to change
 defaults to $defs{'mediawiki.vars'} 

format varsource:vardestination

FINAL
}

sub mediawiki
{
#  use XHTML::MediaWiki;
  my $mediawiki = XHTML::MediaWiki->new();

   debug( 1, "(MediaWiki) MediaWiki  se ejecuta\n") ;
   my $rv =$_[0] ;
	
  $vars = defined ($$rv{'mediawiki.vars'}) ? $$rv{'mediawiki.vars'} : $defs{'mediawiki.vars'} ;

  foreach my $do  (split /\s+/, $vars)  {
	my ($src,$dst) = split /:/ , $do ;
	$$rv{$dst} = $mediawiki->format ($$rv{$src} ) ;
 }
}

if ($0 =~ /$name/) { &help; die ("\n"); }

1;
