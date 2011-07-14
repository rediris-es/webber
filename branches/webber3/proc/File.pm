#!/usr/bin/perl
#
# Webber processor for Handling Files, 
# 
# This processsor is "MUST" if you want to don't break compatibility with the
# old webber System
#

package File;

## Funciones auxiliares

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
#----------------------------------------------------------------------
# Function: untaint
#----------------------------------------------------------------------
sub untaint {
   my ($arg) = @_;
   $arg =~ m/^(.*)$/;
   return $1;
}


my $name=	"File";
my $version=	"1.0";

sub info {
   print "$name v$version: File I/O : Mimic the original Webber I/O\n";
}

sub help
{
   print <<FINAL
$name 

Webber processor, version $version
This program must run inside Webber.
This is  the BASIC webber processor, as it provides the I/O fucnctions to do something
after reading the basic configuration

Provides the following Processors.

WriteVar:  writes the content of a webber variable (pointed bt File.WriteVar)
to a file pointed by  wbbTarget varible.

File::WriteVar uses the following Webber variables:
 #File.WriteVar: Is the variable to be written (defaults to wbbOut)
 #wbbTarget: Filename (path included)
 #wbbexttmp: Extensión temporal de los ficheros
 #wbbTargetFileMode:  File mode (UNIX octal permisssions)

ReadVars: Read Webber Vars from a file , add all the vars read to the webber Vars

File::ReadVars uses the following Webber variable:
  wbb
FINAL
}

sub WriteVar  
{

  my $refvar =$_[0] ;

  open  FILE  , ">".untaint($refvar{'wbbTarget'} . $refvar{'wbbexttmp'} ) || die "Can't write to $trefvar{'wbbtarget'}.$var{'wbbexttmp'}\n" ;

    print FILE   $refvar{$refvar{'File.WriteVar'}} ;
    debug (2, "$refvar{'File.WriteVar'} written in $refvar{'wbbTarget'}$refvar{'wbbexttmp'} " ) ;
   close (FILE);
# Now the move
   unlink $refvar{'wbbTarget'}  if -e  $refvar{'wbbTarget'}   ;
   rename $refvar{'wbbTarget'}  . $refvar{'wbbexttmp'} , $refvar{'wbbTarget'}  ;
   debug (2,"file  $refvar{'wbbTarget'}$refvar{'wbbexttmp'}  renamed to  $refvar{'wbbTarget'} ") ;
   chmod oct $refvar{"wbbTargetFileMode"}, untaint ($refvar{'wbbTarget'} );

}

if ($0 =~ /$name/) { &help; die ("\n"); }

1;
