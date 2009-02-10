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



my $name=	"FileLang";
my $version=	"1.2";

## No gusta pero lo veo más comodo que cargar uno por defecto y como es largo lo defino aqui, y lo
# meto despues en el defs.
my $langnames = <<FIN;
(       'es' =>  { 
                'es' => "Español",
                'en' => "Ingles",
                'de' => "Aleman",
                'fr' => "Frances",
                'gl' => "Gallego",
                'ca' => "Catalan o Valenciano",
                'eu' => "Vasco"
                },
        'en' =>  {
                'es' => "Spanish",
                'en' => "English",
                'de' => "German",
                'fr' => "Frech",
                'gl' => "Galician",
                'ca' => "Catalan, Valencian" ,
                'eu' => "Basque"
                }
)
FIN

sub info {
   print "$name v$version: Manipulate some webber vars based on ISO-3166 country code\n" ;
}

my %defs = (
	'language.changename' => "1" , 
	'language.detectpattern' => '(.+)\.(..)$' ,
	'language.writepattern' => '%N%E.%L' ,
	'language.default' => "es" ,
	'filelang.linkfix.vars' => "wbbOut" ,
	'filelang.linkfix.detectpattern' => '<a.*href.*=.*["\'](.*\.\w\w\.(?:php|html))["\']' ,
	'filelang.linksys.namepattern' => '(.*)\.(.*)\.(.*)$' ,
	'filelang.linkfix.newpattern' => '%1.%3.%2' ,
	'filelang.otherlang.var' => 'langmenu',
	'filelang.otherlang.pre' => "<table><tr>\n" , 
	'filelang.otherlang.post' =>"</tr></table>" ,
	'filelang.otherlang.template' => '<td><a href="%LINK"> %LANG </a></td>' 
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
"name.EXT" (by default). Be careful, when webbering , if you want to have only a language
version use "webber *es.wbb" and not "webber *.wbb" . Mote: for EXT is the value of wbbExtension

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

Useful to use with Webbo to have the same template for pages in different languages,
if the var "#filelang.langreduction.vars" is defined it will only process the vars
(space separated lists of vars to reduce, for example:
#filelang.langreduction.vars= title content 

Will reduce the title-es , title-en, content-fr, etc based on the #wbbLangCode

FileLang::OtherLang : Help processor to produce a "HTML menu list" of links
to ther language versions of the HTML page, it uses the following vars:

#filelang.otherlang.var: In which webber variable will be the output
#filelang.otherlang.pre : HTML code before the other Language section
#filelang.otherlang.post: HTML code after the other language section
#filelang.otherlang.template: HTML template, the "simbol "%%" will be replaced
with the code (ISO-CODE) of the file.



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
		 $$rv{'wbbLangname'} = code2language ($$rv{'language.default'} ) ;
		 $$rv{'wbbLang'} = $$rv{'language.default'} ;

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
			$$rv{'languaje.name'} =$1 ; 
			$lang=$2 ;
			#print STDERR "detectado lenguaje = $lang name=$name, pattern = $$rv{'language.detectpattern'} values $1, $2\n" ;
		}
		else {$name=$file ; }
		
		 $$rv{'wbbLangname'} = code2language ($lang) ;
		 $$rv{'wbbLang'} = $lang ;

	
		#Changing the name ?
		if (( $$rv{'language.changename'} eq "1") || ( $$rv{'language.changename'} eq "yes") ){
		#print STDERR  "Want to change the NAME = 1, name =$name, lang=$$rv{'wbbLang'} ($lang), pattern= $$rv{'language.writepattern'}\n" ; 
		my @dirs =  split  /\//, $$rv{'wbbTarget'}  ;
		pop (@dirs) ;
		my $newname=   $$rv{'language.writepattern'} ;
		$newname =~ s/%N/$name/ ;
		$newname =~ s/%L/$lang/ ;
		$newname =~ s/%E/$$rv{'wbbExtension'}/ ;
		debug (3, "Changing name from $$rv{'wbbTarget'}" ) ;	
		$$rv{'wbbTarget'} =  join ("/", @dirs)  . "/" . $newname ;				
		debug (3,"Changed to $$rv{'wbbTarget'}" ) ;
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
	if (defined $$rv{'wbbLang'} ) {
		if ( not defined $$rv{'filelang.langreduction.vars'} ) {
		foreach my $var (keys %$rv) {
			 debug (1,"FileLang::langreduction se ejecuta sobre todas las variables" ) ;
			if ($var =~ /(.+)-$$rv{'wbbLang'}/ ) { $$rv{$1} = $$rv{$var} } ; }
		}
		else {
		debug (1, "FileLang::langreduction se ejecuta sobre $$rv{'filelang.langreduction.vars'}" );
		foreach my $var (split /\s+/, $$rv{'filelang.langreduction.vars'}) {
			debug (3, "processing $var looking for $var\-$$rv{'wbbLang'}") ;
			if  (defined $$rv{"$var\-$$rv{'wbbLang'}"} ) 
					{ debug (2,"Encontrada variable $var\-$$rv{'wbbLang'} reducida a $var") ;
					 $$rv{$var} = $$rv{"$var-$$rv{'wbbLang'}"};   }
			}
		}
	}
	else { debug (1,"FileLang::langreduction llamado, pero wbbLang no esta definido!!, do nothing") ;} 
}
	

sub otherlang {
	my $rv = shift ;
	my $msg ="" ;
	if (defined $$rv{'wbbLang'} ) {
		debug (1, "FileLang::otherlang is called , language of the page  is $$rv{'wbbLang'} !!" ) ;
		my $lang=$$rv{'wbbLang'} ;
		$$rv{'filelang.otherlang.template'} = $defs{'filelang.otherlang.template'} unless defined ($$rv{'filelang.otherlang.template'}) ;
		$$rv{'filelang.otherlang.pre'} = $defs{'filelang.otherlang.pre'} unless defined ($$rv{'filelang.otherlang.pre'}) ;
		$$rv{'filelang.otherlang.post'} = $defs{'filelang.otherlang.post'} unless defined ($$rv{'filelang.otherlang.post'}) ;

		# Por defecto vamos a tener un Langhash, pero por si se proporciona otro
		my %langhash = (defined ($$rv{'filelang.langhash'} )) ? eval ($$rv{'filelang.langhash'}) : eval $langnames ;
		my $rlh = $langhash{$lang} ;
		# No tengo ganas de pensar mucho hoy, esto seguramente se reescribirá pronto, FJMC 
		# $$rv{'wbbSource'}  contiene el fichero fuente, path incluido y por ahora
		# la extension finalizadora es wbb
		$$rv{'wbbSource'} =~ /(.*)\.(..)\.wbb/ ;
		my $filebase=$1 ;
		my @tmp = split /\//, $filebase ;
		my $base = pop @tmp ;
		foreach my $la (sort keys %$rlh) { 
			if (-r "$filebase.$la.wbb" ) {  debug (1,"Found lang file $filebase.$la.wbb !!") ;
							my $cad= $$rv{'filelang.otherlang.template'} ;
							debug (2, "Languaje template is $cad" ) ;
							$cad =~ s/%LANG/$$rlh{$la}/ ;
							$cad =~ s/%CODE/$la/ ;
							$cad =~ s/%LINK/$base$$rv{'wbbExtension'}.$la/g ;
							debug (3,"Result is $cad") ; 
							$msg .= $cad ; 
							}
		}
		$msg = $$rv{'filelang.otherlang.pre'} . $msg . $$rv{'filelang.otherlang.post'} ;
		$$rv{$$rv{'filelang.otherlang.var'}} = $msg ;
		debug (3, "Generado otherlang line in variable *$$rv{'filelang.otherlang.var'}* , value:\n<--->$$rv{$$rv{'filelang.otherlang.var'}}<--->\n" ) ;
		
			
	}
	else { debug( 1, "FileLang::otherlang called , but wbbLang not defined!!") ; }
}

sub linkfix  { 
	my $rv= shift ;
	my $banner= "$name\:\:linkfix : " ;
	#$$rv{'wbbDebug'} =10 ;
	my $count=0 ;
	debug (1, "$banner se ejecuta") ;
	my $vars = defined ($$rv{'filelang.linkfix.vars'}) ? $$rv{'filelang.linkfix.vars'} : $defs{'filelang.linkfix.vars'} ;
	my $regex= defined ($$rv{'filelang.linkfix.detectpattern'}) ? $$rv{'filelang.linkfix.detectpattern'} : $defs{'filelang.linkfix.detectpattern'} ;
	my $regexfilename=  defined ($$rv{'filelang.linksys.namepattern'}) ? $$rv{'filelang.linksys.namepattern'} : $defs{'filelang.linksys.namepattern'} ;
	my $new= defined ($$rv{'filelang.linkfix.newpattern'} ) ? $$rv{'filelang.linkfix.newpattern'} : $defs{'filelang.linkfix.newpattern'} ; 
	debug (1, "$banner processing vars $vars") ;
#	print STDERR "$banner proccessing vars $vars\n" ;
#	print STDERR "Se ejecuta $banner con $vars\n" ;
	foreach my $var (split /\s+/, $vars)  {
		my $txt= $$rv{$var} ;
		debug (2, "processing var $var") ;
#		debug (0, "LINKFIX=\n$txt" ) ;
#		return ;
#		print  STDERR "$banner processing var $var\n" ;
		while ($txt =~ /$regex/ ) {
			my $filename= $1;
 #                       print STDERR "Name $filename detectado con $regex\n" ;
			if ($filename =~ /\/home\/spool\/WWW\/repositorio\/WWW.pre\// ) { $filename =~ s/\/home\/spool\/WWW\/repositorio\/WWW.pre\/// ; }
			$filename =~ /$regexfilename/ ;
                        my $uno=$1 ;
                        my $dos=$2 ;
                        my $tres=$3 ;
              #ESTE          print STDERR "filename= $filename regex= $regexfilename uno=$uno dos =$dos tres=$tres\n" ;
			my $newname = $new ;
			$newname =~ s/\%1/$uno/ ; 
			$newname =~ s/\%2/$dos/ ;
			$newname =~ s/\%3/$tres/ ;
			debug (1,"LINKFIX: Cambiado en $$rv{'wbbSource'} en variable $var valor $filename por $newname") ;
		#ESTE	print "LINKFIX: Cambiado en $$rv{'wbbSource'} en variable $var valor $filename por $newname\n" ;
			$txt=~ s/$filename/$newname/ ;
			$count++ ;
			}
#		print STDERR "$banner links correguidos en $$rv{'wbbSource'} = $count\n" ;
		debug (1," $banner links correguidos en $$rv{'wbbSoruce'} var $var = $count\n") ; 
		$$rv{$var} = $txt ; 
		}

}


if ($0 =~ /$name/) { &help; die ("\n"); }
1;
