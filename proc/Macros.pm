#!/usr/bin/perl
#
#
# $Id: Macros.pm,v 1.4.2.1 2008/07/31 15:01:43 paco Exp $
# 
# New version of the Macros Module
package Macros;


#use Tie::File::AsHash; 
use DB_File ;
use HTML::Entities;
use strict ;

my $name ="Macros" ;
my $version= "0.2" ;

my %defs = (
	'macros.place' 			=> 'wbbIn' ,
	'macros.indexdir.listingvar'	=> 'all:all' ,
	'macros.indexdir.usestyle'	=> '' ,
	'macros.indexdir.file'		=> 'wbbdir.cfg' ,
	'macros.indexdir.dir'		=> '.' ,
	'macros.indexdir.sep'		=> '<br>' ,
	) ;

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





my $debug ;

#sub macro {} ;

#
# Default values for vars
#---------Info subrutine---------------------------------
sub info {
	print "$name v$version:  Macros for webber\n" ;
}

#--------Help subrutine-----------------------------------
sub help {
 print <<FINAL;

This module includes macros to include files
in the source files, so you don't need to copy the
information in the wbb source.
 
The macros included in this release are:

if using the Macros::macro processor.
  
* #dir( ), 	This is an automatic directory include 
  macro  "#dir(realpath,webserverpath,regex)"  would be 
  expanded with a list of files that matched the regex
  (regex in perl code)

  It will use the use "fileindex.txt" in the realpath directory
  to obtain a description of each file, the format of this file 
  is filename: description.

  This processor modifies by defaults wbbin, but this can be
  change using the variable "dir.place and setting this to wbbout

* #includefile ( ) include a txt file in the , three arguments,
  #includefile(file,search,replace), file is the file to include,
  search and replace are regex to be used, to replace text in
  the file. file is HTMLEncoded. (by default) to avoid problems
  with HTML TAGS.

* #includecode() , like includefile, but the file is included without
  any chnage (usuful for including HTML or other language code.

* #listfrom file() , include a txt file, similar to #includefile,
  but include the information in a file.
 
* #tablefromcsv(), create a table (type 2,http://www.rediris.es/app/webber/guia/), 
  receive up to four arguments, CSV file, fields to print (numeric,
  separated by ":" , and a search / replace expression

* #printindex(indexfile), print an index based on the information 

* #servar (Var, value), set the value of var variable to a new value
 
* #var(var) ,put in the putput the value of var.

* #indexdir(type,webber_vars) produces an HTML listing (directory, based
  in subdirectories and the contents of some webber vars, it requires two arguments
  type: can be ul, ol, dt, (the three type of HTML lists.
  webber_var is a list of webber vars to put.

  This processors parses the wbbdir.cfg files in a group of subdirectories and produces
  the HTML listing , see the documentation 
  
* #execute: Execute a list webber modules,
---

Using the Macros::AddIndex

 AddIdex: Add an entry to an index files, this is executed on
        each page that we want to be part of the index.
- Makeindex: Read the index file and generate the HTML output.

What's an index ?
        An index is a filename that contains information about
the webbered pages, it's deffined as follow:

#index.name= indexname
#index.name.type= [simple, duplicates]
#index.name.file = file
#index.name.key = Key to add to the index
#index.name.value = value to add

Note: For key and value , you can use any text or the
value of a webber variable (for example \$var(Page))


For example , assuming that all the webber pages contains an
#owner variable, we can have an index showing the owner of
each page .

#index.name= owner
#index.owner.type= simple
#index.owner.file = \$env(REPOSITORIO/WWW/aux/index.owner.idx)
#index.owner.key = \$var(urlpage)
#index.ownervalue = owner

 If we want to have an index listing the owner of the pages
as the key.

How to use this processor.

1.  Add the Index::AddIndex to the list of processor to be running
with webber.


FINAL
}

sub tablefromcsv {
	my $file= $_[0] ;
	my $fields = $_[1] ;
	my $search= $_[2];
	my $replace=$_[3];
	debug (1, "processing tablefromcsv directive\n") ;
	my $txt=<<FIN;
<TABLE>
<TR>
FIN

	my $lin ;
	my @fieldstoprint ;
	my @t ;
#	print STDERR  "los campos son $fields\n" ;
	if ($fields=~/:/ ) {  @fieldstoprint = split /:/, $fields ;}
	open FILE , $file || print STDERR "ERROR file $file not found!!!\n" ;
	$lin = <FILE> ; # primera linea los nombres 
	chomp $lin ;
	@t = split /,/, $lin ;
	if ($fields=~/:/ ) {
		chomp $lin;
#		print STDERR "Hay que tener campos @fieldstoprint\n" ;
		for (my $i =0 ; $i!=@fieldstoprint ; $i++ ) {
			$txt.= "<TD>$t[$fieldstoprint[$i]-1]</TD>\n" ;
		}
	}
	else {
		for (my $i =0 ; $i!=@t ; $i ++) {
		$txt.="<TD>$t[$i]</TD>\n";
	}
	}
	$txt .= "</TR>\n" ;
	while ($lin = <FILE>) {
		chomp $lin ;
		if (($search ne "" ) &&  ($replace ne "") ) {
#			print STDERR "se hace cambio en $lin\n" ;
			$lin =~ s/$search/$replace/ ;
		}
		if ($lin=~/,/) { # quedan campos a imprimir
		$txt .= "<TR>\n" ;
		@t= split /,/, $lin ;
#		print STDERR "lineas vale $lin\n";
#		for (my $k=0 ;$k!=@t ; $k++ ) { print STDERR "t[$k] vale $t[$k]\n" ;  }
		if ( $fields=~/:/) {
		for (my $i =0 ; $i!=@fieldstoprint ; $i++ ) {
		$txt .= "<TD>$t[$fieldstoprint[$i]-1]</TD>\n" ;
		}}
		else {
		for (my $i =0 ; $i!=@t ; $i++ ) {
		$txt .= "<TD>$t[$i]</TD>\n" ;
		}
		}
		$txt .= "</TR>\n";
		}
	}
	close FILE ;
	$txt .= "</TABLE>\n";
#	print STDERR "Se retornaria\n $txt\n" ;
	return $txt ;
}

sub listfromfile {
	my $file= $_[0] ;
	my $search= $_[1];
	my $replace=$_[2];
	debug (1, "processing listfromfile directive\n" ) ;
	my $txt = "<ul>\n" ;
	my $lin ;
	open FILE , $file || print STDERR "ERROR file $file not found!!!\n" ;
	while ($lin = <FILE>) {
		if ( ($search ne "" ) &&  ($replace ne "") ) {
			$lin =~ s/$search/$replace/ ;
		}
		chomp $lin ;
		$txt .= "<li> $lin </li>\n";
	}
	close FILE ;
	$txt .= "</ul>\n";
#	print STDERR "Se retornaria\n $txt\n" ;
	return $txt ;
}

sub includecode {
        my $file= $_[0] ;
        my $search= $_[1];
        my $replace=$_[2];
        debug (2,  "processing includecode directive\n" ) ;
        my $txt ;
        my $lin ;
        open FILE , $file || print STDERR "ERROR file $file not found!!!\n" ;
        while ($lin = <FILE>) {
                if (($search ne "" ) &&  ($replace ne "" ) ) {
                        $lin =~ s/$search/$replace/  ; }
                $txt .= $lin ;
        }
        close FILE ; 
        return $txt ;
}

sub includefile {
	my $file= $_[0] ;
	my $search= $_[1];
	my $replace=$_[2];
	debug (2, "processing includefile directive\n" ) ;
	my $txt ;
	my $lin ;
	open FILE , $file || print STDERR "ERROR file $file not found!!!\n" ;
	while ($lin = <FILE>) {
		if (($search ne "" ) &&  ($replace ne "" ) ) {
			$lin =~ s/$search/$replace/ ;
		}
#		$txt .= uri_escape ($lin) . "\n";
		$txt .= encode_entities ($lin) ;
	}
	close FILE ;
	#print STDERR "Se retornaria\n $txt\n" ;

	return $txt ;
}


	
sub dir  {
	my $dir= $_[1] ;
	my $webpath= $_[2] ;
	my $regex= $_[3] ;
	my $lin ;
 
   ( $dir, $webpath, $regex, ) = ($dir, $webpath,$regex) ;
   print STDERR  "processing dir directive $dir\n" if ($debug)  ; 
   my   %desc= () ;
   if (-r "$dir/fileindex.txt" ) { # There is an index file
	my ($l,$fn,$fd) ;
	open (FILE, "/$dir/fileindex.txt") ;
	print STDERR  "Reading description from $dir/fileindex.txt\n" if ($debug) ; 
	while ( $l= <FILE> ) { 	($fn,$fd) = split /:/ , $l  ;  $desc{$fn} =$fd ;} 
	close FILE ;

   opendir DIR, $dir ;


my $text=<<END;
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
		while (my $file =readdir (DIR) ) {
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
#	$lin= $pre. $text , $post ;
	$lin = $text ;
}	
	return $lin ;
}


sub indexdir  {
	my $type=$_[0] ;
	my $varpaint =$_[1] ;
	my $var =$_[2] ;
	# Defaults

	my $file = defined ( $$var{'macros.indexdir.file'}) ? $$var{'macros.indexdir.file'} :  $defs{'macros.indexdir.file'} ;
	my $sep =  defined ( $$var{'macros.indexdir.sep'} ) ? $$var{'macros.indexdir.sep'}  :  $defs{'macros.indexdir.sep'}  ;
	my $dirs =  defined ( $$var{'macros.indexdir.dir'} ) ? $$var{'macros.indexdir.dir'}  :  $defs{'macros.indexdir.dir'}  ;
	my $style= defined ( $$var{'macros.indexdir.style'})? $$var{'macros.indexdir.style'}:  $defs{'macros.indexdir.style'};
#	debug 1, "Aqui var macros vale $$var{'macros.indexdir.listingvar'}" ;
	my ($vartocheck, $value ) = split /:/, defined ($$var{'macros.indexdir.listingvar'}) ? $$var{'macros.indexdir.listingvar'} : $defs{'macros.indexdir.listingvar'}  ;



	my @varsto_paint=split /:/, $varpaint ;
	my $varindex = shift (@varsto_paint) ;
	debug (1, "processing indexdir macros.indexdir.dir =  $$var{'macros.indexdir.dir'}  def=  $defs{'macros.indexdir.dir'}  directive now") ;
#	print STDERR "vars content =$vars\n" ;
#	print STDERR "key index= $varindex , other vars are : " . join "," , (@varsto_paint)  ."\n" ; 
	my $txt ="" ;

	if ($type eq "ul" )  { $txt .= "<ul>\n" ; }
	elsif ($type eq "ol") { $txt .= "<ol>\n" ; }
	elsif ($type eq "dl") { $txt .= "<dl>\n" ; }

	my %hash_temporal ;
	my %listing ;
#	debug 1, "directory is $dirs" ;
	foreach my $dir (split /\s+/ , $dirs) {
	#printf STDERR "DIR=$dir\n" ;
	 opendir DIR, $dir ;
	my $direntry ;
                while ($direntry =readdir (DIR) )  {
#			print STDERR "DIR_ENTRY=$direntry\n" ;
#			debug (1,"direentry= $direntry");
                        next if ($direntry =~ /^\..*/ )  ;
#			debug (1,"Se saltan los puntos, direntry eq $direntry") ;
                        next unless -d "$dir\/$direntry" ;
#			debug (1, "hay que leer el fichero $dir\/$direntry\/$file") ;
			if (-r "$dir/$direntry\/$file" ) { # Only index directories with the propper file
		#	   debug (1,"reading file $dir\/$direntry\/$file") ;
			   %hash_temporal = () ; # Empty the temporal hash 
		#	   print STDERR  "reading $dir\/$direntry\/$file\n" ;
			   main::readVars ( "$dir\/$direntry\/$file" , "-" , \%hash_temporal ) ;
		
			  # Temporaly creating the entry ...
			  my $description ="" ;
			#  print STDERR "PACOBUG: valor = $varsto_paint[0] , value = $hash_temporal{$varsto_paint[0]}\n" ;
			  for (my $i =0 ; $i!=@varsto_paint ; $i ++ ) {
					$description .=  $sep  .  $hash_temporal{$varsto_paint[$i]} ;
					if ($i < (@varsto_paint ) -1 ) { $description .= $sep ; }
			  }
			 # print STDERR "description created = $description\n" ;
		#	 debug (1, "vartocheck = $vartocheck value= $hash_temporal{$vartocheck} valuetocheck=$value") ;
		#	print STDERR  "PREIFvartocheck = $vartocheck value $hash_temporal{$vartocheck} valuetocheck=$valu\n" ;
                         if ( ($vartocheck eq "all") || (defined ($hash_temporal{$vartocheck}) && ( $hash_temporal{$vartocheck} eq $value )))  {
#			 debug (1,"si que se imprime la info") ;
			 if( ($type eq "ul") || ($type eq "ol") ) {
				 my $pre ; if ($dir =~ /^\//) { $pre="" ; } else {$pre=$dir ; } ; 
				 $listing{"$hash_temporal{$varindex}:$direntry"} = "<li><a href=\"$pre\/$direntry/\">$hash_temporal{$varindex}</a>$description</li>\n" ;
#		#		 print STDERR "clave  = $hash_temporal{$varindex}:$direntry \n" ; 	
			 }
			  elsif ($type eq "dl") {
#		#		print STDERR "clave  = $hash_temporal{$varindex}:$direntry \n" ;
			 	  my $pre ; if ($dir =~ /^\//) { $pre="" ; } else {$pre= $dir  . "/" ; } ; 	
				  $listing{"$hash_temporal{$varindex}:$direntry"} = "<dt><a href=\"$pre$direntry/\">$hash_temporal{$varindex}</a></dt>\n<dd>$description</dd>\n" ;
			}
	  		   
			} 
		#	else {debug( 1, "Found var $vartocheck set to $value" ) ; }
			}
	#		else { debug (1,  "found directory, $direntry, but not file $$var{'macros.indexdir.file'} inside it" ) ; }
		}
	}
	# Join all all the listing 	
	foreach my $k  (sort {uc($a) cmp uc($b)} keys %listing ) {
			$txt .= $listing{$k} ;
			}
	
	#  end and return 
	if ($type eq "ul" )  { $txt .= "</ul>\n" ; }
        elsif ($type eq "ol") { $txt .= "</ol>\n" ; }
        elsif ($type eq "dl") { $txt .= "</dl>\n" ; }

        return $txt ;
}


## PARSER

sub macro {
        my $lin="" ;
        my  $var = $_[0];
        my $place =  defined ($$var{'macros.place'}) ? $$var{'macros.place'} : $defs{'macros.place'} ;
	my %desc ;
	my @array ;

	$debug=1 ;	
#----- Gets the values for the variables

#  Ok, 
	@array = split /\n/, $$var{$place} ;

 
	foreach (my $j=0 ; $j!=@array ; $j++ ) {
		$lin =$array[$j] ;
		if ($lin =~ /(.*)#dir\((.*),(.*),(.*)\)(.*)/ ) {
			if ($lin =~ /\\#dir/ ) { $lin =~ s/\\#dir/#dir/ ; next ;}
		$lin = $1 . dir ($2,$3,$4) . $5 ; }
		elsif  ($lin =~ /(.*)#includefile\((.*),(.*),(.*)\)(.*)/) {
		if ($lin=~ /\\#includefile/ ) { $lin =~ s/\\#includefile/#includefile/ ; next; }
		$lin = $1 . includefile($2,$3,$4) .$5 ; }
		elsif  ($lin =~ /(.*)#includecode\((.*),(.*),(.*)\)(.*)/) {
                if ($lin=~ /\\#includecode/ ) { $lin =~ s/\\#includecode/#includecode/ ; next; }
                $lin = $1 . includecode($2,$3,$4) .$5 ; }
		elsif  ($lin =~ /(.*)#listfromfile\((.*),(.*),(.*)\)(.*)/) {
		if ($lin =~ /\\#listfromfile/) {$lin=~ s/\\#listfromfile/#listfromfile/; next ; }
		$lin = $1 . listfromfile($2,$3,$4) . $5 ; }
		elsif ($lin  =~ /(.*)#tablefromcsv\((.*),(.*),(.*),(.*)\)(.*)/) {
		if ($lin =~ /\\#tablefromcsv/) { $lin=~ s/\\#tablefromcsv/#tablefromcsv/ ; next;}
		$lin = $1 . tablefromcsv($2,$3,$4,$5) .$6 ;}
		elsif ($lin =~ /(.*)#indexdir\((.*),(.*)\)(.*)/ ) {
                        if ($lin =~ /\\#indexdir/ ) {  print "STDERR es un comentario \n" ;$lin =~ s/\\#indexdir/#indexdir/ ; next ;}
                $lin = $1 . indexdir ($2,$3,$var) . $4 ; }
		elsif ($lin =~ /(.*)#setvar\((.*),(.*)\)(.*)/ ) { # setvar solamente fija una variable
			if ($lin =~ /\\#setvar/ ) { next ; }
			$$var{$2} = $3  ;   $lin =  $1 . $4 ; 
		}	
                elsif ($lin =~ /(.*)#var\((.*)\)(.*)/ ) { # Imprimer una variable
                        if ($lin =~ /\\#var/ ) { next ; }
                         $lin =  $1 . $$var{$2} . $3 ; 
                }
		elsif ($lin =~ /(.*)#execute\((.*)\)(.*)/) { # Execute a set of webber processors 
			if ($lin =~ /\\#execute/)  { next ; }
			$lin = $1 . execute ($2,$var) . $3 ; 
		}
		$array[$j] =$lin . "\n"  ;
	}
	$$var{$place} = join "", @array  ;	

}

sub execute {
	my $proc=shift ;
	my $var=shift ;
    my $thisp ;
   if ($proc ne "") {
       my @tempo = split /\s+/, $proc ;
      foreach $thisp (@tempo) {
         next unless $thisp =~ /\w+/ ;
         debug (1," Executing webber Processor  $thisp inside Macros.pm ..." ) ;
         my ($package, $sname) = split /::/,$thisp;
         require $package .".pm" ;
         &$thisp( $var );
      }
   }
   return "" ;
}
   
sub AddIndex {



        my $refvar=$_[0] ;
 		my $separator =":" ;
        foreach my $key  (keys %$refvar)  {
                next unless $key =~ /index.(.*).file/ ;
                my $index = $1 ;
                
                debug (1, "Found index $index \n" ) ;
                my $filename= $$refvar{"index.$index.file"} ;
                
               debug(3, "Index $index key   = $$refvar{\"index.$index.key\"}") ;
               debug (3, "Index $index value = $$refvar{\"index.$index.value\"}") ;
              
#                tie my  %hash, 'Tie::File::AsHash', $filename , split => "$separator" ||
#                		die "Index problems with file= $filename $! \n" ;
		tie my %hash , 'DB_File',  $filename || 
				die "Index problems with file=$filename $! \n" ;

              	my $key = $$refvar{"index.$index.key"} ;
              	my $value=$$refvar{"index.$index.value"} ;
              	
              	if ($key   =~/.*var\((.*)\)/ ) {
              					 debug (3,"Evaluating key  value of $1 sohuld be $$refvar{\"$1\"}") ; 
              					 $key =~ s/$1/$$refvar{"$1"}/ ; }
                if ($value =~/.*var\((.*)\)/ )  {
                				  debug (3,"Evaluating value value of $1") ;
                				  $value =~ s/$1/$$refvar{"$1"}/ ; }
              	             			
                if ($$refvar{"index.$index.type"} eq "simple" )    {$hash{$key} = $value ; }
                elsif  ($$refvar{"index.$index.type"}  eq "duplicates" ) { $hash{$key} .=  $value . ":" ; }
                untie %hash ;
                }


}
#-------Webber proccessors -------------
#---------- Main program -----------------
if ($0 =~ /$name/) { &help; die ("
"); }

# required to make a compliance perl module
1;


