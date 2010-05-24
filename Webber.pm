package Apache::Webber;
# File Apache/Webber ;
#
# Handler for using Webber inside Apache
#
# Primera versión de un modulo para la creación de contenidos en formato "Webber" que sean
# procesados dinamicamente dentro del apache, se contemplan cuatro supuestos, basados
# en la extension del fichero
#
# Codigo para webber "antiguo" en el sentido de estar "forzadas algunas variables,
# Nota, no procesa ficheros "wbbdir.cfg" 
# 1- Extensión wbb : Son ficheros "webber" normales, en formato webber
# 2- Extension wphp: Son ficheros PHP cuya salida esta en formato webber 
# 3- Extensión php : Ficheros PHP que hay que ejecutar y la salida "analizar"  
# 4- Extension html|htm: Paginas HTML normal.
#
# Para los casos 1 y 2 se procesa directamente la salida , se mete en un hash de valores
# y se pasa a la función "do_webber" que genera el wbb.
# Para los casos 3  y 4 Se "extrae" el "title" y el wbbIn de la pagina
# Para 1 y 4 se lee directamente el fichero y se procesa
# Para los casos 3 y 4 se emplea un modulo Perl que permite el acceso a PHP para asi poder
# la salida en PHP
#
# Funciones:
# * = implementada
# * handler: Es la que procesa la llamada del servidor WWW
# * html2wbb: Extrae el wbbIn y title de la pagina HTML/PHP
# * var2wbb: Genera un hash "webber" en base a una variable escalar
# * dowebber: Procesa el webber
# * readfile: Lee un fichero
# init_hash : Inicializa un hash con variables webber, basado en el Path del fichero
# * EvaluateVar : Auxiliar de var2wbb 
# * debug : Mensajes de depuración a un fichero
# init_webber: Inicialización de webber (debería ser más generico, se llama en el arranque
# del servidor solamente para así inicializar el hash de varialbles, usado por init_webber,
# path del fichero de debug, nivel de debug, etc, debería ser ma´s generico

use strict ;
use Apache2::Const qw(:common);
use Apache2::RequestRec ();
use Apache2::Log () ;

# PAra poder grabar con el debug ...
use APR::PerlIO() ;
use APR::Pool ;

#use Apache::File () ;

# Variable global , indica la configuracion de cada Web, gestionada por Webber.
# es un hash , path-base => hash_de_configuración donde cada "hash de configuración"
# son las variables webber y valores que deben aplicarse., La busqueda se realiza
# por las claves "ordenadas", de forma que las webs de
# /var/www/html/ y /var/www/html/test puedan ser distintas, se queda con el ultimo
# en machear.

my  %webbers;

my  $wbb_debugfile="/tmp/webber.txt" ;
my  $wbb_debuglevel=10 ;

my $r ;  
# r pool
my $inmodule=0 ;
# For PHP side
use PHP::Interpreter ;
# See http://cpan.uwinnipeg.ca/htdocs/PHP-Interpreter/PHP/Interpreter.html for usage of


####################
# Funciones
###################

sub readfile {
        my $file=$_[0] ; 
        open my $FILE,'<', $file or die $!;
         my $data = join"",<$FILE>;
         close($FILE);
        return $data ;
        }


sub html2wbb {
	my $rh= $_[0] ;
	my $html = $_[1] ;
	$html =~ /.*<title>(.*)<\/title>.*/msi ;
	$$rh{'title'} = $1 ;
	$html =~ /.*<body.*>(.*)<\/body>.*/msi ;
	$$rh{'wbbIn'} = $1 ;
	}

sub init_hash {

	my $path= $_[0] ;
	my $match ="" ;
	my %ret=();
	my $rh ;
	foreach my  $indice  (sort (keys %webbers )) {
		if ($path =~ /$indice/) { $match =$indice ;
		debug (3, "Found Webber configuration for $path, web $indice") ;
	}}

	if ($match eq "") {
		debug (1, "Error no webber configuration for $path") ;
	} else {
		 $rh=$webbers{$match}  ;
		foreach my $indice  (keys %$rh) { 
				debug(3, "Valor de variable $indice es $$rh{$indice}") ;
				$ret{$indice} = $$rh{$indice} ;
		}
	}
	return %ret ;
	}

sub var2wbb {
	my $ref= $_[0] ;
	my  $var= $_[1]  ;
   
   my $line ;
   my $lno = 0;
   my $varname = "" ;
   my @array= split /\n/, $var ; 
   for (my $i=0 ; $i!=@array ; $i++) {
	$line = $array[$i] ; 
      if ($line =~ /^##/) {
         if ($varname ne "") { debug (2, "Debug:(readVars) $varname := $$ref{$varname}\n")  ; }
         $varname = "";
      }
      elsif ($line =~ /^#([\w]+[a-zA-Z0-9_.\-\$]*)\s*\=\s*(.*)$/) {
         if ($varname ne "") { debug (2,"Debug:(readVars) Asignation $varname := $$ref{$varname}\n") ; }
         $$ref{"$1"} = EvaluateVar ($2, $ref );
         $varname = "$1";
      }
      elsif ($line =~ /^#([\w]+[a-zA-Z0-9_.\-\$]*)\s*\+\s*(.*)$/) {
         if ($varname ne "") { debug(2, "Debug:(readVars) Concatenation $varname := $$ref{$varname}\n") ; }
         if (exists $$ref{"$1"}) { $$ref{"$1"} .= " " . EvaluateVar($2, $ref) ; }
         else { $$ref{"$1"} = EvaluateVar ($2, $ref) ; }
         $varname = "$1";
      }
      elsif ($line =~ /^#([\w]+[a-zA-Z0-9_.\-\$]*)\s*\*\s*(.*)$/) {
         if ($varname ne "") { debug(2, "Debug:(readVars) Left Concatenation $varname := $$ref{$varname}\n") ; }
         if (exists $$ref{"$1"}) { $$ref{"$1"} = EvaluateVar($2, $ref) . " "  . $$ref{"$1"}; }
         else { $$ref{"$1"} = EvaluateVar ($2, $ref) ; }
         $varname = "$1";
      }
      else {
         if ($varname eq "") {
            chomp $line;
		# Ignore blank lines outside variable definitions without error
            if ($line !~ /^[\s]*$/) {
              debug (2,  "Syntax error in the loading of vars, line $i : \"$line\" ignored\n");
            }
         }
         else {
            chomp $line;
            $$ref{"$varname"} .= "\n" . EvaluateVar($line , $ref) ;
         }
      }
   }
   if ($varname ne "") { debug(2, "Debug:(readVars) $varname := $$ref{$varname}\n") ; } 
}

sub EvaluateVar  {
        my $lin = $_[0] ;
        my $ref = $_[1] ;
        my $c ;
        my %var ;
        debug (3, "Entrada en EvaluateVar con Line= $lin" ) ;

        while ($lin =~ /.*\$var\(([\w]+[a-zA-Z0-9_.\-]*)\).*/ ) {
                $c = $$ref{$1} ;
                $lin =~ s/\$var\($1\)/$c/ ;
        }
        while ($lin =~ /.*\$env\(([\w]+[a-zA-Z0-9_.\-]*)\).*/ ) {
                $c = $ENV{$1} ;
                $lin =~ s/\$env\($1\)/$c/ ;
        }
#        while ($lin =~ /.*\$orig\(([\w]+[a-zA-Z0-9_.\-]*)\).*/ ) {
#                $c = $wbbDef{$1} ;
#                $lin =~ s/\$orig\($1\)/$c/ ;
#        }

        debug (3, "Salida de EvalueateVar con Line =$lin") ; 
        return $lin ;
        }

#-------------------------------------------------------------------------
# Function: debug 
#-------------------------------------------------------------------------

sub set_debug {
	$wbb_debugfile=$_[0] ;
	$wbb_debuglevel=$_[1] ;
	}

sub debug {
        my @lines = @_ ;
        my $level = shift @lines ;
        if ($level <= $wbb_debuglevel ) {
        my $line= join '', @lines ;
        chomp $line ;
	my $fh ;
	if ($inmodule ) { $r->log_error($line) ; } 
	else {
        	open FILE, ">>" , $wbb_debugfile ;
		my $now= gmtime ;
         	print FILE  "[$now] $line\n" ;
        	close FILE ;
        	}
	}
}



sub dowebber {
        my $rh = $_[0] ;
	no strict 'refs' ;
my ($pre, $post, $proc) ;

 if( exists ($$rh{'wbbPre'})) {$pre= $$rh{'wbbPre'} ;  } else {$pre="" ; }
 if (exists ($$rh{'wbbProc'})) { $proc=$$rh{'wbbProc'} ; } else {$proc="" ; }
 if (exists ($$rh{'wbbPost'})) { $post=$$rh{'wbbPost'}; } else {$post="" ; }


   my @tempo ;

 my ($package, $sname)  ;

# Preprocessors ;

   my $thisp ;
   if ($pre ne "") {
      @tempo = split /\s+/, $pre;
      foreach $thisp (@tempo) {
         next unless $thisp =~ /\w+/ ;
         ($package, $sname) = split /::/,$thisp;
         require $package .".pm" ;
         &$thisp( $rh);
      }
   }
# Proccessors 

   if ($proc ne "") {
      @tempo = split /\s+/, $proc;
      foreach $thisp (@tempo) {
         next unless $thisp =~ /\w+/ ;
         ($package, $sname) = split /::/,$thisp;
         require $package . ".pm" ;
         &$thisp( $rh );
      }
   }
else  { $$rh{'wbbOut'} .= $$rh{'wbbIn'}; }

# Postproccessors 

   if ($post ne "") {
      @tempo = split /\s+/, $post;
      foreach $thisp (@tempo) {
         next unless $thisp=~ /\w+/ ;
         ($package, $sname) = split /::/,$thisp;
         require $package.".pm";
         &$thisp( $rh );
      }
   }

}

sub handler {
	$r= shift ;

	$inmodule=1 ;
# File check	
my $file= $r->filename() ;

$r->log_error ("Debug level is $wbb_debuglevel and file is $wbb_debugfile") ;

unless  ( ($file =~/\.wbb$/) || ($file=~ /\.php$/) || ($file=~/\.html$/) || ($file =~ /\.htm$/)) {
        $r->log_error("File $file is not used by this module") ;
        debug (2, "file $file extension not allowed for this module" ) ;
        return DECLINED ;
        }

unless (-e $file) {
	$r->log_error("File does not exists: $file") ;
	debug (2, "file $file not found" );
	return NOT_FOUND ;
	}

unless  (-r $file ) {
	$r->log_error("File Permissions deny access: $file") ;
	debug (2, "file $file can't access") ;
	return FORBIDDEN;
	}
#

my $string ;
my %hash = init_hash ($file) ;
my $phpout="" ;

my $phpinit = (  'OUTPUT' => \$phpout ) ;
if  ($file =~ /\.wbb$/ ) {
	var2wbb (\%hash, readfile($file) ) ;
	dowebber (\%hash) ; }
	
elsif ($file =~ /\.wphp$/) {
	my $p = PHP::Interpreter->new ( $phpinit) ;
#	my $phpcode= readfile ($file) ;
	my $phpcode ="print \"hola que tal \";  " ;
	$p->eval( $phpcode  ) ;
#	var2wbb (\%hash, $p->get_output) ;
	var2wbb (\%hash, $phpout) ;
	dowebber (\%hash) ;
	}
elsif ($file =~ /\.php$/) {
	my $php = PHP::Interpreter->new() ;
	my $old_handler = $php->set_output_handler(\$phpout);
	my $page=  readfile ($file) ;
	$page =~ /<?php(.*)\?>/msi ;
	my $phpcode = $1 ;
	$phpcode =" print \"hola mundo\" ; " ; 
	debug (2,"PHP se evalua $phpcode") ;
	my $output= $php->eval(" $phpcode\n")  ;
	my$outbuf = $php->get_output(); 
	debug (2,"output= $output , outbuf= $outbuf, phppout=$phpout");
	$page =~ s/<?php.*?>/$outbuf/msi ;
	html2wbb (\%hash, $page) ;
	dowebber (\%hash) ;
	}
elsif( ($file =~ /\.html$/) || ($file =~ /\.htm$/)) {
	html2wbb (\%hash , readfile ($file) );
	dowebber (\%hash) ;
}

## And now the output 
$r->content_type('text/html');
#$r->send_http_header ;
print($hash{'wbbOut'}) ;
return OK ;
}

## End of Module

sub init_webber { 
	my $path = $_[0] ;
	my $file= $_[1] ;
	
	my $string ="" ;
	my %hash= () ;
	var2wbb (\%hash, readfile ($file) ) ;
	$webbers{$path} = \%hash ;
	debug (2, "path $path tiene la configuración webber de $file") ;
	}

sub print_webs {
	foreach my $path (sort (keys %webbers) ) {
		debug (1, "$path -> ") ;
		my $rh= $webbers{$path} ;
		debug (1, "\t{\n") ;
		foreach my $var (keys %$rh ) { debug (1, "\t\t$var => $$rh{$var}\n") ; }
		debug (1, "\t}") ;
	}
}
1;
__END__


	
