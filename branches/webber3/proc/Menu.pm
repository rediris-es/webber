#!/usr/bin/perl
#
# Webber processor for simply printing the contents of #wbbIn
#

package Menu;

use strict ;
no strict "subs";


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
		my $rh = {} ;
		my $tmp = $i ;
		while ($tmp =~ s/<(.*)>(.*)<\/\1>//msi ) {
			my $key= $1 ;
			my $value =$2 ; 
			$$rh{$key} = $value ;
			debug (3, "key=$key , value=$value") ;
#			$tmp =~ s/<$key>$value<\/$key>//gi ; 
			debug (3, "queda $tmp despues eliminacion de $key y $value\n" ) ;
		}		
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
	'menu.li.template' => "<li><a href=\"\%url\">\%text</a></li>\n" , 
	'menu.td.template' => "<td><a href=\"\%url\">\%text</a></td>\n" 
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


$name must be anywhere in the processor(s)  , list 

$name uses the following Webber variables:

#menu.src: webber var that contains the menu $defs{'menu.src'} , format is src:dst , 
wehere src and dst are webber vars, this allow to process more than one menu in the
same page.

The following vars depends on the value of the previus src definition.
#menu.\$src.pre : HTML code before the menu, (class definition,etc) default= $defs{'menu.pre'}
#menu.\$src.post: HTML code after the menu, (end of list, etc) defaults = $defs{'menu.post'}
#menu.\$type: to have different kind of listing by now only "li", (default), 
#menu.\$src.template:  template , by now \n\t $defs{'menu.template'}
#menu.\$src.template.current:  Templeate to use in to denote "active" or current, this is used
if the "key" is the same of  #menu.\$src.active
 Replace \$src with the name of the src part in the menu.src definition

Note: the format of the menu is the following XML:
<menuitem>
	<key>value</key>
	..
	<keyn>value</key>
</menuitem>
	
   Names of the keys are matched with in the template, replacing the \%key with the key
value.

FINAL
}

sub  menu
{
	my $rh= $_[0] ;
	debug( 1, "Menu:menu se ejecuta\n") ;
	my $menusrc = defined ($$rh{'menu.src'})  ? $$rh{'menu.src'} :   $defs{'menu.src'} ;
	debug 2, "Menus a procesar : $menusrc" ; 
	foreach my $src  (split /\s+/, $menusrc) {
	debug (2, "Processing menu for $src") ;
	# Se mezclan las variables.
     	my $pre = defined ($$rh{'menu.pre'} )  ? $$rh{'menu.pre'} : $defs{'menu.pre'} ;
        my $post= defined ($$rh{'menu.post'})  ? $$rh{'menu.post'}: $defs{'menu.post'};
#        my $type= defined ($$rh{'menu.type'})  ? $$rh{'menu.type'}: $defs{'menu.type'};
        my ($template, $templateli, $templatetd) ;
#        if ($type eq "li") {
         $templateli = defined ($$rh{'menu.li.template'}) ? $$rh{'menu.li.template'} : $defs{'menu.li.template'} ;
 #       }
#        elsif ($type eq "td") {
         $templatetd = defined ($$rh{'menu.td.template'}) ? $$rh{'menu.td.template'} : $defs{'menu.td.template'} ;
#        }
	debug (3, "Default template for  li= $templateli, default template for td = $templatetd") ;
	my ($var , $target ) = split /:/ , $src ;
	debug (2, "Variable origen =$var se escribira el menu en $target") ;
	debug(2, "variables que afectan a este menu : menu.$var.pre menu.$var.post menu.$var.type valores:") ;
	debug(2, "menu.$var.pre = $$rh{\"menu.$var.pre\"}");
	debug(2, "menu.$var.post= $$rh{\"menu.$var.post\"}");
	debug(2, "menu.$var.type= $$rh{\"menu.$var.type\"}");
 
	$pre = defined ($$rh{"menu.$var.pre"} ) ? $$rh{"menu.$var.pre"}  : $pre ;
	$post= defined ($$rh{"menu.$var.post"}) ? $$rh{"menu.$var.post"} : $post ;
	
	my $template_actived="" ;
	if (defined ($$rh{"menu.$var.type"} ) && $$rh{"menu.$var.type"} eq "li") {
		$template= defined ($$rh{"menu.$var.template"}) ? $$rh{"menu.$var.template"} : $templateli ; 
		debug (2, "setting output template to li style = $template") ;
		}

	else {
		debug(3, "XX= menu.$var.type = $$rh{\"menu.$var.type\"}" ) ;
		debug(3, "default template procesador Menu is $defs{'menu.td.template'}") ;
		debug(3, "templated set to $$rh{'menu.td.template'}") ;
		 $template= defined ($$rh{"menu.$var.template"}) ? $$rh{"menu.$var.template"} : $templatetd ;
		debug (2,"setting output template to td style = $template");
		 }
  	  $template_actived= defined ($$rh{"menu.$var.template.current"} ) ? $$rh{"menu.$var.template.current"} : $template ; 
	debug (2, "Menu  $var contenido $$rh{$var}") ;
   	debug (2, "template= $template , templateli=$templateli templatetd=$templatetd") ;  
	my @entries = xml2array ( $$rh{$var} ) ;
	my $output = $pre;
	foreach my $i (@entries) {
		my $lin ;
		#menu.$var.key= indica nombre del valor en las entradas que indica la clave
		debug (3, "menu.$var.key= " . $$rh{"menu.$var.key"}) ;
		debug (3, "menu.$var.active = " . $$rh{"menu.$var.active"}) ;
		if ($$i{$$rh{"menu.$var.key"}} =~ /$$rh{"menu.$var.active"}/ ) {  $lin= $template_actived ;
				debug (3, "menu.$var.key   =". $$i{$$rh{"menu.$var.key"}}  ."\nmenu.$var.active=". $$rh{"menu.$var.active"});
				}
		else {		$lin= $template ; }
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
	
}

if ($0 =~ /$name/) { &help; die ("\n"); }

1;
