#!/usr/bin/perl
#
#
# $Id: Dir.pm,v 1.2 2007/09/28 12:48:45 paco Exp $
# 
# New version of the Dir Module
package Dir ;

use strict ;

my $name ="Dir" ;
my $version= "0.2" ;

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





#
# Default values for vars
#---------Info subrutine---------------------------------
sub info {
	print "$name v$version:  This is a automatic directory include for webber\n" ;
}

#--------Help subrutine-----------------------------------
sub help {
 print <<FINAL;
	This is an automatic directory include for webber 
  For use include it in the list of webber templates
  
 This processor will change the macro "#dir(realpath,webserverpath,regex)" for a list
 of links to files that matches the regex (perl mode)

 This processor modifies by defaults wbbin, but this can be
change using the variable "dir.place and setting this to wbbout

 It will use the use "fileindex.txt" in the realpath directory to obtain a description
of each file, the format of this file is filename: description.

FINAL
}

sub dir  {
        my $lin="" ;
        my $var = $_[0] ;
        my $place = 'wbbIn' ;
	my %desc ;
	my @array ;
	my $opt_d = $$var{'opt_d'} ;
	
        $lin .= "<!-- Webber proc $name" . ":: $dir  v$version -->";
#----- Gets the values for the variables

         if (defined $$var{'dir.place'} &&
            ( ($$var{'dir.place'} =~ /wbbOut/i ) || ( $$var{'dir.place'} =~ /wbbIn/i )) ) {
               $place = $$var{'dir.place'} ; }
	else { $place = 'wbbIn' ; }

#  Ok, 
	@array = split /\n/, $$var{'wbbIn'} ;

	foreach $lin  ( @array ){
		if ($lin =~ /(.*)#dir\((.*),(.*),(.*)\)(.*)/ ) {
		   #Line of dir
		   ($pre, $dir, $webpath, $regex, $post) = ($1,$2,$3,$4,$5) ;
		   print STDERR  "processing dir directive $dir\n" if ($opt_d)  ; 
		   %desc= () ;
		   if (-r "$dir/fileindex.txt" ) { # There is an index file
			my ($l,$fn,$fd) ;
			open (FILE, "/$dir/fileindex.txt") ;
			print STDERR  "Reading description from $dir/fileindex.txt\n" if ($opt_d) ; 
			while ( $l= <FILE> ) { 	($fn,$fd) = split /:/ , $l  ;  $desc{$fn} =$fd ;} 
			close FILE ;

		   opendir DIR, $dir ;

$text=<<END;
<center>
<TABLE BORDER="0" BGCOLOR="#555555" 
       CELLPADDING="0" CELLSPACING="1" width="60%">
<TR>
  <TD BGCOLOR="#FFCC00" width="8"><img 
          SRC="/v.gif" WIDTH="8" HEIGHT="8"></td>
  <TD ALIGN="CENTER" BGCOLOR="#1A7F84" 
      CLASS="tbTitAnuncio4">$webpath</td>
</TR>
<TR>
  <TD BGCOLOR="#B7AE9C"><IMG 
          SRC="/v.gif" WIDTH="3" HEIGHT="3"></td>
  <TD BGCOLOR="#EFECE3">
    <TABLE BORDER="0" 
           CELLPADDING="10" CELLSPACING="1" WIDTH="100%">
END
		while ($file =readdir (DIR) ) {
			next unless $file =~ /$regex/  ;
			next if ($file eq "." ) ;
			next if ($file eq ".." ) ;
			next if ($file eq "fileindex.txt" ) ;
 
		$text.="<TR><TD><A href=\"$webpath/$file\">$file</a>" ;
		if (exists $desc{$file}) { $text .=" $desc{$file} " ; }
		$text.= "</TD></TR>\n" ;
		}
		closedir DIR ;
$text .=<<END;
    
    </TABLE>
  </TD>
</TR>
</TABLE>
END
	$lin= $pre. $text , $post ;
	}
	}
	$$var{$place} = join //, @array  ;	

}}

#-------Webber proccessors -------------
#---------- Main program -----------------
if ($0 =~ /$name/) { &help; die ("
"); }

# required to make a compliance perl module
1;


