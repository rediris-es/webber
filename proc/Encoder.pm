#!/usr/bin/perl

package Encoder;

use File::Temp;
use Encode;
use Encode::Guess ; 
#use strict ;

#-------------------------------------------------------------------------
# Function: debug 
#-------------------------------------------------------------------------
sub debug {
        my @lines = @_ ;
#        my $level = shift @lines ;
        if (defined (&wbbdebug)) { wbbdebug ( @lines) ; }
        elsif (defined main::debug) { main::debug (@lines) ; }
        else {
         my $level = shift @lines ;
        my $line= join '', @lines ;
        chomp $line ;
        print STDERR "$line\n" ;
        }
        }# End Funcion debug



my $name=       "Encoder";
my $version=    "0.1";

my %def = (
	'encoder.targetencoding' => 'utf8' ,
	'encoder.varstoencode'   => 'wbbIn wbbOut title subtitle iris-smHijos-es iris-smPadres-es' 
	) ;

sub info { print "$name v$version: Transforms an input file tree encoded with any charset to an user defined output charset\n"; }

sub help
{
  print <<FINAL
$name

Webber processor, version $version
This program must run inside Webber.
This Webber processor modified some webbers variables (defined in encoder.varstoencode webber var) so
all the variable contents are in the charset encoding defined for encoder.targetencoding 

Usage:
 - Include Encoder::translate in the processors list
 - If needed set #encoder.targetencoding and #encoder.varstoencode to the desired values

Vars

 #Encoder.targetencoding Targer Encoding used in the variables default  = $def{'encoder.targetencoding'} 
 #Encoder.varstoencode  List of webber vars (comma separated) to change = $def{'encoder.varstoencode'} 

FINAL
}



sub translate
{

  my $rv = $_[0] ;
  
  my $targetencoding = defined ($$rv{'encoder.targetencoding'}) ? $$rv{'encoder.targetencoding'}  : $def{'encoder.targetencoding'} ;
  my $tmp =  defined ($$rv{'encoder.varstoencode'}) ? $$rv{'encoder.varstoencode'}    : $def{'encoder.varstoencode'} ;
  my @vars= split /\s+/ , $tmp ;
  debug (1, "encoder.varstoencode' = $tmp   ") ;
  debug (1,"Encoding to $targetencoding tmp =$tmp  vars= @vars") ;

  foreach my $vartoencode  (@vars )  {
	debug (3,"Encoding $vartoencode  to $targetencoding   value $$rv{$vartoencode}");
	my $current= guess_encoding ($$rv{$vartoencode} , qw /ascii ascii-ctrl iso-8859-1 null utf-8-strict utf8/ );
	
	if (ref($current)) {
	my $name= $current->name ;
	print STDERR  (3,"Current encoding of $vartoencode in file $$rv{'wbbSource'} is $name\n") ;
	if (($name ne $targetencoding )  && ( $name !~ /ascii/ ) ){
		#from_to($$rv{$vartoencode} , $name , $targetencoding )  ;
#		$$rv{$vartoencode} = encode($targetencoding , decode ($name, $$rv{$vartoencode})) ;
	}
	else { $$rv{$vartoencode} = encode ($targetencoding , $$rv{$vartoencode} ) ; }
	debug (3,"Result is $$rv{$vartoencode}" ) ;
	}
	else {  print STDERR "Cant' detect the encoding of $vartoencode\n" ; }
}


}

if ($0 =~ /$name/) { &help; die ("\n"); }

1;

