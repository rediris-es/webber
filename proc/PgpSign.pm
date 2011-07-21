#!/usr/bin/perl
#
# A Webber processor for digitally signing
#

package PgpSign ;

use English ;
my $name=	"PgpSign";
my $version=	"0.3";

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

    debug 3,  "PgpSign::pgpsign execution" ;
#
# cut &paste
#
$file= "/tmp/pgpfirma.$$" . $BASETIME ;

unlink $file if -r $file ; 

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
debug 3, "execution was $pgp < $file" ;
unlink $file ;
$$var{$wbbdst} =  $mes ;
debug 3, "message placed in $wbbdst was\n....\n$mes\....\n" ; 

 $INPUT_RECORD_SEPARATOR = $i; 
}

if ($0 =~ /$name/) { &help; die ("\n"); }

1;
