#!/usr/bin/perl
#
# Webber processor for managing Languages
#

package FileLang;

use Locale::Language;
require HTML::LinkExtor;
use strict ;
no strict "subs" ;
	
#-------------------------------------------------------------------------
# Function: debug 
#-------------------------------------------------------------------------
sub debug {
        my @lines = @_ ;
        my $level = shift @lines ;
 	if (defined (&wbbdebug)) { wbbdebug (@lines) ; }
        elsif (defined main::debug) { main::debug (@lines) ; }
        else {
        my $line= join '', @lines ;
        chomp $line ;
        print STDERR "$line\n" ;
        }
        }
# End Funcion debug



my $name=	"FileLang";
my $version=	"1.0";

sub info {
   print "$name v$version: Manipulate some webber vars based on ISO-3166 country code\n" ;
}

my %defs = (
	'language.changename' => "1" , 
	'language.detectpattern' => '(.+)\.(..)$' ,
	'language.writepattern' => '%N.html.%L' ,
	'language.default' => "es" ,
	) ;

sub help
{
   print <<FINAL
$name 

Webber processor, version $version
This program must run inside Webber.

FileLang::filelang

This function tried to set some webber variables  based in the
source file 

$name must be one of the first processors.

$name sets/modified the following variables:

#year : Year in which the program is executed
#wbbDateMeta: Last modified date of the source file
#wbbDateWeb: Time in which the page is beeing produced
#wbbLang: Language of the file (based on the ISO 639)
(se below), if language can not be determined, it would be
set to #language.default (def= $defs{'language.default'})

For the language there are two variables:
#language.changename def= $defs{'language.changename'}
#language.writepattern def= $defs{'language.writepattern'} 
#language.detectpattern def= $defs{'language.detectpattern'}

that can be used to control the wbbTarget Filename, as follows.

the filenmame would be check against #language.detectpattern,
if language can be detected, wbbLang would be set to the 
the ISO 639 country code, otherwise it would be set to 
#language.default ($defs{'language.default'})

if #language.changename is set and value is not "equal" to  "nolang", then it would change the 
filename, according to #language.writepattern   this can be used,
for storing  language specific files as name.CC.wbb in the source and
change the filenames to name.html.CC, that can be used with
internationalized web servers

if  #language.changename  is set to "nolang", the processor will remove th "lang" from the name
of a file, so if the original file is "name.CC.wbb", webber will change the name to
"name.html" (by default). Be careful, when webbering , if you want to have only a language
version use "webber *es.wbb" and not "webber *.wbb" . Mote: for the HTML extension will
use wbbExtension 

Usage: incorporate Filelang::filelang to the list of proccessors
at the beginning of them.

Webber variables modified by the fucntion

#wbbDateMeta date of the web page
#wbbDateWeb  idem ?
wbbLang	Spanish, English, ISO name
#wbbLangcode es, en , ISO-CODE
#year

can also modify
#wbbTarget (output filename)

FileLang::langreduction {

Based on #wbbLangCode (if not defined it will not do anything), reduce the name
of some vars, so for example if you have two vars:
#content-es 
#content-en

will create #content based in the #wbblangcode var

Useful to use with Webbo to have the same template for pages in different languages


FINAL
}


sub filelang {

	my $rv = $_[0]  ;

	#print STDERR "\n-------\nFileLang, llegamos aqui src= $$rv{'wbbActualfile'} dst=$$rv{'wbbTarget'} \n " ;

#	foreach my $k ( keys %defs) { print STDERR "clave=$k, valor =$defs{$k}\n" ;}

	$$rv{'language.changename'}    = defined ($$rv{'language.changename'})    ? $$rv{'language.changename'}     : $defs{'language.changename'} ;
	$$rv{'language.writepattern'}  = defined ($$rv{'language.writepattern'})  ? $$rv{'language.writepattern'}   : $defs{'language.writepattern'} ;
	$$rv{'language.detectpattern'} = defined ($$rv{'language.detectpattern'}) ? $$rv{'language.detectpattern'}  : $defs{'language.detectpattern'} ;
	$$rv{'language.default'} =       defined ($$rv{'language.default'})       ? $$rv{'language.default'}        : $defs{'language.default'} ;

	$$rv{'year'} =  1900 + ((localtime)[5] > 50 ? (localtime)[5] : 100 + (localtime)[5]); 
		

	if (defined ($$rv{'wbbInteractive'}) &&  (( $$rv{'wbbInteractive'} ne "0" ) || ( $$rv{'wbbInteractive'} ne "no"))  ) {
		# Interactive mode not doing so much
		 $$rv{"wbbDateMeta"} = POSIX::strftime ("%Y-%m-%d", localtime);
   		 $$rv{"wbbDateWeb"}  = POSIX::strftime ("%d/%m/%Y", localtime);
		 $$rv{'wbbLang'} = code2language ($$rv{'language.default'} ) ;
		 $$rv{'wbbLangcode'} = $$rv{'language.default'} ;

		}

	else   {  #We have a filename
		# Info for the Filename
		my ($file,$n,$lang, $name) ;
		 my (@stats) = stat  $$rv{'wbbActualfile'} ;
      		$$rv{"wbbDateMeta"} = POSIX::strftime ("%Y-%m-%d", localtime ($stats[9]));
     		$$rv{"wbbDateWeb"}  = POSIX::strftime ("%d/%m/%Y", localtime ($stats[9]));
  
		#Information for the language 
		$lang= $$rv{'language.default'} ; 
		my @dirs =   split  /\//, $$rv{'wbbActualfile'}  ;
		$file = pop (@dirs) ;
		#print STDERR "before regex file=$file\n" ;
		$file =~ /$$rv{'wbbFileNameRegExp'}/ ; 
		$file = $1 ;
		#print STDERR "After regex file=$file pangpattern=$$rv{'language.detectpattern'}\n" ;
	
		if ($file =~ /$$rv{'language.detectpattern'}/) {
			$name=$1 ;
			$lang=$2 ;
			#print STDERR "detectado lenguaje = $lang name=$name, pattern = $$rv{'language.detectpattern'} values $1, $2\n" ;
		}
		else {$name=$file ; }
		
		 $$rv{'wbbLang'} = code2language ($lang) ;
		 $$rv{'wbbLangcode'} = $lang ;

	
		#Changing the name ?
		if (( $$rv{'language.changename'} eq "1") || ( $$rv{'language.changename'} eq "yes") ){
		#print STDERR  "Want to change the NAME = 1, name =$name, lang=$$rv{'wbbLang'} ($lang), pattern= $$rv{'language.writepattern'}\n" ; 
		my @dirs =  split  /\//, $$rv{'wbbTarget'}  ;
		pop (@dirs) ;
		my $newname=   $$rv{'language.writepattern'} ;
		$newname =~ s/%N/$name/ ;
		$newname =~ s/%L/$lang/ ;
			
		$$rv{'wbbTarget'} =  join ("/", @dirs)  . "/" . $newname ;				
		}
		elsif (($$rv{'language.changename'} eq "noext") ) {
		my @dirs =  split  /\//, $$rv{'wbbTarget'}  ;
		pop (@dirs) ;
		 $$rv{'wbbTarget'} =  join ("/", @dirs)  . "/" .  $name .  $$rv{'wbbExtension'} ; 
		}	
		
	}
  	debug (1, "FileLang end,   filename= $$rv{'wbbActualfile'}") ;
        debug (1, "FileLang end  target = $$rv{'wbbTarget'}}") ;
	        #print STDERR "FileLang, salimos aqui src= $$rv{'wbbActualfile'} dst=$$rv{'wbbTarget'} \n " ;
}


sub langreduction {
	my $rv = shift ;
	
	if (defined $$rv{'wbbLangcode'} ) {
		foreach my $var (keys %$rv) {
			if ($var =~ /(.+)-$$rv{'wbbLangcode'}/ ) { $$rv{$1} = $$rv{$var} } ; }
	}

}
	


if ($0 =~ /$name/) { &help; die ("\n"); }
1;
