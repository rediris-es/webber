#!/usr/bin/perl
#----------------------------------------------------------------------
#                            __       __                
#                           /\ \     /\ \               
#          __  __  __     __\ \ \____\ \ \____    ___   
#         /\ \/\ \/\ \  /'__`\ \ '__`\\ \ '__`\  / __`\ 
#         \ \ \_/ \_/ \/\  __/\ \ \L\ \\ \ \L\ \/\ \L\ \
#          \ \___x___/'\ \____\\ \_,__/ \ \_,__/\ \____/
#           \/__//__/   \/____/ \/___/   \/___/  \/___/  2.1
#
#         (c) 1997-2007 Javi Masa - javier.masa@rediris.es
#                       Diego R. Lopez - diego.lopez@rediris.es
#
# Webber processor for incorporating variables into page templates
#
#----------------------------------------------------------------------
package Webbo;
use Cwd;
use strict ;

my $name=	"Webbo";
my $version=	"2.1";

my $expVAR=  '<var name\s*\=\s*\"(w+)\"\s*\/>';
my $expVAR1= '<var name\s*\=\s*\"';
my $expVAR2= '\"\s*\/>';

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
   print "$name: v$version: Incorporate variables into page templates\n";
}

sub help
{
   print <<FINAL
$name

Webber processor, version $version

Incorporates variables into page templates.
This program must run inside Webber.

It subsitutes in the variable defined by #webbo.dst any ocurrence of tags of
the form: <var name="WEBBER-VARIABLE" /> for the value of the Webber variable
identified by the tag. The original value for the destination variables is
taken from the contents of the elements identified by #webbo.src.
$name must be used as (one of) the first processor(s).

$name uses the following Webber variables:

 #webbo.src: Defines a list of sources to be used for reading source
             values. 
             The format of a source specification is:   CLASS:NAME

             Where CLASS can be either:
             "var" (the source is a Webber variable), 
             "file" (the source is a file) or 
             "eval" (the source is a file whose name is obtained when evaluating NAME),
             and NAME identifies the source.

             If no source is specified, #wbbIn (equivalent to
             "#webbo.src = var:wbbIn") is used.

 #webbo.dst: Defines the destination of $name processing. If no destination is
             specified, #wbbOut (equivalent to "#webbo.dst = wbbOut") is used.

 #webbo.regex.pre: The start of the regular expresion (defaults to: $expVAR1 )
 #webbo.regex.post: The end  of the regular expresion (defaults to: $expVAR2 )

 Any other:  Any other variable referred in a <var /> tag, subsituting the
             tag for the variable value in #wbbOut.

$name modifies the following Webber variables:
 Any defined by #webbo.dst (by default, #wbbOut), using the values of the
 sources defined by #webbo.src, and substituting the values of variables
 identified inside <var/> tags.
FINAL
}

#----------------------------------------------------------------------
#
#----------------------------------------------------------------------
sub webbo
{
   my $var = $_[0];

    debug  (1, "Webbo::webbo se ejecuta") ;
    debug  (1, "webbo.src = $$var{'webbo.src'}") ;
    debug  (1, "webbo.dst = $$var{'webbo.dst'}\n")  if (defined $$var{'webbo.dst'});

    if (exists ($$var{'webbo.regex.pre'} )) { $expVAR1=$$var{'webbo.regex.pre'} ; }
    if (exists ($$var{'webbo.regex.post'} )) { $expVAR2=$$var{'webbo.regex.post'} ; }
	
    $expVAR= $expVAR1 . "(\\w+)" . $expVAR2 ;

	debug (2, "webbo.regex.pre = $expVAR1" ) ;
	debug (2, "webbo.regex.post= $expVAR2" ) ;
	debug (2, "Regex= $expVAR") ;

   my ($webboSrc , $webboDst) ;

if (exists $$var{"webbo.src"}) 
{
  my ($srcClass, $srcName) = split /:/,$$var{"webbo.src"};
  if ($srcClass eq "file") 
  { 
    $webboSrc = &leeDatos($srcName);
    debug  (3, "Template file read from $srcName" );
     
     debug (5, "valor de webboSrc :\n ", $webboSrc) ;
    $webboSrc = "" if ($webboSrc eq "-1");
  }
  elsif ($srcClass eq "var") 
  { 
    $webboSrc = $$var{$srcName};
  }
  elsif ($srcClass eq "eval")
  {
    $webboSrc = &leeDatos( eval $srcName );
    $webboSrc = "" if ($webboSrc eq "-1");
  }
}
else
{
  $webboSrc = $$var{wbbIn};
}

 $webboDst = "wbbOut";
$webboDst = $$var{"webbo.dst"} if exists $$var{"webbo.dst"};
   debug  (1, "Webbo: La salida estara en $webboDst") ;
#-- FALTA --

   $$var{$webboDst} = $webboSrc;

#   $$var{"wbbOut"} =~ s/^/<!-- Webber proc $name v$version -->\n/;

   #-- Lo hacemos 2 veces porque se ha dado el caso en el que con
   #   una sola vez no se resolvían todas las variables
   for (my $i=1 ; $i<=2 ; $i++)
   {
     foreach my $k ( sort keys %$var) 
     {
        if ($k ne $webboDst)
        {
           my $rex = $expVAR1.$k.$expVAR2;
	   debug (5, "rex= $rex k= $k  valor $$var{$k}" ) ;
           $$var{$webboDst} =~ s/$rex/$$var{$k}/g;
        }
     }
   }
   $$var{$webboDst} =~ s/$expVAR//g;
}

#----------------------------------------------------------------------
#
#----------------------------------------------------------------------
sub leeDatos
{
my  ($file) = @_;
my ($datos);

  if (-f $file)
  {
    open F, "<$file" ||
      syslog ("err", "Error reading $file: $!") && return ("-1");
    $datos = join "", <F>;
    close F;
  }
  else
  {
    my $e = $!;
    my $error = "Error opening $file: $e";
    syslog ("err", $error);
    return ("-1");
  }
  
  return ($datos);
}

#----------------------------------------------------------------------
#
#----------------------------------------------------------------------
sub syslog
{
  my ($pri,$line)=@_;
  print STDERR "Webbo: $line\n\n";

#  open F, ">>/tmp/webbo.log";
#  print F "$line\n";
#  close F;
}

if ($0 =~ /$name/) { &help; die ("\n"); }


1;

