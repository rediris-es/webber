#!/usr/bin/perl
#
# A Webber processor for variable extraction based on an HTML/XML parser
#
# (c) RedIRIS 2000
#
package Caparse;

my $name="Caparse";
my $version="1.69";

#use HTML::Parser 3.00 ();

use HTML::Parser ; 

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

#
# Spec pseudo-DTD
my $inVsp = "n";
my %vAttr = (
   "element" => 1, "mode" => 1, "assign" => 1, "attr" => 1, "separator" => 1,
   "attseparator" => 1,
);
my %valH = ();
#
# HTML pseudo-DTD
my %tagIsEmpty = (
   "br" => "y", "area" => "y", "link" => "y", "img" => "y", "param" => "y",
   "hr" => "y", "input" => "y", "col" => "y", "base" => "y", "meta" => "y",
   "basefont" => "y", "isindex" => "y",
);
my %tagXref = (
   "" => "",
   "head" => { "body" => "o", "html" => "c", },
   "body" => { "html" => "c", },
   "p" => { "p" => "o", "h1" => "o", "h2" => "o", "h3" => "o", "h4" => "o",
            "h5" => "o", "h6" => "o", "ul" => "o", "ol" => "o", "dl"=>"o",
            "pre" => "o", "div" => "o", "blockquote" => "o", "form" => "o",
            "hr" => "o", "table" => "o", "address" => "o", "fieldset" => "o",
            "li" => "o", "dd" => "o", "dt" => "o",
            "body" => "c", "html" => "c", },
   "dt" => { "dd" => "o",
             "body" => "c", "html" => "c", },
   "dd" => { "dd" => "o", "dt" => "o", "dl" => "b",
             "body" => "c", "html" => "c", },
   "li" => { "li" => "o", "ul" => "c", "ol" => "c",
             "body" => "c", "html" => "c", },
   "option" => { "option" => "o", "optgroup" => "b", "select" => "c",
                 "form" => "c", "body" => "c", "html" => "c", },
   "thead" => { "tfoot" => "o", "tbody" => "o", "tr" => "o", "table" => "c",
                "body" => "c", "html" => "c", },
   "tfoot" => { "tbody" => "o", "tr" => "o", "table" => "c",
                "body" => "c", "html" => "c", },
   "tbody" => { "tbody" => "o", "table" => "c",
                "body" => "c", "html" => "c", },
   "tr" => { "tr" => "o", "thead" => "c", "tfoot" => "o", "tbody" => "o",
             "table" => "c", "body" => "c", "html" => "c", },
   "th" => { "td" => "o", "th" => "o", "tr" => "c", "table" => "c",
             "body" => "c", "html" => "c", },
   "td" => { "td" => "o", "th" => "o", "tr" => "c", "table" => "c",
             "body" => "c", "html" => "c", },
);
#
# Structures for variable values
my %cva = ();
my %cvat = ();
my %cvv = ();
my @cvt = ();

sub info {
   print "$name v$version: Variable extraction based on an HTML/XML parser\n"
}

sub help {
   print <<FINAL
$name

Webber processor, version $version.
This progran must run inside Webber.
Parses source files in HTML/XML and extracts from them values for Webber
variables. It modifies any Webber variable, as defined below.

$name should be used as (one of) the first pre-processor(s).

$name uses the following Webber variables:

 #caparse.source: Defines a list of sources to be parsed for extracting
                  variable values. The format of a source specification is:
                     CLASS:NAME
                  Where CLASS can be either "var" (the source is a Webber
                  variable) or "file" (the source is a file), and NAME
                  identifies the source.
                  If this variable does not exist, the file identified by
                  #wbbSource is parsed.
 #caparse.spec:   Specifies how the results of parsing source files should be
                  assigned to Webber variables.
The value of #caparse.spec is composed of a series of <var> tags, each one
of them containing a list of variable names. According to the attributes of
the <var> tag, the values of these variables are assigned by $name.
The attributes recognized for the <var> tag are:
 element      -> Identifies the element of the source file(s) to be used when
                 building the variable values. The special element "comment"
                 may be used for comment processing.
 mode         -> Defines how the values extracted from elements are composed to
                 build the variable values. This attribute may have one of
                 the following values:
                 first   -> Use only the first value found when parsing the
                            source file(s).
                 last    -> Use only the last value found when parsing the
                            source file(s).
                 compose -> Compose all the values found, using the string
                            defined by the attribute "separator". If this
                            attribute is not used, the string " " is used by
                            default.
                 array   -> Compose all the values found, building a string
                            that can be later used for a Perl list assignment
                            using an 'eval' statement.
 assign       -> Defines how the extracted value must be assigned to the
                 Webber variable. This attribute may have one of the following
				 values:
                 overwrite -> The value overwrites the previous value (if any)
                              of the variable (just like `=' in Webber source
                              files). This is the default.
                 append    -> The value is appended to the previous value (if
                              any) of the variable (just like `+' in Webber
                              source files).
                 prepend   -> The value is prepended to the previous value (if
                              any) of the variable (just like `*' in Webber
                              source files).
 separator    -> Defines the string to be used for composing values.
 attr         -> If this attribute is used, variable extraction is performed
                 for the attributes of the element, and not for its content.
                 The value of this attribute is a comma-separated list of
                 element attribute names to be read.
 attseparator -> If the attribute "attr" is used, this attribute specifies
                 the string to be used for composing an individual value from
                 the values of the element attributes. It defaults to " ".

For example, assume we want to assign to #wbbIn the contents of all the body
elements in file "src.hsr" and in variable #caparseSrc, keeping their image
names and sources into a list that can be built using the contents of variable
#imgList.
The corresponding definitions for $name should be:
 #caparse.source= file:src.hsr var:caparseSrc
 #caparse.spec=
 <var element="body" mode="compose" separator="&lt;p&gt;">
 wbbIn
 </var>
 <var element="img" attr="name,src" attseparator=": " mode="array">
 imgList
 </var>
FINAL
}
              
sub caparse {
   %cva = ();
   %cvat = ();
   %cvv = ();
   @cvt = ();
   local $var = $_[0];
   debug 3, "Caparse Se ejecuta" ; 

   my $spParser = HTML::Parser->new(api_version => 3,
                                    handlers => [
                                       start => [\&spStart,"tagname,attr,text"],
                                       end   => [\&spEnd, "tagname"],
                                       text  => [\&spText, "dtext,text"],
                                    ],
                                    strict_names    => 1,
                                    xml_mode        => 1,
                                    unbroken_text   => 1,
                                    marked_sections => 1,);
   my $srcParser = HTML::Parser->new(api_version => 3,
                                      handlers => [
                                        start => [\&start, "tagname,attr,text"],
                                        end   => [\&end, "tagname,text"],
                                        text  => [\&addText, "text"],
                                        comment => [\&comment, "tokens,text"],
                                     ],
                                     unbroken_text   => 1,
                                     marked_sections => 1,);

   $spParser->parse ($$var{"caparse.spec"});
   if (exists $$var{"caparse.source"}) {
      my @srcSp = split /\s/,$$var{"caparse.source"};
      for $thsrc (@srcSp) {
         my ($scc, $scn) = split /:/,$thsrc;
         if ($scc eq "file") {  $srcParser->parse_file ($scn); }
         elsif ($scc eq "var") { $srcParser->parse ($var->{$scn}); }
      }
   }
   else {
      $srcParser->parse_file ($$var{"wbbSource"});
   }

   for my $tk (keys %cva) {
      my $tv = "";
      if ($#{$cvv{$tk}} >= 0) {
         if ($cva{$tk}{mode} eq "last") {
            $tv = $cvv{$tk}[$#{$cvv{$tk}}]{val};
         }
         elsif ($cva{$tk}{mode} eq "compose") {
            $tv = $cvv{$tk}[0]{val};
            for (my $i = 1; $i <= $#{$cvv{$tk}}; $i++) {
               if (exists $cva{$tk}{separator}) {
                  $tv .= $cva{$tk}{separator}.$cvv{$tk}[$i]{val};
               }
               else { $tv .= " ".$cvv{$tk}[$i]{val}; }
            }
         }
         elsif ($cva{$tk}{mode} eq "array") {
            $tv = "('".$cvv{$tk}[0]{val};
            for (my $i = 1; $i <= $#{$cvv{$tk}}; $i++) {
               $tv .= "','".$cvv{$tk}[$i]{val};
            }
            $tv .= "');";
         }
# Default mode is "first"
         else { $tv = $cvv{$tk}[0]{val}; }
      }
      if (exists $cva{$tk}{assign}) {
         if ($cva{$tk}{assign} eq "append") {
            $$var{$tk} .= " " . $tv;
         }
         elsif ($cva{$tk}{assign} eq "prepend") {
            $$var{$tk} = $tv . " " . $$var{$tk};
         }
         else { $$var{$tk} = $tv; }
      }
      else { $$var{$tk} = $tv; }
   }
}
   
sub spStart {
   my ($tag, $atref, $text) = @_;
   my $vat = "y";
   for my $tk (keys %$atref) {
      if (not exists $vAttr{$tk}) {
         $vat = "n";
         last;
      }
   }
   if ($inVsp eq "y" or $tag ne "var" or $vat ne "y" or
       not exists $$atref{element}) {
      print STDERR "Caparse: Error in specification. Ignored:\n\t $text\n";
      return;
   }
   $inVsp = "y";
   %valH = %$atref;
}

sub spText {
   my ($val, $text) = @_;
   if ($inVsp eq "n") { return; }
   my @vNames = split /[\s\n]/,$val;
   for my $vn (@vNames) {
      next if ($vn eq "");
      $cva{$vn} = { %valH };
      if (exists $cvat{$valH{element}}) { ++$cvat{$valH{element}}; }
      else { $cvat{$valH{element}} = 1; }
      @cvv{$valH{element}} = [];
   }
}

sub spEnd {
   my ($tag, $text) = @_;
   if ($inVsp eq "n" or $tag ne "var") {
      print STDERR "Caparse: Error in specification. Ignored:\n\t $text\n";
      return;
   }
   $inVsp = "n";
   %valH = ();
}

sub openTag () {
   my ($tkv, $text) = @_;
   for my $vk (keys %cva) {
      if ($vk eq $tkv) {
         if (exists $cva{$vk}{attr}) {
            push @{$cvv{$vk}}, {"state"=> "c", "val" => ""};
         }
         else {
            push @{$cvv{$vk}}, {"state"=> "o", "val" => ""};
         }
      }
   }
}

sub closeTag () {
   my ($tkv, $text) = @_;
   for my $vk (keys %cva) {
      if ($vk eq $tkv) {
         for (my $i = $#{$cvv{$vk}}; $i >= 0; $i--) {
            if ($cvv{$vk}[$i]{state} eq "o") {
               $cvv{$vk}[$i]{state} = "c";
               last;
            }
         }
      }
   }
}

sub addAttr () {
   my ($tag, $atref) = @_;
   for my $vk (keys %cva) {
      if ($cva{$vk}{element} eq $tag and exists $cva{$vk}{attr}) {
         my $tv = "";
         for my $an (split /[\s\n,]/,$cva{$vk}{attr}) {
            if (exists $$atref{$an}) {
               if ($tv eq "") { $tv = $$atref{$an}; }
               elsif (exists $cva{$vk}{attseparator}) { 
                  $tv .= $cva{$vk}{attseparator}.$$atref{$an};
               }
               else { $tv .= " ".$$atref{$an}; }
            }
         }
         $cvv{$vk}[$#{$cvv{$vk}}]{val} = $tv;
      }
   }
}

sub addText () {
   my ($text) = @_;
   for my $vk (keys %cvv) {
      for (my $i = $#{$cvv{$vk}}; $i >= 0; $i--) {
         if ($cvv{$vk}[$i]{state} eq "o") { $cvv{$vk}[$i]{val} .= $text; }
      }
   }
}

sub start {
   my ($tag, $atr, $text) = @_;
   my $lt = ""; 
   $lt = $cvt[$#cvt] if ($#cvt >= 0);

   if (exists $tagXref{$lt}{$tag} and
       ($tagXref{$lt}{$tag} eq "o" or $tagXref{$lt}{$tag} eq "b")) {
      for my $vk (keys %cva) {
         if ($cva{$vk}{element} eq $tag) { &closeTag ($vk, $text); }
      }
      pop @cvt;
   }
   &addText ($text);
   for my $vk (keys %cva) {
      if ($cva{$vk}{element} eq $tag) { &openTag ($vk, $text); }
   }
   &addAttr ($tag, $atr);
   if (not exists $tagIsEmpty{$tag} and exists $cvat{$tag}) {
      push @cvt, $tag;
   }
}

sub end {
   my ($tag, $text) = @_;
   my $lt = ""; 
   $lt = $cvt[$#cvt] if ($#cvt >= 0);

   if ($lt eq $tag or 
       (exists $tagXref{$lt}{$tag} and
        ($tagXref{$lt}{$tag} eq "c" or $tagXref{$lt}{$tag} eq "b"))) {
      for my $vk (keys %cva) {
         if ($cva{$vk}{element} eq $tag) { &closeTag ($vk, $text); }
      }
      pop @cvt;
   }
   &addText ($text);
}

sub comment {
   my ($tokr, $text) = @_;
   my $faketn = "comment";
   my $lt = "";

   for my $vk (keys %cva) {
      if ($cva{$vk}{element} eq $faketn) {
         $cvv{$vk}[$#{$cvv{$vk}}+1]{val} = $$tokr[0];
      }
   }
   &addText ($text);
}

if ($0 =~ /$name/) { &help; die ("\n"); }

1;
