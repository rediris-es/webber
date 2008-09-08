#!/usr/bin/perl

package Encoder;

use File::Temp;
use Encode;
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
	'encoder.varstoencode'   => 'wbbIn wbbOut title subtitle' 
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
  debug (1, "$def'encoder.varstoencode'} is this ") ;
  debug (1,"Encoding to $targetencoding tmp =$tmp  vars= @vars") ;

  foreach my $vartoencode  (@vars )  {
	debug (3,"Encoding to $targetencoding  result of $vartoencode value $$rv{$vartoencode}");
	$$rv{$vartoencode} = encode ($targetencoding, $$rv{$vartoencode}) ;
	debug (3,"Result is $$rv{$vartoencode}" ) ;
}


}

if ($0 =~ /$name/) { &help; die ("\n"); }

1;

