#!/usr/bin/perl
#
# Webber processor for Handling Files, 
# 
# This processsor is "MUST" if you want to don't break compatibility with the
# old webber System
#


package File;

use File::Path ;

use Cwd;
use strict ;

my $name=       "File";
my $version=    "1.0";


## Funciones auxiliares

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





#----------------------------------------------------------------------
# Function: untaint
#----------------------------------------------------------------------
sub untaint {
   my ($arg) = @_;
   $arg =~ m/^(.*)$/;
   return $1;
}




#### Main 
sub info {
   print "$name v$version: File I/O : Mimic the original Webber I/O\n";
}

sub help
{
   print <<FINAL
$name 

Webber processor, version $version
This program must run inside Webber.
This is  the BASIC webber processor, as it provides the I/O fucnctions to do something
after reading the basic configuration

Provides the following Processors.

WriteVar:  writes the content of a webber variable (pointed bt File.WriteVar)
to a file pointed by  wbbTarget varible.

File::WriteVar uses the following Webber variables:
 #File.WriteVar: Is the variable to be written (defaults to wbbOut)
 #wbbTarget: Filename (path included)
 #wbbexttmp: Extensión temporal de los ficheros
 #wbbTargetFileMode:  File mode (UNIX octal permisssions)

ReadVars: Read Webber Vars from a file , add all the vars read to the webber Vars

File::ReadVars uses the following Webber variable:
  wbbSource: Filename to read 
 
FINAL
}

sub SetTarget {


	my $refvar=$_[0] ; ; 


#----
   debug 2, "Setting de target,  file= $$refvar{'wbbSource'} \n" ;   
   debug 2, "wbbTargetRoot is $$refvar{'wbbTargetRoot'}\n" ;
   
  # No se para que cojones era el wbbTarget, asi que lo pongo a un valor simbolico, ya que despues se camiba
	$$refvar{'wbbTarget'} = $$refvar{'wbbSource'} . $$refvar{'wbbExtension'}  unless (defined ($$refvar{'wbbTarget'} ));
  
   my ($name, $lang);
   if (! ((defined $$refvar{'wbbInteractive'}) && ( $$refvar{'wbbInteractive'}  eq "1")  )) {
      if ($$refvar{'wbbSource'} =~ /$$refvar{'wbbFileNameRegExp' }/) { $name = $1; }
      else { $name = $$refvar{'wbbSource'}; }
      
      $$refvar{"wbbTargetName"} = $$refvar{"wbbTarget"}.$$refvar{"wbbExtension"};
 # Esto nunca se produce     $$refvar{"wbbTarget"} =~ s/\.$lang$// if ($lang ne "");
   }

   $$refvar{"wbbIn"}="" if !exists $$refvar{"wbbIn"};
    
   ((-f "$$refvar{'wbbSource'}") ||  (defined $$refvar{'wbbInteractive'} && ( $$refvar{'wbbInteractive'}  eq "1") )) || die "No such page $$refvar{'wbbSource'}.\n";

   my (@stats) = stat ($$refvar{'wbbSource'}) ;

  ## Y esto es lo que se quita (ahora sería File::ReadVars &readVars ($page, "source file", \%var) unless (defined $var{'wbbInteractive'} && ( $var{'wbbInteractive'}  eq "1")) ;

   my $target ;
   if ($$refvar{'wbbTargetRoot'} =~ /absolutePath:\s*(.*)/) {
	$target =$1 ; 
	debug 1, "absolutepath targetroot =$$refvar{'wbbTargetRoot'}" ;		
	}
   else {
	 $target = getcwd();
	 $$refvar{'wbbSourceRoot'} = NormalizePath ($$refvar{'wbbSourceRoot'} ) ;
	 $$refvar{'wbbTargetRoot'} = NormalizePath ($$refvar{'wbbTargetRoot'}) ;
	my $base = $$refvar{'wbbSource'}  ;
	if (defined ( $$refvar{'wbbSourceRoot'} )) {  $base=~ s/$$refvar{'wbbSourceRoot'}// ;  }
	else { $base = "" ; } 
	if ($target =~ /.*$$refvar{'wbbSourceRoot'}.*/ ) {
         		$target =~ s/^$$refvar{'wbbSourceRoot'}/$$refvar{'wbbTargetRoot'}/;
			}
	else {
	        debug 0, "NOTICE: Webbering file outside wbbSourcePath, Setting target to: root wbTargetRoot" ;
 		my @temp = split /\//, $target ;
		my $target = $base  . "/" . pop @temp ; 
		debug 1, " target is $target" ;
	}
	}
   
  
   if  (($$refvar{'wbbMakedir'} == 1  ) and  (not -d $target))
   {
    debug (1,"creating path $target") ;
     mkpath ( untaint("$target") ,0,0755) ;
   }
	else{ debug 1, " no se cumple condicion  Path don't exists and wbbMakedir= $$refvar{'wbbMakedir'} " ;}

  if (not -d $target ) { 		debug 0,  " ojo con -d target $target"; }

   $target .= "/$name$$refvar{'wbbExtension'}";
    
   if (($$refvar{'wbbForceupdate'} ==0 )and (my $targetdate = (stat "$target")[9] )) {
      if ($stats[9]<=$targetdate) {
         print STDERR "$target is more recent than $$refvar{'wbbSource'}. Skipping\n";
	 $$refvar{'wbbEnd'} = "1" ;
         return;
      }
   }
 
   if  (( defined $$refvar{'wbbInteractive'}) && ( $$refvar{'wbbInteractive'}  eq "1") ) {
#      chmod 0644, untaint ("$target");
#      unlink (untaint ("$target"));
	 }

	else {
       
      debug (1,"Debug:(process) Target File is " . untaint ($target . $$refvar{'wbbexttmp'}) ) ;

	$$refvar{'wbbActualFile'} = $$refvar{'wbbSource'} ;	
  	$$refvar{'wbbTarget'} =  untaint ($target ) ;  # NOTA Seguramente esto debería ser "depraced" 
	$$refvar{'wbbTargetRelative'} = $$refvar{'wbbTarget'} ;
	$$refvar{'wbbTargetRelative'} =~ s/$$refvar{'wbbTargetRoot'}// ;

   }
	
}
sub WriteVar  
{

  my $refvar =$_[0] ;
    my $outvar="wbbOut" ;
   if (defined $$refvar{'File::WriteVar'} ) { $outvar=$$refvar{'File.WriteVar'} ; }

   debug (3, "Output file is $$refvar{'wbbTarget'} and output content is defined in variable $outvar\n" );	
 
  open  FILE  , ">" . untaint($$refvar{'wbbTarget'} . $$refvar{'wbbexttmp'} ) || die "Can't write to $$refvar{'wbbtarget'}.$$refvar{'wbbexttmp'}\n" ;
    print FILE   $$refvar{$outvar}  ;
    
    debug (5, "Content of $outvar is $$refvar{$outvar}") ;
    debug (2, "$outvar  written in $$refvar{'wbbTarget'}$$refvar{'wbbexttmp'} " ) ;
   close (FILE);
# Now the move
   unlink $$refvar{'wbbTarget'}  if -e  $$refvar{'wbbTarget'}   ;
   rename $$refvar{'wbbTarget'}  . $$refvar{'wbbexttmp'} , $$refvar{'wbbTarget'}  ;
   debug (2,"file  $$refvar{'wbbTarget'}$$refvar{'wbbexttmp'}  renamed to  $$refvar{'wbbTarget'} ") ;
   chmod oct $$refvar{"wbbTargetFileMode"}, untaint ($$refvar{'wbbTarget'} );

}

if ($0 =~ /$name/) { &help; die ("\n"); }

sub ReadVars {
	my $refvar =$_[0] ;
	my $file =$$refvar{'wbbSource'} ;
   my $target=  getcwd() ."/$file" ; 

    open INFILE,"<". untaint ("$file") ; 
   my $lno = 0;
   my $varname = "" ;
   debug (1,"  File::ReadVarsreadVars processing file $target\n" ) ;
   $$refvar{'wbbActualfile'} = $target ;
   while (my $line = <INFILE>) {
      if ($line =~ /^##/) {
	 if ($varname ne "") { debug (2, "Debug:(readVars) $varname := $$refvar{$varname}\n")  ; }
         $varname = "";
      }
      elsif ($line =~ /^#([\w]+[a-zA-Z0-9_.\-\$]*)\s*\=\s*(.*)$/) {
	 if ($varname ne "") { debug (2,"Debug:(readVars) $varname := $$refvar{$varname}\n") ; }
         $$refvar{"$1"} = EvaluateVar ($2, $refvar );
         $varname = "$1";
      }
      elsif ($line =~ /^#([\w]+[a-zA-Z0-9_.\-\$]*)\s*\+\s*(.*)$/) {
	 if ($varname ne "") { debug(2, "Debug:(readVars) $varname := $$refvar{$varname}\n") ; }
         if (exists $$refvar{"$1"}) { $$refvar{"$1"} .= " " . EvaluateVar($2, $refvar) ; }
         else { $$refvar{"$1"} = EvaluateVar ($2, $refvar) ; }
         $varname = "$1";
      }
      elsif ($line =~ /^#([\w]+[a-zA-Z0-9_.\-\$]*)\s*\*\s*(.*)$/) {
	 if ($varname ne "") { debug(2, "Debug:(readVars) $varname := $$refvar{$varname}\n") ; }
         if (exists $$refvar{"$1"}) { $$refvar{"$1"} = EvaluateVar($2, $refvar) . " "  . $$refvar{"$1"}; }
         else { $$refvar{"$1"} = EvaluateVar ($2, $refvar) ; }
         $varname = "$1";
      }
      else {
         if ($varname eq "") {
            chop $line;
# Ignore blank lines outside variable definitions without error
            if ($line !~ /^[\s]*$/) {
              print STDERR "Syntax error in $target: \"$line\" ignored\n";
            }
         }
         else {
            my $lc = chop $line;
            $line .=  $lc if (ord($lc) ne 10); # Si no es un \n
            $$refvar{"$varname"} .= "\n" . EvaluateVar($line , $refvar) ;
         }
      }
   }
   if ($varname ne "") { debug(2, "Debug:(readVars) $varname := $$refvar{$varname}\n") ; } 
   close INFILE;
}


#-------------------------------------------------------------------------
# Function: EvaluateVar
# ------------------------------------------------------------------------
sub EvaluateVar  {
        my $lin = $_[0] ;
	my $ref = $_[1] ;
	my $c ;
        while ($lin =~ /.*\$var\(([\w]+[a-zA-Z0-9_.\-]*)\).*/ ) {
		$c = $$ref{$1} ;
		debug (2, "Var $1 evaluada, valor =$c") ;
                $lin =~ s/\$var\($1\)/$c/ ;
        }
	while ($lin =~ /.*\$env\(([\w]+[a-zA-Z0-9_.\-]*)\).*/ ) {
		$c = $ENV{$1} ;
		debug 2, "evaluacion de entorno de $1!!\n" ;
		$lin =~ s/\$env\($1\)/$c/ ;
	}
#	while ($lin =~ /.*\$orig\(([\w]+[a-zA-Z0-9_.\-]*)\).*/ ) {
#		$c = $wbbDef{$1} ;
#		debug 2,  "evaluacion de original de $1!!\n" ;
#		$lin =~ s/\$orig\($1\)/$c/ ;
#	}

  
        return $lin ;
        }


#----------------------------------------------------------------------
# Function: NormalizePath
#----------------------------------------------------------------------
sub NormalizePath {
  my $wPath = shift;
  if ((defined ($wPath)) &&  ($wPath  ne "")) { 
  # Por si alguien pone 
  # /Volumes/////repositorio/WWW2/www.rediris.es//src/
  $wPath =~ s/\/\/+/\//g ;
  # Eliminamos la última barra "/"
  $wPath =~ s/\/$//g;
  }
  else { $wPath = "" ; }

  return $wPath;
}




	
1;
