#!/usr/bin/perl
#
# A Webber processor for digitally signing
#

package PgpSign ;

use English ;
use File::Copy ;
use strict ;

my $name=	"PgpSign";
my $version=	"1.0";

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
my $defpgpsigndetach= "/usr/bin/gpg -sb" ;
my $wbbsrc = "wbbOut" ;
my $wbbdst = "wbbOut" ;
my $msg="This page has been <a href=\"http://wwww.rediris.es/pgp/firmaweb\"> PGP signed </a>" ;
my $msgdetach="This HTML page has a <a href=\"http://www.rediris.es/pgp/firmaweb#detached\"> Detached PGP signature</a>" ;

my $msgvar="pgpsign" ;
my $msgvardet="pgpsigndet" ;

my $expVAR1= '<var name\s*\=\s*\"';
my $expVAR2= '\"\s*\/>';
my ($pgp, $file, $i,$mensaje) ;

#INFO-INSERT-START
sub info
{
 print "$name $version:\t Web processor for PGP signing web pages\n" ;
}

#INFO-INSERT-END 

#HELP-INSERT-START
sub help
{
   print <<FINAL;
$name 

Webber processor, version $version
This program must run inside Webber.

This Module  signs the  HTML pages using PGP, it contains two processors,

$name::PgpSign:  The signature is  hidden into an HTML comment, so users don't see anything 
special in the page, but can download it and check the signature.

This proc uses the following variables:
   #pgpsign.cmdline : Command line and all the args needed by PGP
                      for signing the page.
                      The default value of this variable is:
                      $defpgpsign
   #pgpsign.srcvar : Webber variable to sign (default $wbbsrc),
   		      usually wbbIn or wbbOut
   #pgpsign.dstvar : Webber variable that will have the output,
   		      (default $wbbdst) usually wbbOut
   #pgpsign.msg : Message to be place in the page (#pgpsign.msgvar) 
			stating that the page has been signed.
   #pgpsign.msgvar : Variable in pgpsign.srcvar that will contain the
			message about the signing of the web page.

$name::PGPSignDetached : The signature is placed in the a detached file (HTML_page.sig ), so you must
download this file in order to chech the integrity of the page. It has the advantage of generating correct
HTML pages.

This proc uses the following variables:
    #pgpsing.cmdline.detached: Command line and all the args needed by PGP/GnuP for signing the page.
			       The default value is $defpgpsigndetach
    #pgpsign.srcvar          : Webber variable to sign (defaults to $wbbsrc,  usually wbbIn or wbbOut.
    #pgpsign.dstvar	     : Webber variable that will have the output, (defaults to $wbbdst), usually wbbOut
    #pgpsign.msg.detached    : Message to be place in the page (#pgpsign.msgvar.detached) stating that the page
				has been signed. usually:
				$msgdetach
    #pgpsign.msgvar.detached : Variable in pgpsign.srcvar that will contain the messgage about the signing of 
				the page., defaults to $msgvardet 

This proc also uses the "wbbTarget" variable to write the ".sig" file, so it can't be run interactively			     


Both processors  MUST be (RFC 2119) the last proccesor that modifies the
contents of the page.

If you intend to use this in batch processing you will need
to unprotect your private PGP key or enter the passphrase in order
to sign all the pages.

FINAL

}
#HELP-START-END


sub PgpSign {
	
   my $var = $_[0];
   if (exists $$var{'pgpsign.cmdline'})  
   	{ $pgp = $$var{'pgpsign.cmdline'} ; }
   else { $pgp = $defpgpsign ; }

   if (exists $$var{'pgpsign.srcvar'}) { $wbbsrc= $$var{'pgpsign.srcvar'} ; }
   if (exists $$var{'pgpsign.dstvar'}) { $wbbdst= $$var{'pgpsign.dstvar'} ; }

   if (exists $$var{'pgpsign.msg'}) {$msg =$$var{'pgpsign.msg'} ; } 

   if (exists $$var{'pgpsign.msgvar'}) { $msgvar = $$var{'pgpsign.msgvar'} ; }


    debug 3,  "PgpSign::PGPSignDetach execution" ;
#
# cut &paste
#
$file= "/tmp/pgpfirma.$$" . $BASETIME ;

unlink $file if -r $file ; 

$i= $INPUT_RECORD_SEPARATOR ;
undef $INPUT_RECORD_SEPARATOR;

$mensaje= $$var{$wbbsrc} ;

my $rex = $expVAR1.$msgvar.$expVAR2;
 
$mensaje =~ s/$rex/$$var{$msgvar}/g;

open (SALIDA, ">$file") ;
print SALIDA  $mensaje ;
close SALIDA ;
my $mes ="" ;
open PGP , "$pgp < $file|" ;
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

sub PgpSignDetached {
	
   my $var = $_[0];

# Verificacion de interactivo
    if ($$var{'wbbInteractive'} eq "1") {
	debug (2, " CGI mode don't do anything") ;
	}
	else {
   if (exists $$var{'pgpsign.cmdline.detached'})  
   	{ $pgp = $$var{'pgpsign.cmdline.detached'} ; }
   else { $pgp = $defpgpsigndetach ; }

   if (exists $$var{'pgpsign.srcvar'}) { $wbbsrc= $$var{'pgpsign.srcvar'} ; }
   if (exists $$var{'pgpsign.dstvar'}) { $wbbdst= $$var{'pgpsign.dstvar'} ; }

   if (exists $$var{'pgpsign.msg.detached'}) {$msgdetach=$$var{'pgpsign.msg.detached'} ; }

   if (exists $$var{'pgpsign.msgvar'}) { $msgvardet = $$var{'pgpsign.msgvar'} ; }


    debug 3,  "PgpSign::pgpsign execution" ;
#
# cut &paste
#
$file= "/tmp/pgpfirma.$$" . $BASETIME ;

unlink $file if -r $file ; 

$i= $INPUT_RECORD_SEPARATOR ;
undef $INPUT_RECORD_SEPARATOR;

$mensaje= $$var{$wbbsrc} ;

my $rex = $expVAR1.$msgvardet.$expVAR2;
 
$mensaje =~ s/$rex/$$var{$msgdetach}/g;

open (SALIDA, ">$file") ;
print SALIDA  $mensaje ;
close SALIDA ;

system ( "$pgp  $file") ;
# detached signature has two parts the file to be read again in the var and the ".sig" to be copied
open PGP , $file ;
my $mes .= scalar (<PGP>) ;
close PGP ;
debug 3, "execution of  $pgp  $file" ;
unlink $file ;
$$var{$wbbdst} =  $mes ;
	debug 3, "message placed in $wbbdst was\n....\n$mes\....\n" ; 
# Now copy the file
copy ("$file.sig" , $$var{'wbbTarget'} . ".sig" ) ;
	debug 3, "copied $file.sig to $$var{'wbbTarget'}.sig " ;

unlink "$file.sig" ;

 $INPUT_RECORD_SEPARATOR = $i; 

}
}

#MAIN-INSERT-START

if ($0 =~ /$name/) { &help; die ("\n"); }

1;

#MAIN-INSERT-END

