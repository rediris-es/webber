#!/usr/bin/perl -w 
#
# BodyFaq processor 
#

package BodyFaq ;

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


my $name=	"BodyFaq";
my $version=	"0.7";

my %defs = (
	'#bodyfaq.pretoc' => "<h1><center>Indice de Contenidos</center></h1><hr><p><ul>" ,
	'#bodyfaq.postoc' => "</ul><p>" , 
	'#bodyfaq.tocsty' => "<li><a href = \"#VALUE\"> VALUE CODE </a></li>" ,
	'#bodyfaq.entrys' => "<h2><a name = \"VALUE\"> CODE </a></h2><p>" ,
	'#bodyfaq.sep'    => "TIT" , 
	'#bodyfaq.place'  => 'wbbOut' , 
) ;
my $defpretoc="<h1><center>Indice de Contenidos</center></h1><hr><p><ul>" ;
my $defpostoc="</ul><p>" ;
my $deftocsty="<li><a href = \"#VALUE\"> VALUE CODE </a></li>" ;
my $defentrys="<h2><a name = \"VALUE\"> CODE </a></h2><p>" ;
my $defsep="TIT" ;
my $defplace="wbbout" ;

sub info
{
 print "$name $version:\t Make a HTML FAQ with TOC\n" ;
}

sub help
{
   print <<FINAL;
$name 

Webber processor, version $version
This program must run inside Webber.

This processor composes a HTML page with a Table of Contents (TOC)
at the start of the page. The format of this table can be defined
by the Webber template. The table of contents can be multilevel.
Each of the entries of the TOC is an hyperlink referencing the
beginning of the text in the page.

The variables used by this processor are:
   #bodyfaq.pretoc: HTML code to put before the TOC
   #bodyfaq.postoc: HTML code to put after the TOC
   #bodyfaq.tocsty: HTML code for each of the entries in the TOC
   #bodyfaq.entrys: HTML code used to format each reference
   #bodyfaq.sep: Tag Separator for each entry
   #bodyfaq.place: Webber varible where the results will be placed, usually
     this will be wbbIn or wbbOut but also can be any other variable
For #bodyfaq.tocsty and #bodyfaq.entrys, the tokens VALUE and CODE are
replaced by the current number and reference in the TOC.

The default values are:
  #bodyfaq.pretoc : $def{'bodyfaq.pretoc'}
  #bodyfaq.postoc : $def{'bodyfaq.postoc'}
  #bodyfaq.tocsty : $def{'bodyfaq.tocsty'}
  #bodyfaq.entrys : $def{'bodyfaq.entrys'}
  #bodyfaq.sep    : $def{'bodyfaq.sep'} 
  #bodyfaq.place  : $def{'bodyfaq.place'}

FINAL
}

sub incr {
	#
	# Add a level to arg1 
	# arg2 is the level to add
	# if arg1= x.x.x.y
	# and arg2 = 4 then return x.x.x.z
	# if arg2 eq 3
	# return x.x.y
	my $level =$_[0] ;
	my $poss = $_[1] ;
	$poss ++ ;
	#print ("incr called with $level, $poss \n") if $debug;
	my $return ="" ;
	$level="0" if ($level eq "") ;
	my @codes= split /\./, $level ;
	my @copia=() ;
	my ($i,$t) ;
	my $lab =@codes ;
	if ($lab == $poss)  { 
		$codes[$lab-1] ++ ;
		return join (".", @codes) ;
		}
	elsif ($poss < $lab) {
		$codes[$poss-1] ++ ;
		for ($i=0 ; $i!=$poss ; $i++) {
		$copia[$i]=$codes[$i] ;
		}
		return join ".", @copia ;
		}
	else {
		for ($i=0 ; $i!=$poss ; $i++) {
		$copia[$i]=0 ;}
		for ($i=0 ; $i!=$lab ; $i++) {
		$copia[$i]=$codes[$i] ; }
		$copia[$poss-1] ++ ;
		return join ".", @copia ; }	
}
		
		
		
sub bodyfaq
{
   my $var =  $_[0] ;
   debug (1, "BodyFaq::bodyfaq se ejecuta") ;

   my ($pretoc,$postoc,$tocsty, $entrys, $sep,$i, @array,$level,$value,@toc ) ;
   my ($salida) ;
   $salida = "<!-- Webber proc $name v$version -->\n";
   debug( 1, "OK Going to play !!!\n");

    $pretoc=  (defined $$var{'bodyfaq.pretoc'}) ?  $$var{'bodyfaq.pretoc'} : $def{'bodyfaq.pretoc'} ;
    $postoc=  (defined $$var{'bodyfaq.postoc'}) ?  $$var{'bodyfaq.postoc'} : $def{'bodyfaq.postoc'} ;
    $tocsty=  (defined $$var{'bodyfaq.tocsty'}) ?  $$var{'bodyfaq.tocsty'} : $def{'bodyfaq.tocsty'} ;
    $entrys=  (defined $$var{'bodyfaq.entrys'}) ?  $$var{'bodyfaq.entrys'} : $def{'bodyfaq.entrys'} ;
    $sep=     (defined $$var{'bodyfaq.sep'})    ?  $$var{'bodyfaq.sep'}    : $def{'bodyfaq.sep'} ;
    $place =  (defined $$var{'bodyfaq.place'})  ?  $$var{'bodyfaq.place'}  : $def{'bodyfaq.place'} ;
 
		
    $level=1 ;
    $label="0" ;
    $value="" ;
    @toc=() ;
    @array=split /\n/, $$var{$place} ;

    for ($i=0 ; $i!=@array ; $i++) {
    	if ($array[$i] =~ /^\s*$sep([0-9]*):(.*)/ ) {
#	if ($array[$i] =~ /^TIT/ ) {

		#codigo de la faq
		debug (5, "DEBUG: Found tag $array[$i] !!") ;
		$level=$1 ;
		if ($level eq "") {
			$level=0 ;
			debug (5,  "DEBUG: A cero mark !!!\n")  ;
			}
		$print = $array[$i] ;
		$code=$2 ;
		$label=incr($label,$level) ;
		debug (5, "DEBUG: change to $label\n") ;

		# OK Let's to compose the toc entry
		$tentry=$tocsty ;
		$tentry=~ s/VALUE/$label/g ;
		$tentry=~ s/CODE/$code/ ;
		push @toc, $tentry ;
		debug ( 5,  "DEBUG: pushed $tentry") ;
		# and the line
		$line =$entrys ;
		$line =~ s/VALUE/$label/g ;
		$line =~ s/CODE/$code/ ;
		push @lines,$line ;
		debug( 5, "DEBUG: pushed $line \n") ;
		}
		
       else { debug (2,  "DEBUG Not found $sep in $array[$i]");
		push @lines, $array[$i] ; }
	}

    $salida .= $pretoc . "\n" ;
    for ($i=0 ; $i!=@toc ; $i++) {
    	$salida .= $toc[$i] . "\n" ; }

    $salida .= $postoc . "\n" ;
    for ($i=0 ; $i!=@lines ; $i++) {
    	 $salida .=$lines[$i] . "\n" ; }

    $$var{$place} = $salida ;
    
}


if ($0 =~ /$name/) { &help; die ("\n"); }

1;
