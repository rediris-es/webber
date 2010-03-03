#!/usr/bin/perl
#
# Webber processor for simply printing the contents of #wbbIn
#

package Vars;

use File::Basename ;

#################### Auxiliary function & vars   #########################
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

#-----Programacion modular ;-)--------------
sub readvars {
	my $file = shift ;
	my %hash ;
 	main::readVars ( $file , "-" , \%hash) ;
	return %hash ;
	}
#--------------------------------------------
my %defs = (
	'vars.pathvars.wbbsourceroot' => 'wbbTargetRoot' 
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
 Copy the content of a webber Vars onto another one 

 Exmaple: You have an old Var definitin in which one variable is used for
example for the "content" of the page, now you use another template with 
another name, this processor allow to copy the old var and create a new
one. Use the #vars.CopyVars, a white list of var_src:vars_dst pairs to define
which vars to copy.
  
  The separator has different meanings:
	: Means straight Copy src:dst copy src always to dst
	:? means conditional copiy src:?dst copy src to dst if dst is not defined
	:+ means addition after src:+dst . dst will have the value of dst concatenated 
	with the value of src (same value if dst wasn't defined 
 
Vars::PathVars
  Implements the following "special Vars":
  #vars.dep = Dep from wbbSourceRoot to the actual file (in number)
  #vars.pathtoroot = "Creates a Path" (concatation of "../.." to the wbbTargetRoot
  #vars.pathfromoot = "Path from the wbbTargetRoot to the file"

Note: All this variables requires that file being webbered would  be in a directory
below #vars.pathvars.wbbsourceroot (defaults to $$defs{'vars.pathvars.wbbsourceroot'} , to work
correctly.

Vars::readfromfile
 Read some webbers vars from a webber format file that.
 webbers vars.
#vars.readfromfile.CODE.file=
#vars.readfromfile.CODE.vars=

 where CODE is a generic code to allow multiple file import
 file is relative to the current (source code path)
 vars is a list of vars, use the extended syntax of Vars::CopyVars, so 
#vars.readfromfile.info.file= ./wbbdir.cfg.back
#vars.readfromfile.info.vars= title author? contributor+

Will:
  - Set the title vars to the one in the file wbbdir.cfg.bak"
  - Change the author variable (if not exists) , 
  - concat the contributors 

Note all the vars are alphanumeric sorted before processing so
#vars.readfromfile.AAAA.file = ../wbbdir.cfg
#vars.readfromfile.AAAA.vars = author
#vars.readfromfile.BBBB.file = ./wbbdir.cfg
#vars.readfromfile.BBBB.vars = author

Will create the author var with the most specific version if
found.

Vars::regex
Perform Regular expressions actions on webber vars

It will use vars in the format #vars.regex.CODE (where code
is a unique code that identifies the regular expresion).

Example

#vars.regex.AAAA.var= wbbIn 
#vars.regex.AAAA.regex= s/XXX/juan/g

Perform a substitituion on on var wbbIn, changing the appareance
of XXX by the name juan

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
		if ($i =~ /(.*):\+(.*)/ ) { # Concatenation
		   my $src=$1 ;  my  $dst=$2 ;
		   debug 3, "concatnationcopy :+ from $src to $dst" ;
		  if (defined $$rv{$dst} ) {$$rv{$dst} .= $$rv{$src} ; }
		  else {   $$rv{$dst} = $$rv{$src} ; }
		}
		elsif ($i =~ /(.*):\?(.*)/ ) { #conditional
		 my   $src=$1 ; my $dst=$2 ;
		       $$rv{$dst} = $$rv{$src}  unless defined ($$rv{$dst});
			debug 3, "conditional copy :? from $src to $dst" ;
		}
		else {
		my ($src, $dst) = split /:/, $i ;
                debug  3 ,"Goint to process $i src= $src copied to $dst " ;
		$$rv{$dst} = $$rv{$src} ;
        	}
        }}
   else { debug 1, "Vars.CopyVars called, but vars.copyvars not defined" ; }
}

sub PathVars {
	my $rv = shift ;
	debug 1, "Vars::PathVars Vars is started\n" ;
	if (defined ($$rv{'wbbInteractive'} && $$rv{'wbbInteractive'} eq "1")) {
		debug  1, "Intectavtive mode not doing anything"; 
		 }
	else {
	my $basevar= defined ($$rv{'vars.pathvars.wbbsourceroot'} ) ? $$rv{'vars.pathvars.wbbsourceroot'} : $defs{'vars.pathvars.wbbsourceroot'} ;
	my $base = $$rv{$basevar} ;
	debug 2, "checking paths, basevar =$basevar value base  Source start at =$base wbbTarget=$$rv{'wbbTarget'}" ;
	my $filepath= $$rv{'wbbTarget'} ;
	my $relpath= $filepath ;
	$relpath =~ s/^$base// ;
	my @dir = split /\//, dirname ($relpath) ;
	my $count = @dir ;
	if ($count !=0 ) { $count-- ; }
	$point="" ;
	debug 2, "bucle for from o a $count\n" ;
	for (my $i=0 ; $i!=$count; $i++ ) {
		$point .= "../" ; 
	}
	debug 2, "from $filepath result is dep = $count , pathtoroot =$point ; pathfromroot=$relpath" ;
	$$rv{'vars.dep'} = $dep ;
	$$rv{'vars.pathtoroot'} = $point ;
	$$rv{'vars.pathfromroot'} = $relpath ;
	}
}
sub readfromfile {
	my $rv=shift ;
	debug (1, "Vars::readfrom file is  executed") ;
	foreach  my $var (sort keys %$rv ) {
			next unless ($var =~/vars.readfromfile.(.*).file/) ;
			my $code = $1 ;
			my $vtemp= "vars.readfromfile.$code.vars" ;

			if (not defined ($$rv{$vtemp})) {
				debug (1,"found $var , but not $vtemp variable, doing nothing");
				next ;
				}
			my $file= $$rv{$var} ;
	
			debug (2, "procesing file $file} from $var , vars to modify $$rv{$vtemp}") ;
			if (not -r ($file  )) { 
						debug (1, "file $file  not found, sky!");
						next ; }
			my %hash = readvars ($file);
			my @to_process = split /\s+/, $$rv{$vtemp} ;
			foreach my $add (@to_process) {
				debug (4, "vars.readfromfile $code var $add") ;
				if ($add =~ /(.*)\+$/ ) { $$rv{$1} .= $hash{$1} ; debug (3, "concat(+) $var") ; }
				elsif ($add=~/(.*)\?$/) { debug (3, "conditional add $1") ;$$rv{$1} = $hash{$1} unless (defined $$rv{$1}) ;  }
				else { $$rv{$add} =$hash{$add} ; debug (3, "added $add") ; }
				}

			}
}	

sub regex {
	my $rv= shift ;
	debug (1, "Vars::regex is executed") ;
	foreach my $var (sort keys %$rv) {
		next unless  ($var =~ /vars.regex.(.*).var/) ;
		my $code= $1 ;
		my $regex= "vars.regex.$code.regex" ;
		if (not defined ($$rv{$regex})) {
			debug (1, "found vars.regex.$code.var , but no regular expression $regex") ;
			next ;
		}
		my $exec ; 
		if ($$rv{$regex} =~ /s\/(.*)\/(.*)\/(.*)/ ) {
			debug (3, "Var::regex var is $var,  content is $$rv{$var} ");
			debug (3, "Var::regex1 to build is rv{$$rv{$var}} =~ $$rv{$regex}") ;
			my $page = $$rv{$$rv{$var}} ;
			my $regex2= $$rv{$regex} ;
			debug (3, "Var::regex2 to build is rv{$$rv{$var}} =~ $regex2") ;
#			 $regex2 = 's/https:\\/\\/alejandria.rediris.es\/.*\/(.*)"/$1"/mg' ;
			debug (3, "Var::regex3 to build is rv{$$rv{$var}} =~ $regex2") ;
			chomp $regex2 ;
			chomp $page ;
		 	debug (3 , "Var::regex to execute is \$page =~ $regex2 ") ;
			debug (3, "page vale $page") ;
			my $exec = "\$page =~ $regex2" ;
			debug (3, "Var::regex exec is $exec" ) ;
			my $res= eval ($exec) ;
#			eval {				$page =~ $regex ;	} ;
#			debug (3, "resultado evaluacion $@") ;
			debug (3, "Var::regex result is $page") ;
			$$rv{$$rv{$var}} = $page ; 
			debug (3, "rv{$$rv{$var}} = $$rv{$$rv{$var}}") ;
		}

}
}
if ($0 =~ /$name/) { &help; die ("\n"); }

1;
