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

