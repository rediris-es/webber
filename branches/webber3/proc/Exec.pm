#!/usr/bin/perl
#
# A Webber processor for variable assignment using external programs
#
# (c) RedIRIS 2000
#
package Exec;

my $name="Exec";
my $version="1.0";

my $varkey = 'exec';

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





sub info {
   print "$name v$version: Execute programs and store the output in Webber vars\n";
}

sub help {
   print <<FINAL
$name 

Webber processor, version $version
Assign the values of Webber variables by executing external programs.
This progran must run inside Webber.
It modifies any Webber variable, as defined below.

$name may be used as any kind of processor

$name uses the following Webber variables:

 #exec.VARNAME: Where VARNAME is the name of a Webber variable. Depending
                on the value of the variable, $name assigns a value for
                VARNAME taken from the results of executing a program.
The value of a $name variable has to comply to the following format:
  ['+'] ProgramAndArguments
Where:
 * If the optional '+' symbol is used, $name appends the result of
   executing the program to the current value of the variable.
 * ProgramAndArguments is the program to be executed, through the Perl
   backtick operator.
   The string is pre-processed by $name prior to invoking the backtick
   operator, so any reference of the form #VARNAME is substituted by
   the current value of the corresponding Webber variable (an empty
   string if the variable referenced by VARNAME is not defined).
FINAL
}

sub exec {
   my $var = $_[0] ;
   $$var{'wbbOut'} .= "<!-- Webber proc $name v$version -->\n";
   my ($k, $d, $kva, $command);
   my %cva;
   for $k (keys %$var) {
      ($d, $kva) = split /\./,$k;
      next if ($d ne $varkey);
      if ($$var{$k} =~ /^[+](.*)/) {
         $cva{$kva}->{argv} = $1;
         $cva{$kva}->{plus} = 1;
      }
      else {
         $cva{$kva}->{argv} = $$var{$k};
      }
   }

   for $k (keys %cva) {
      $command = "";
      for $d (split /\s/, $cva{$k}->{argv}) { 
         if ($d =~ /^#(.*)/) { $command .= " $$var{$1}"; }
         else { $command .= " $d"; }
      }
      if (exists $cva{$k}->{plus} and exists $$var{$k}) {
         $$var{$k} .= `$command`;
      }
      else { $$var{$k} = `$command`; }
   }
}

if ($0 =~ /$name/) { &help; die ("\n"); }

1;
