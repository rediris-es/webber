#!/usr/bin/perl -w
#
# Modulo de funciones extras.
# 
# Un modulo webber con funciones "extra" que no tienen en principio que ver con el cometido principal
# de webber de hacer páginas HTML, pero que como estoy cansado de cambiar muchos la función de "debug"
# a mano pues me hago uno.

use strict ;

package ExtraProc;


my $name="ExtraProc" ;
my $version="1.0" ;


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







#-------------------------------------------------------------------------
# Function: info 
#-------------------------------------------------------------------------


sub info {
   print "$name v$version: Copy #wbbIn into #wbbOut\n";
}

#-------------------------------------------------------------------------
# Function: help
#-------------------------------------------------------------------------

sub help
{
   print <<FINAL

 Procesadores Extras Diversos, para uso con webber aunque no siguen el formato antiguo de diseño
de páginas WWW, sino que estan pensados para otras cosas.


Por ahora tiene solo uno inFileRplace , que lo que hace es:

 - Lee el fichero apuntado por wbbFile
 - Lee el fichero apuntado por ExtraProc.replacement, (file:) o directamente sino una veriable
 - Cambia la entrada ExtrProc.anchor (expresion regular por el contenido del fichero/valor
    de ExtraProc.replacement
 - Graba de nuevo el fichero wbbFile.

Pensado: porque la función debug cambia en los procesadores constantemente y es un follón
editar cada procesador para cambiar la información.

FINAL
}

# Codigo principal

if ($0 =~ /$name/) { &help; die ("\n"); }

1;

#-------------------------------------------------------------------------
# Function: inFileReplace
#-------------------------------------------------------------------------

sub inFileReplace {

	my $rv=$_[0] ;
	
	my $orig ;
	my $replacement ;
	my $anchor ;
	my $file ;
	my $filebak =".bak" ;
#	foreach my $key (keys %$rv) { print "Clave $key , valor .$$rv{$key}.\n" ;  }
	# Comprobaciones de que las variables estan Extraproc.replacement.
	if (defined $$rv{'ExtraProc.replacement'} ) {
		if ($$rv{'ExtraProc.replacement'} =~ /file:(.*)/) {
			$file = $1 ;
			print "file is $file\n" ;
			open FILE ,$file || die "Can't open file $file pointed in in ExtraProc.replacement!!\n" ;
			while (my $line=<FILE>) { $replacement.= $line ; }
			close FILE ;
			}
		else { $replacement = $$rv{'ExtraProc.replacement'} ; }
	}
	else { die "Webber var ExtraProc.replacement not defined !!\n" ;} 
	# cadena de ancla
	if (defined $$rv{'ExtraProc.anchor'}) { $anchor= $$rv{'ExtraProc.anchor'} ; }
	else {die "Webber var ExtraProc.anchor not defined !!! \n" ; }
	#fichero fuente
	$file=$$rv{'wbbSource'} ;
	open FILE, $file || die "Can't open file $$rv{'wbbSource'} , as pointed by wbbSource var!! \n" ;
	while (my $line=<FILE> ) { $orig .= $line ; }
	close FILE ;
	# Comprobamos que hay una extensión para el backup
	if (defined ($$rv{'ExtraProc.filebak'} ) ) { $filebak = $file . $filebak ;}
	else { $filebak= $file . $filebak ; } 

	# Antes de hacer la magia copiamos al bak
	open FILE , ">$filebak"  || die "Can't write backup file $filebak !!!\n" ;
	print FILE $orig ;
	close FILE ;

	# Se hace la magia
	print "anchor=$anchor\noriginal=\n========\nncodigo a reemplazar:\n$replacement\n" ;


	BEGIN {undef $/;}
	$orig =~ /$anchor/sm ;
	if (defined $1) { print "found $anchor =\n $1 " ; }		
	$orig =~ s/$anchor/$replacement/sm;
	# Se graba el fichero 
	open FILE, ">$file " || die "Can't write on $file !!\n" ;
	print FILE $orig ;
	close FILE ;
}

		
