#file: WebberRaw.pm
# 
# Apache2 Filter to Webberize web pages on the fly
# Input must be in webber Format
#
# Based on a prevoius work wwebber.pm 
#
# $Id$ 
#-------------------------------- 

package Webber::FilterRaw; 
  
use strict;

use warnings; 
use Apache2::Filter (); 
use Apache2::RequestRec (); 
use APR::Table (); 
  
use Apache2::Const -compile => qw(OK); 
use constant BUFF_LEN => 4098; 


our    @ISA = qw(Exporter);
our  @EXPORT = qw(read_webber_conf debug ) ;
our @EXPORT_OK =  qw(read_webber_conf debug );

### Funciones propias de Webber

no strict 'refs';

my $debugfile="/var/log/webber/debug-web.txt" ;
my %webber_env= () ;
my %webber_default =() ;

my %webs_hash ;
my %webberhash ;

sub set_debug_file {
	my $file = $_[0] ;
	$debugfile = $file ; 
	}

sub set_webber_env {
	my $key=$_[0] ;
	my $value=$_[1] ;
	$webber_env{$key}= $value ;
	}
#-------------------------------------------------------------------------
# Function: debug 
#-------------------------------------------------------------------------
sub debug {
        my @lines = @_ ;
        my $level = shift @lines ;
	my $currentlevel=1000 ;
	$currentlevel= $webber_default{'wbbDebug'} if ( defined $webber_default{'wbbDebug'} );
        if ($level <= $currentlevel ) {
        my $line= join '', @lines ;
        chomp $line ;
	my $file = $debugfile ;
        if (  defined ($webber_default{'wbbDebugFile'}) && $webber_default{'wbbDebugFile'} !~/stderr/i)   {
         	$file= $webber_default{'wbbDebugFile'} ;
		}

                open FILE, ">>$file" ;
         #       print FILE  untaint ($line) . "\n" ;
#		if(tell(FILE) != -1) { print FILE  ($line) . "\n" ; }

                close FILE ;
        }
}


sub wbbdebug {
	debug @_ ;
	}
 
sub string2webber {
	my $string=$_[0] ;
	my $rhash=$_[1] ;
	
	my $target ="" ;
	my @hash= split /\n/, $string ;
	$$rhash{'wbbActualFile'}="stdin" ;
	
	my ($line, $varname) ;	
	$varname="" ;
	for  (my $loop=0 ; $loop!=@hash ; $loop++) {
			debug(1,"procesando linea[$loop]=$hash[$loop]");
		$line=$hash[$loop] ;
		#Same as read_webber_file ;-)
		if ($line =~ /^##/) { # Comentarios ...
        	 $varname = "";
      		}
		elsif ($line =~ /^#([\w]+[a-zA-Z0-9_.\-\$]*)\s*\=\s*(.*)$/) {
        	 $$rhash{"$1"} = EvaluateVar ($2, $rhash ) if ( defined $2 ) ;
#		debug (2,"Debug:(readVars) $varname := $1}\n") ;
         	$varname = "$1";
      		}	
      		elsif ($line =~ /^#([\w]+[a-zA-Z0-9_.\-\$]*)\s*\+\s*(.*)$/) {
         		if (exists $$rhash{"$1"}) { $$rhash{"$1"} .= " " . EvaluateVar($2, $rhash) if (defined $2) ; }
         		else { $$rhash{"$1"} = EvaluateVar ($2, $rhash) if (defined $2) ; }
		debug (2,"Debug:(readVars) $varname += $$rhash{$varname}\n") ;
         	$varname = "$1";
      		}
      		elsif ($line =~ /^#([\w]+[a-zA-Z0-9_.\-\$]*)\s*\*\s*(.*)$/) {
         		if (exists $$rhash{"$1"}) { $$rhash{"$1"} = EvaluateVar($2, $rhash) . " "  . $$rhash{"$1"} if (defined $2) ; }
         		else { $$rhash{"$1"} = EvaluateVar ($2, $rhash)  if (defined $2 ) }
		debug (2,"Debug:(readVars) $varname *= $$rhash{$varname}\n") ;
         	$varname = "$1";
      		}
      		else {
         		if ($varname eq "") {
            			chop $line;
            			if ($line !~ /^[\s]*$/) { # Ignore blank lines without 
               			}	
         		}
         		else {
            		my $lc= chop $line;
			 $line .=  $lc if (ord($lc) ne 10); # Si no es un \n 
            		$$rhash{"$varname"} .= "\n" . EvaluateVar($line , $rhash) ;
         		}
      		}
   		}	
	
}
			
sub read_webber_file {

   my  $file =$_[0] ;
   my  $rhash= $_[1] ;

   my $target= "";
  
   my %var= %$rhash ;  
   open INFILE,"<". $file  ; 

   my $lno = 0;
   my $varname = "" ;
   $var{'wbbActualfile'} = $target ;
   while (my $line = <INFILE>) {
      if ($line =~ /^##/) { # Comentarios ...
         $varname = "";
      }
      elsif ($line =~ /^#([\w]+[a-zA-Z0-9_.\-\$]*)\s*\=\s*(.*)$/) {
         $$rhash{"$1"} = EvaluateVar ($2, $rhash ) if ( defined $2 ) ;
         $varname = "$1";
      }
      elsif ($line =~ /^#([\w]+[a-zA-Z0-9_.\-\$]*)\s*\+\s*(.*)$/) {
         if (exists $$rhash{"$1"}) { $$rhash{"$1"} .= " " . EvaluateVar($2, $rhash) if (defined $2) ; }
         else { $$rhash{"$1"} = EvaluateVar ($2, $rhash) if (defined $2) ; }
         $varname = "$1";
      }
      elsif ($line =~ /^#([\w]+[a-zA-Z0-9_.\-\$]*)\s*\*\s*(.*)$/) {
         if (exists $$rhash{"$1"}) { $$rhash{"$1"} = EvaluateVar($2, $rhash) . " "  . $$rhash{"$1"} if (defined $2) ; }
         else { $$rhash{"$1"} = EvaluateVar ($2, $rhash)  if (defined $2 ) }
         $varname = "$1";
      }
      else {
         if ($varname eq "") {
            chop $line;
            if ($line !~ /^[\s]*$/) {
               }
         }
         else {
            chop $line;
            $$rhash{"$varname"} .= "\n" . EvaluateVar($line , $rhash) ;
         }
      }
   }
   close INFILE;
}


#----------------------------------------------------------------------
# Function: untaint
#----------------------------------------------------------------------
sub untaint {
   my ($arg) = @_;
   $arg =~ m/^(.*)$/;
   return $1;
}
#-------------------------------------------------------------------------
# Function: EvaluateVar
# ------------------------------------------------------------------------
sub EvaluateVar  {
        my $lin = $_[0] ;
        my $ref = $_[1] ;
        my $c ;
	my %var ;
	debug (3, "Entrada en EvaluateVar con Line= $lin" ) ;

        while ($lin =~ /.*\$var\(([\w]+[a-zA-Z0-9_.\-]*)\).*/ ) {
                if (defined ($$ref{$1})) {
			$c = $$ref{$1}  ;
		} else { $c= "" ; }
                $lin =~ s/\$var\($1\)/$c/ ;
		
        }
        while ($lin =~ /.*\$env\(([\w]+[a-zA-Z0-9_.\-]*)\).*/ ) {
                $c = $webber_env{$1} ;
                $lin =~ s/\$env\($1\)/$c/ ;
        }
#        while ($lin =~ /.*\$orig\(([\w]+[a-zA-Z0-9_.\-]*)\).*/ ) {
#                $c = $wbbDef{$1} ;
#                $lin =~ s/\$orig\($1\)/$c/ ;
#        }

	debug (3, "Salida de EvalueateVar con Line =$lin") ; 
        return $lin ;
        }



sub copy_hash {

 my  $rs=$_[0] ;
 my  $rd=$_[1] ;
foreach my $key (keys %$rs) { $$rd{$key} = $$rs{$key} ; }

}

sub init_webber_system {
	my $file = $_[0] ;
	%webber_default = () ;
	read_webber_file ($file, \%webber_default) ;
	# We set some defaults values here
	if (defined $webber_default{'wbbDebugFile'} ) {set_debug_file ($webber_default{'wbbDebugFile'} ); }

}




sub do_webber {
        my $rh = $_[0] ;

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

return ( $rh) ;

}


sub read_webber_conf {
	my $file= $_[0] ;
open FILE , $file || die " Can't open $file!!\n" ; 
my ($xml ) ;
my %ret ;

while (<FILE> )  { $xml .= $_ ; }

my @sites= split /<\/site>/, $xml ;
pop @sites ;

my $rs={} ;
for  (my $i = 0 ; $i!=@sites ; $i ++ ) {
#	print "Site $i ; \n $sites[$i]\n-----\n" ; 
# OK , let's start building the hash 
my ($key, $rl, $re) ;
my ($cad,$url,$env, $config,$local) ;
my @tmp ;

$re={} ;
$rl={} ;

   $cad=$sites[$i] ;
   $cad =~ /<site "(.*)">/i ;
   $url=$1 ;
   $cad =~/<env>(.*)<\/env>/si ;
   $env=$1 ;
   # Falta procesamiento de $env
   @tmp = split /<\/key>/, $env ; pop @tmp ;
   for (my $j=0 ; $j!=@tmp ; $j++) {
	$tmp[$j] =~ /<key.*"(.*)".*>(.*)/si ;
        $$re{$1}=$2 ;
#	print STDERR "ENV cargado $1 ==> $2 \n" ;
   }
   $cad=~ /<config>(.*)<\/config>/i ;
   $config =$1 ;
   $cad=~/<local>(.*)<\/local>/si ;
   $local=$1 ;
   @tmp = split /<\/key>/, $local ; pop @tmp ;
   for (my $j=0 ; $j!=@tmp ; $j++) {
        $tmp[$j] =~ /<key.*"(.*)".*>(.*)/si ;
        $$rl{$1}=$2 ;
#	 print STDERR "LOCAL cargado $1 ==> $2 \n" ;
   }
 

#almacenamiento
 my $rt={} ;
 $$rt{'url'} =$url ; 
 $$rt{'config'} =$config ;
 $$rt{'env'} = $re ;
 $$rt{'local'} = $rl ;

$webs_hash{$url} = $rt ;

}
   
}

sub lookup_web
{
	my $cad =$_[0] ;
	
	my $pos ;
	my $tmp="" ;
foreach my $k (sort keys %webs_hash) {
#	print STDERR "checking $cad vs $k\n" ;
	if ($pos = index ($cad,$k) != -1) { 
		if (length ($k) > length($tmp)) {$tmp =$k ; }
	}
	}

	if ($tmp ne "") {
#		print STDERR "Path encontrado $tmp\n" ; 
		my $rh=  $webs_hash{$tmp} ; 
		my $rt  =$$rh{'env'} ;
		#foreach my $k (keys %$rt) { print STDERR " ENV $k ==> $$rt{$k}\n" ; }      
		%webber_env = () ;
		copy_hash($rt, \%webber_env);
		
		%webberhash = () ;
		read_webber_file ($$rh{'config'}, \%webberhash) ;
                $rt= $$rh{'local'} ;
                #foreach my $k (keys %$rt) { print STDERR " LOCAL $k ==> $$rt{$k}\n" ; }
		copy_hash ($$rh{'local'}, \%webberhash);
	}
	else {
		# Not found this is RedIRIS specific 
		$webberhash{'wbbOut'} = "Error stio web no encontrado $cad no debe usar este filtro"; 
	
}		

}
### Handler magico que que hace todo el trabajo sucio y algo más
 
sub handler { 
       my $f = shift; 
 
      unless ($f->ctx) { 
	 $f->r->headers_out->unset('Content-Length');
        $f->r->content_type("text/html; charset=UTF-8");
          $f->ctx(1); 
      } 
 
 	my $string = "" ;
 
      while ($f->read(my $buffer, BUFF_LEN)) { 
          $string .= $buffer ; 
	}
	
# todo esto deberia estar en un fichero de configuracion 
#	set_webber_env("WBBROOT","/rep0sitorio/servicios/web/webber/" ) ;
#	set_webber_env("REPOSITORIO","/rep0sitorio/servicios/web/webber/" ) ;
#	set_debug_file ("/tmp/webber-cgi-debug.txt") ;
#	init_webber_system ("/rep0sitorio/servicios/web/webber/rediris.wbb") ;
#	init_webber (\%webberhash) ;

# Esto es el webbeo 
	

        my $r= $f->r() ;
        my $s= $r->server() ;
        my $host=$r->hostname() ;
	$r=$f->r() ;
        my $uri= $r->unparsed_uri();
        #my $port=$s->port() ;
#	my $port="" ;
#	print  STDERR "Peticion de $host$uri\n" ;
	# Precargamos el hash con la infomracion 	
	lookup_web ($host .  $uri);
	if (defined $webberhash{'wbbDebugFile'} ) {set_debug_file ($webberhash{'wbbDebugFile'} ); }
	#cargamos la pagina en formato webber
        string2webber($string, \%webberhash) ;	
	do_webber(\%webberhash) ;

	my @out = split /\n/, $webberhash{'wbbOut'} ; 
	for (my $i=0 ; $i!=@out ; $i++) {
			  $f->print("$out[$i]\n") ;  }

	  
      return Apache2::Const::OK; 
  } 


 1; 
