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

my $name=	"Webbo";
my $version=	"2.1";

my $expVAR=  '<var name\s*\=\s*\"(w+)\"\s*\/>';
my $expVAR1= '<var name\s*\=\s*\"';
my $expVAR2= '\"\s*\/>';


#-------------------------------------------------------------------------
# Function: debug 
#-------------------------------------------------------------------------
sub debug {
        my @lines = @_ ;
        my $level = shift @lines ;
        if (defined (&wbbdebug)) { wbbdebug (@lines) ; }
	elsif (defined main::debug) { main::debug (@lines) ; }
        else {
        my $line= join '', @lines ;
        chomp $line ;
        print STDERR "$line\n" ;
        }
        }
# End Funcion debug

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
   $var = $_[0];

    debug  (1, "Webbo::webbo se ejecuta") ;
if (exists $$var{"webbo.src"}) 
{
  my ($srcClass, $srcName) = split /:/,$$var{"webbo.src"};
  if ($srcClass eq "file") 
  { 
    $webboSrc = &leeDatos($srcName);
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
   #   una sola vez no se resolv�an todas las variables
   for ($i=1 ; $i<=2 ; $i++)
   {
     foreach my $k ( sort keys %$var) 
     {
        if ($k ne $webboDst)
        {
           my $rex = $expVAR1.$k.$expVAR2;
	   #debug (0, "rex= $rex k= $k  valor $$var{$k}" ) ;
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
local ($file) = @_;
local ($datos);

  if (-f $file)
  {
    open F, "<$file" ||
      syslog ("err", "Error reading $file: $!") && return ("-1");
    $datos = join "", <F>;
    close F;
  }
  else
  {
    $e = $!;
    $error = "Error opening $file: $e";
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
