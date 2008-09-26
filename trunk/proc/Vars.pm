#!/usr/bin/perl
#
# Webber processor for simply printing the contents of #wbbIn
#

package Vars;

use File::Basename ;
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


my %defs = (
	'vars.pathvars.wbbroot' => 'wbbRoot' 
	);

my $name=	"Vars";
my $version=	"1.0";


sub info {
   print "$name v$version: Manipulate Webber Vars\n";
}

sub help
{
   print <<FINAL
$name 

Webber processor, version $version
This program must run inside Webber.

This module implements different proccessor to manipulate Webber Vars.
the Vars that are affected by this proccesor usually are defined
in a webber vars.
 
$name processors  must be used as (one of) the first processor(s).

$name  implement the following proccesors:

Vars::LazyEval 
 Evaluates/Substitutes the occurrences in webber Vars of %var(name) with
the content of the name webber Vars.

 Example: You want to "evalauate" a webber var after the load vars phase
of webber , currently webber only implements immediately (on the momment)
var substituion with this proccesor you can evaleate a var after all the
vars has been read.
 
Vars::LazyEval use the webber var #vars.lazyeval to define a  while separated
list of webber vars to be Lazy Evaluates

Vars::CopyVars
 Copy the content of a webber Vars onto another one .

 Exmaple: You have an old Var definitin in which one variable is used for
example for the "content" of the page, now you use another template with 
another name, this processor allow to copy the old var and create a new
one. Use the #vars.CopyVars, a white list of var_src:vars_dst pairs to define
which vars to copy.

Vars::PathVars
  Implements the following "special Vars":
  #vars.dep = Dep from wbbSourceRoot to the actual file (in number)
  #vars.pathtoroot = "Creates a Path" (concatation of "../.." to the wbbTargetRoot
  #vars.pathfromoot = "Path from the wbbTargetRoot to the file"

Note: All this variables requires that file being webbered would  be in a directory
below #var.pathvars.wbbroot (defaults to $$defs{'var.pathvars.wbbroot'} , to work
correctly.

FINAL
}

sub LazyEval
{
   $rv= $_[0] ;
   debug( 1, "Vars::LazyEval se ejecuta\n") ;
   if (defined $$rv{'vars.lazyeval'} ) { 
	my @tmp = split /\s+/ , $$rv{'vars.lazyeval'} ;
	foreach my $i (@tmp) {
		debug  3 ,"Goint to process var $i value $$rv{$i}" ;
		while ($$rv{$i} =~ /\%var\(.*\)/ ) 
		{
		$$rv{$i} =~ s/\%var\(.*\)/$$rv{$1}/ ;
		}
		debug 3, "Value of $i possible changed to $$rv{$i}" ;
	}
	}
   else { debug 1,  "Vars.LazyEval called, but vars.lazyeval not defined" ; }
}

sub CopyVars
{
   $rv= $_[0] ;
   debug( 1, "Vars::CopyVars se ejecuta\n") ;
   if (defined $$rv{'vars.copyvars'} ) {    
        my @tmp = split /\s+/ , $$rv{'vars.copyvars'} ;
        foreach my $i (@tmp) {
		my ($src, $dst) = split /:/, $i ;
                debug  3 ,"Goint to process $i src= $src copied to $dst " ;
		$$rv{$dst} = $$rv{$src} ;
        	}
        }
   else { debug 1, "Vars.CopyVars called, but vars.copyvars not defined" ; }
}

sub PathVars {
	my $rv = shift ;
	debug 1, "Vars::PathVars Vars is started\n" ;
	if (defined ($$rv{'wbbInteractive'} && $$rv{'wbbInteractive'} eq "1")) {
		debug  1, "Intectavtive mode not doing anything"; 
		exit  ; }
	my $base= defined ($$rv{'vars.pathvars.wbbroot'} ) ? $$rv{'vars.pathvars.wbbroot'} : $defs{'vars.pathvars.wbbroot'} ;
	debug 2, "checking paths, wbbTargetRoot=$base wbbTarget=$$rv{'wbbTarget'}" ;
	my $filepath= $$rv{'wbbTarget'} ;
	my $relpath= $filepath ;
	$relpath =~ s/^$base// ;
	my @dir = split /\//, dirname ($relpath) ;
	my $count = @dir ;
	$count-- ;
	$point="" ;
	for (my $i=0 ; $i!=$count; $i++ ) {
		$point .= "../" ; 
	}
	debug 2, "from $filepath result is dep = $count , pathtoroot =$point ; pathfromroot=$relpath" ;
	$$rv{'vars.dep'} = $dep ;
	$$rv{'vars.pathtoroot'} = $point ;
	$$rv{'vars.pathfromroot'} = $relpath ;
	}

if ($0 =~ /$name/) { &help; die ("\n"); }

1;
