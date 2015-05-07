#!/usr/bin/perl
#
# Webber processor for printing the values of Webber variables.
#

package DumpVars;
use strict ;



my $name=       "DumpVars";
my $version=    "1.0";

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
   print "$name v$version: Store in wbbOut selected Webber vars\n";
}

sub help
{
   print <<FINAL
$name

Webber processor, version $version
This program must run inside Webber.
This processor stores in #wbbOut the current contents of the selected Webber
variables.
$name must be used as (one of) the last processor(s).

$name uses the following available Webber variables:
 #dumpVars.varlist: A list of the variable names to be printed
FINAL
}

sub dumpVars
{
   my $var= $_[0] ;
   my @vl = split /\s/,$$var{"dumpVars.varlist"};
   $$var{'wbbOut'} .= "<!-- Webber proc $name v$version -->\n";
   foreach my $k (@vl) { $$var{'wbbOut'} .= "#$k= $$var{$k}\n"; }
}

if ($0 =~ /$name/) { &help; die ("\n"); }

1;

sub debugvar  {
}
