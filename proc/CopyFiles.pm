#!/usr/bin/perl
#
# 
# Please customize this body proccessor as you like
# this is only an automatic template.
#
package CopyFiles ;

my $name ="CopyFiles" ;
my $version= "0.4" ;

use File::Copy ; 
use File::Basename ;
use File::Path ;
use File::Find;
use File::Spec;
require HTML::LinkExtor;
use POSIX ;
use strict ;


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





my ($wbbDebug, $wbbSourceRoot, $wbbTargetRoot) ;
my $var ;
my $allowed_ext="avi|cfg|conf|doc|gif|gz|jpeg|jpg|lst|mpg|mpeg|odt|pdf|pem|png|txt|xls|zip";
my $parseVar = 'wbbOut';
my $fileList = "";
my $dirList = "";


# Este es de ejemplo, se puede eliminar despues.
#
my $codigo=<<FIN;

Codigo de prueba para ver si con parser funciona

 requisitos segun Tomas.

        1. Las referencias externas no se copian, 
        es decir <a href="http://www.rediris.es">no se copia</a>
        2. Las referencias absolutas "/icono" tampoco
        3. Por lo que se solo se copia
                <a href="fichero.ext">lo uqe sea </a>
                y 
                <img src="../fichero.ext">
                
                Pero no se copia
                <a href="/imagen.ext"> imagen </a>
        
        pero si que se copiu <a href="loquesea/demas.ext"> adaa</a>

        Ninguna de estas extensiones se deberían copiar, sin embargo
                <a href="loquesea.avi"> este avi</a>
        y claro , esta imagen <img src="uno.png"> si que deberían 
        ir al modo "copia"
        
        Por que se comprueban las extensiones ?
                Porque podría pasar que 
        <a href="pulsa_aqui.html"> se copiase ...
        
FIN


#---------Info subrutine---------------------------------
sub info {
  print "$name v$version: CopyFiles between src &dst dir
" ;
}

#--------Help subrutine-----------------------------------
sub help {
 print <<FINAL;

 Este módulo copia los ficheros que aparecen en la página
 (estan en la variable definida por CopyFiles.parse) al directorio
 destino, siempre y cuando:
 - Sean de distinto tamaño
 - Tengan una extensión que se encuentre dento de la variable CopyFiles.ext
 
 El valor por defecto de CopyFiles.ext es
 $allowed_ext
 Y el de CopyFiles.parse es $parseVar

 Tambien copia todos los ficheros que aparezcan referenciados
 en la variable CopyFiles.files, siempre que sean mas recientes que
 los que se encuentren en el directorio destino.

 Tambien se copian, recursiva e incondicionalmente, los directorios
 que se referencien en la variale CopyFiles.dirs

 Por defecto, tanto CopyFiles.files como CopyFiles.dirs estan vacias 

FINAL
}

#-------Webber proccessors -------------

sub do_cpfile {
 my $fn = shift;
 my ($origen, $destino, $mtime_origen, $mtime_destino) ;
my $fullpath=0 ;
my $relpath ;
if   ($fn =~ /^\//)  {
		($origen , $relpath) = split /:/,  $fn ; 
		$fullpath=1 ;  } 
else {  $origen= getcwd() ."/$fn" ; }

 if (($mtime_origen =(stat($origen))[9])== NULL) {
  debug (0, "Error NO existe fichero $fn");
  return;
 }
if ( $fullpath == 1)  {  $destino = getcwd() . "/$relpath" . basename ($origen) ;  }
	else {    $destino = $origen ; }
 $destino =~  s/^$wbbSourceRoot/$wbbTargetRoot/ ;
 debug (1, "debug origen = $origen    dst=$destino") ;
 if (($mtime_destino=(stat ($destino))[9]) !=NULL) {
	debug (1,"debug origen=$mtime_origen, destino=$mtime_destino");
  if ($mtime_origen > $mtime_destino) { 
   ## COPIAR , origen, $DESTINo) ; 
    debug (1, "copy ($origen,$destino)")  ;
#   print STDERR "do_cpfile 1 copy $origen -> $destino\n" ;
   copy ($origen,$destino) ;
  }
 } 
 else {
  my $ruta_destino=(fileparse($destino))[1]  ;
  if (!-d $ruta_destino) { mkpath ($ruta_destino,0,0755) ; }
  ## copiar , $origen, destino
  debug (1, "copy ($origen, $destino)") ;
#   print STDERR "do_cpfile 2 copy $origen -> $destino\n" ;
  copy ($origen,$destino) ;
 }
}


sub do_work 
{

  my($tag, %links) = @_;
  
  if (($tag eq "img") || ($tag eq "a") || ($tag eq "iframe"))
  {
    my $file =${[%links]}[1] ;
    if ($file =~ /^(\/|ftp|http|https|mail|):\/\//) 
    {
       # esto debería quitar paso 1 y 2 
       debug (1, "$file es url absoluta, no se copia") ;
       return ; 
    }

    if ($file =~ /^\//) 
    {
      # No se porque esto no lo pilla antes
      debug (1, "$file es ruta absoluta, no se copia");
      return ;  
    }          

    debug (1, "$file es relativa es posible que se copie"); 

    if ($file =~ /#/) 
    { 
      # Si lleva a una marca interna de página web
     debug (1, "$file es una marca HTML, no se copia") ;
      return; 
    }

    # OK ahora hay que comprobar que acaba en ext permitida
    if ( $file  =~ /.*\.($allowed_ext)$/ )
    {
      debug (1, "Ademas $file tiene una extension permitida !!")  ;
      do_cpfile ($file);    
    }
    else 
    {
      ## Si el fichero es html o no acaba en "\/"  no pintamos el error
      if  ( ($file =~ /.*\.html$/) || ($file =~ /.*\/$/)) {
      }
      else {
       debug (1, "skip: $file no tiene una extension reconocida") ;
      }
    }
  }
}


sub copyfiles  {
 my $lin="" ;
 $var = $_[0] ;
 if (defined ($$var{'wbbInteractive'}) && ($$var{'wbbInteractive'} eq "1")) {
	debug (2, " CGI mode don't do anything") ;
	}
else {
 debug (3, STDERR "procesing $$var{'wbbSource'}\n" ) ;
 $wbbDebug = $$var{'wbbDebug'} ;
 $wbbSourceRoot= $$var{'wbbSourceRoot'} ;
 $wbbTargetRoot= $$var{'wbbTargetRoot'} ;

 $lin = "<!-- Webber proc $name v$version -->";

#----- Gets the values for the variables
 $allowed_ext = $$var{'CopyFiles.ext'} if (exists $$var{'CopyFiles.ext'});
 $parseVar = $$var{'CopyFiles.parse'} if (exists $$var{'CopyFiles.parse'});
 $fileList = $$var{'CopyFiles.files'} if (exists $$var{'CopyFiles.files'});
 $dirList = $$var{'CopyFiles.dirs'} if (exists $$var{'CopyFiles.dirs'});

 debug (2, " ..extensiones que se copiaran $allowed_ext") ; 
 debug (2, " ..desde la variable Webber $parseVar");

 for my $d (split /[\s]+/, $dirList) {
  my $org = getcwd() ."/$d" ;
  my $dst = $org;
  $dst =~  s/^$wbbSourceRoot/$wbbTargetRoot/ ;
  if (-d $org) {
#   print STDERR "CopyFiles: /bin/cp -Rp $org $dst\n" if ($wbbDebug);
#   system("/bin/cp -Rp $org $dst");

   debug (1, "CopyFiles: wbbCopyDir $org, $dst");;
   wbbCopyDir ($org, $dst);

   if ($? == -1) {
    debug (1, "CopyFiles: System copy failed for $org: $!");
   }
  }
 }
 for my $f (split /[\s]+/, $fileList) {
 debug (3 , "going to copy $f") ;
  do_cpfile($f);
 }
 my $p = HTML::LinkExtor->new(\&do_work, "");
 $p->parse($$var{$parseVar}) ;

}
}

#----------------------------------------------------------------------
# wbbCopyRecursive
#----------------------------------------------------------------------
sub wbbCopyRecursive(&@) {
    my ($code, $src, $dst) = @_;
    print STDERR "wbbCopyRecursive code=$code src=$src dst=$dst\n" ;
    my @src = File::Spec->splitdir($src);
    pop @src unless defined $src[$#src] and $src[$#src] ne '';
    my $src_level = @src;
    find({ wanted => sub {
               my @src = File::Spec->splitdir($File::Find::name);
               my $from = File::Spec->catfile($src, @src[$src_level .. $#src]);
               my $to = File::Spec->catfile($dst, @src[$src_level .. $#src]);
               $code->($from, $to);
           },
           no_chdir => 1,
         },
         $src,
        );
}

#----------------------------------------------------------------------
# wbbCopyDir
#----------------------------------------------------------------------
sub wbbCopyDir {
    wbbCopyRecursive { -d $_[0] ? do { mkdir($_[1]) unless -d $_[1] } : debug (3, "wbbCopyDir $_[0] -> $_[1]\n") ;  copy(@_) } @_;
}
  

#---------- Main program -----------------
if ($0 =~ /$name/) { 
  &help; 
#  do_work ($codigo) ;
    die ("
"); }

# Compliance with the standard modules 
1;
