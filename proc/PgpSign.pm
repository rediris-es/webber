#!/usr/bin/perl
#
# A Webber processor for digitally signing
#

package PgpSign ;

use English ;
my $name=	"PgpSign";
my $version=	"0.2";

# defaults
my $defpgpsign= "/usr/bin/gpg -sat" ;
my $wbbsrc = "wbbOut" ;
my $wbbdst = "wbbOut" ;

my ($pgp, $file, $i,$mensaje) ;
sub info
{
 print "$name $version:\t Web processor for PGP signing web pages\n" ;
}
sub help
{
   print <<FINAL;
$name 

Webber processor, version $version
This program must run inside Webber.

This processor signs the page using PGP. The signature is 
hidden into an HTML comment, so users don't see anything special
in the page, but can download it and check the signature.
This MUST be (RFC 2119) the last proccesor that modifies the
contents of the page.

If you intend to use this in batch processing you will need
to unprotect your private PGP key or enter the passphrase in order
to sign all the pages.

$name uses the following variables:
   #pgpsign.cmdline : Command line and all the args needed by PGP
                      for signing the page.
                      The default value of this variable is:
                      $defpgpsign
   #pgpsign.srcvar : Webber variable to sign (default $wbbsrc),
   		      usually wbbIn or wbbOut
   #pgpsign.dstvar : Webber variable that will have the output,
   		      (default $wbbdst) usually wbbOut
FINAL

}
sub PgpSign {
	
   my $var = $_[0];
   if (exists $$var{'pgpsign.cmdline'})  
   	{ $pgp = $$var{'pgpsign.cmdline'} ; }
   else { $pgp = $defpgpsign ; }

   if (exists $$var{'pgpsign.srcvar'}) { $wbbsrc= $$var{'pgpsign.srcvar'} ; }
   if (exists $$var{'pgpsign.dstvar'}) { $wbbdst= $$var{'pgpsign.dstvar'} ; }

#
# cut &paste
#
$file= "/tmp/pgpfirma.$$" . $BASETIME ;

$i= $INPUT_RECORD_SEPARATOR ;
undef $INPUT_RECORD_SEPARATOR;

$mensaje= $$var{$wbbsrc} ;
open (SALIDA, ">$file") ;
print SALIDA "\n\n-->\n" ;
print SALIDA  $mensaje ;
print SALIDA "\n<!--WRAPPER TO PGP SIGN THIS PAGE\n\n" ;
close SALIDA ;
$mes ="" ;
open PGP , "$pgp < $file|" ;
$mes .= "<!-- Webber proc $name v$version -->\n" ;
$mes .= "<!-- PAGE SIGNED WITH PGP\n" ;
$mes .= scalar (<PGP>) ;
$mes .=  "\n (c) 2000 RedIRIS -->\n" ;

close PGP ;
unlink $file ;
$$var{$wbbdst} =  $mes ;

 $INPUT_RECORD_SEPARATOR = $i; 
}

if ($0 =~ /$name/) { &help; die ("\n"); }

1;
