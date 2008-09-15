#!/usr/bin/perl
#
# Webber processor for printing the values of Webber variables.
#

package DumpVars;

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


my $name=	"DumpVars";
my $version=	"1.0";

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
   $var= $_[0] ;
   my @vl = split /\s/,$$var{"dumpVars.varlist"};
   $$var{'wbbOut'} .= "<!-- Webber proc $name v$version -->\n";
   foreach my $k (@vl) { $$var{'wbbOut'} .= "#$k= $$var{$k}\n"; }
}

if ($0 =~ /$name/) { &help; die ("\n"); }

1;

sub debugvar  {
}
