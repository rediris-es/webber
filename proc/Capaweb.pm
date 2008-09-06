#!/usr/bin/perl
#
# A Webber processor for variable extraction from tagged data
#
# (c) RedIRIS 2000
#
package Capaweb;

my $name="Capaweb";
my $version="1.0";

my @flags = ('keep', 'multi', 'span');
my $varkey = 'capaweb';

sub info {
   print "$name v$version: Extracts Webbers vars from tagged data\n";
}

sub help {
   print <<FINAL
$name 

Webber processor, version $version
Extracts Webber variables from tagged data (HTML, XML,...).
This progran must run inside Webber.
It modifies any Webber variable, as defined below.

$name should be used as (one of) the first pre-processor(s).

$name uses the following Webber variables:

 #wbbSource:       The source file to be used for variable extraction.
 #capaweb.VARNAME: Where VARNAME is the name of a Webber variable. Depending
                   on the value of the variable, $name assigns a value for
                   VARNAME taken from the contents of the source file.
The value of a $name variable has to comply to the following format:
  StartTag EndTag ['<'ListOfFlags'>']
Where:
 * StartTag is the tag that marks the beginning of the value to be assigned
   to VARNAME.
 * EndTag is the tag that marks the end of the value to be assigned to
   VARNAME.
 * ListOfFlags is an optional (comma separted) list of flags that control
   the behavior of $name when extracting the value for VARNAME.
   Supported flags are:
   * keep: By default, tags identified by StartTag and EndTag are not included
     into VARNAME. If the 'keep' flag is used, these tags are included.
   * multi: Directs $name to extract multiple values for VARNAME. This means
     that the value of VARNAME will be an expression suitable for building
     an array by means of an 'eval' statement.
   * span: Since value extraction performed by $name is done by means
     of regular expressions, if this flag is used the regular expression will
     be a 'greedy' one.

For example, to assign the value of the body of an HTML page to #wbbIn, the
following syntax can be used:
 #capaweb.wbbIn= <BODY> </BODY> <span>
And to assign to #hd an expression that can be used to assign (by 'eval')
to an array the values of the contents inside the tags <i> and </i>
(including the tags themselves):
 #capaweb.hd= <i> </i> <multi,keep>
FINAL
}

sub capaweb {
   my $var = $_[0] ;
   $$var{'wbbOut'} .= "<!-- Webber proc $name v$version -->\n";
   my ($i, $j, $k, $d, $kva);
   my %cva;
   for $k (keys %$var) {
      ($d, $kva) = split /\./,$k;
      next if ($d ne $varkey);
      if ($$var{$k} =~ /^<(.*?)>\s*<(.*?)>\s*<(.*?)>\s*$/) {
         $cva{$kva}->{start} = "<$1.*?>";
         $cva{$kva}->{end} = "<$2.*?>";
         my @tf = split /,\s*/,$3;
         foreach $i (@tf) {
            foreach $j (@flags) {
               if ($i eq $j) { $cva{$kva}->{$j} = 1; }
            }
         }
      }
      elsif ($$var{$k} =~ /^<(.*?)>\s*<(.*?)>\s*$/) {
         $cva{$kva}->{start} = "<$1.*?>";
         $cva{$kva}->{end} = "<$2.*?>";
      }
      else {
         print STDERR "$name: Syntax error for variable $k. Ignored\n";
      }
   }

   open SOURCE, $$var{"wbbSource"};
   my $as = join '',<SOURCE>;

   for $k (keys %cva) {
      my $re = "";
      if (exists $cva{$k}->{span}) { $re = ".*"; }
      else { $re = ".*?"; }
      if (exists $cva{$k}->{keep}) {
         $re = "($cva{$k}->{start}$re$cva{$k}->{end})";
      }
      else {
         $re = "$cva{$k}->{start}($re)$cva{$k}->{end}";
      }
      if (exists $cva{$k}->{multi}) { 
         my @tv = ($as =~ /$re/simg);
         $$var{$k} = "(";
         foreach $i (@tv) { 
            $i =~ s/"/\\"/smg;
            $$var{$k} .= "\"$i\",\n";
         }
         chop $$var{$k}; chop $$var{$k};
         $$var{$k} .= ");";
      }
      else {
         $as =~ /$re/sim;
         $$var{$k} = $1;
      }
   }
}

if ($0 =~ /$name/) { &help; die ("\n"); }

1;
