#!/usr/bin/perl
#
# Webber processor for simply printing the contents of #wbbIn
#

package Menu;

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

sub  xml2array {
# Note incomplete XML parsing ...
        my $cad =$_[0] ;
	debug (3, "menu xml2array:input is $cad" ) ;
        my @tmp= split /<\/menuitem>/msi , $cad  ;
      	my @ret ;
	foreach my $i (@tmp) {
		debug (3, "menuxmlarray processing $i");
		$i =~ /<text>(.*)<\/text>/si ;
		my $text =$1 ;
		$i =~ /<url>(.*)<\/url>/si ;
		$url =$1 ;
		debug (3, "text=$text , url=$url") ;
		my $rh = {
			'text' => $text ,
			'url'  => $url
		} ;
	push @ret, $rh ;
        }
	return @ret ;
}

# End Funcion debug

my %defs= (
	'menu.pre'	=> '',
	'menu.post'	=> '',
	'menu.type'	=> 'li',
	'menu.src'	=> 'menu.var',
	'menu.target'	=> 'menuhere',
	'menu.template' => "<li><a href=\"\%url\">\%text</a></li>\n"
) ;


my $name=	"Menu";
my $version=	"1.0";

sub info {
   print "$name v$version: Produce a HTML listing menu from a XML var\n";
}

sub help
{
   print <<FINAL
$name 

Webber processor, version $version
This program must run inside Webber.

 This proccesor produced a Menu from a webber var in XML format, the
var is pointed by menu.info (default is menu.var, outuput of the menu is
placed in menu.target pointed webber var

the "XML" format is as follow:
<menuitem>
        <text>Text of the enty</text>
        <url>relative or absolute/</url>
</menuitem>
<menuitem>
	....
</menuitem>

Foreach menuitem it will produce a:
<li>< a href="URL"> text </a> </li>


$name must be used as (one of) the last processor(s).

$name uses the following Webber variables:

#menu.pre : HTML code before the menu, (class definition,etc) default= $defs{'menu.pre'}
#menu.post: HTML code after the menu, (end of list, etc) defaults = $defs{'menu.post'}
#menu.type: to have different kind of listing by now only "li", (default), 
#menu.template: Default template , by now \n\t $defs{'menu.template'}
#menu.src: webber var that contains the menu $defs{'menu.src'}
#menu.target: webber var in which we will put the HTML code , defaults $defs('menu.target'}
FINAL
}

sub  menu
{
	my $rh= $_[0] ;
	debug( 1, "(Menu:menu se ejecuta\n") ;
	$pre = defined ($$rh{'menu.pre'} )  ? $$rh{'menu.pre'} : $defs{'menu.pre'} ;
	$post= defined ($$rh{'menu.post'})  ? $$rh{'menu.post'}: $defs{'menu.post'};
	$type= defined ($$rh{'menu.type'})  ? $$rh{'menu.type'}: $defs{'menu.type'};
	$template = defined ($rh{'menu.template'}) ? $$rh{'menu.template'} : $defs{'menu.template'} ;
	$src = defined ($$hrh{'menu.src'})  ? $$rh{'menu.src'} :   $defs{'menu.src'} ;
	$target=defined ($$rh{'menu.target'})? $$rh{'menu.target'}: $defs{'menu.target'} ;
	debug (2, "menuvar= $src = $$rh{$src}") ;

	my @entries = xml2array ( $$rh{$src} ) ;
	my $output = $pre;
	foreach my $i (@entries) {
		my $lin= $template ;
		foreach my $k ( keys %$i)  {
			debug (3, "replacing $k value $$i{$k} in $lin" );
			$lin =~ s/\%$k/$$i{$k}/ ;
			debug (3, "result $lin") ;
		}
	$output .= $lin ;	
	}
	$output .= $post ;
	debug (2, "putting output in $target value is $output") ;
	$$rh{$target} = $output ;
	
}

if ($0 =~ /$name/) { &help; die ("\n"); }

1;
