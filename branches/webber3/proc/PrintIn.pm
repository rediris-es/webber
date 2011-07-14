#!/usr/bin/perl
#
# Webber processor for simply printing the contents of #wbbIn
#

package PrintIn;

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



my $name=	"PrintIn";
my $version=	"1.0";

sub info {
   print "$name v$version: Copy #wbbIn into #wbbOut\n";
}

sub help
{
   print <<FINAL
$name 

Webber processor, version $version
This program must run inside Webber.
This is the simplest Webber processor. It just passes to #wbbOut the current
contents of #wbbIn.
$name must be used as (one of) the last processor(s).

$name uses the following Webber variables:
 #wbbIn:    Its value is passed to #wbbOut by the processor.
 #wbbOut:   Its current value is concatenated with #wbbIn by the processor.
FINAL
}

sub printIn
{
#   foreach my $k (keys %main::var) {  print STDOUT "con main::var $k= $main::var{$k}\n" ; }
#   $refvar = \%Webber::var;
   $refvar = $_[0] ;
   debug( 1, "(PrintIn) PrintIn se ejecuta\n") ;
   debug(1, " (PrintIn),wbbIn = \n$main::var{'wbbIn'}\n" );
#   foreach my $k (keys %$refvar ) { print  STDOUT "refvar $k = $$refvar{$k}\n" ; }
#   $main::var{'wbbOut'} .= "<!-- Webber proc $name v$version -->\n";
#   $$main::var{'wbbOut'} .= $main::var{"wbbIn"};
    $$refvar{'wbbOut'} .= "<!-- Webber proc $name v$version -->\n";
    $$refvar{'wbbOut'} .= $$refvar{'wbbIn'} ;
}

if ($0 =~ /$name/) { &help; die ("\n"); }

1;
