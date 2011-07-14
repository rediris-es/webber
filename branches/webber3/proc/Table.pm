#!/usr/bin/perl
##

# Webber processor to construct tables and lists from databases

package Table;

my $name=	"Table";
my $version=	"1.1";

my ( %renderParams );

my %tblStyle = (
	'1' => 'BGCOLOR="#B7AE9C" CLASS="tbTit"' ,
	'2' => 'BGCOLOR="#1A7f84" CLASS="tbTit2"' ,
	'default' => 'BGCOLOR="#B7AE9C" CLASS="tbTit"' );

sub info {
   print "$name v$version: Include a table with #dbName into #wbbOut\n";
}

sub help
{
   print <<FINAL
$name

Webber processor, version $version
This program must run inside Webber.

Substitutes in #wbbOut the ocurrences of <table/> tags.
It should be used after main processors or even as a post-processor.

The <table/> tag is replaced with an HTML table or list, depending on the
definition of a record template (liTempl variable).

The variables used by this processor are:
   #dbName: the name of the database (format below)
   #dbSelect: selection condition to show or not a record (format below)
   #liTempl: template to print every element as a list (format below)
   #dbFields: are the fields to be shown (use db defaults if not defined)
   #tblType: table type (actually, just the type of the header row)

If #liTempl is defined, neither #dbFields nor #tblType are used.

On #liTempl and #dbSelect variables, any appearance of ${fieldname} gets
replaced with the value of fieldname field for every record.

If we use field1::field2 on #dbFields, field1 is actually used for the
table elements, and field2 is used as an hyperlink.

The database is just a text file with a simple format. The first line must
began with 'CODE-+-', being followed by the list of the field names. Each
record line starts with a unique id, before the different field values, and
uses '-+-' as field separator.


If there is more than one table to print, we should use the Table::Multiple
as processor. Each table must have a unique name, which is prepended to the
standard Table variable name (dot separated). The tags must include these
names, using the format <table db=tablename/>.
In adition, an extra variable is recognized:
   #tables: list of names used for the different tables

FINAL
}

sub ReadDB($$){
    my ($db_file,$db_name) = @_;
    my (@codes,@captions,@fields);

    open(DBF,"$db_file")
     || die "ERROR ( ReadDB ) : Cannot read db_file $db_file\n";

    while (<DBF>) {
        chomp;
        my @line = split(/-\+-/);
        my $code = shift @line;
        if ( $code eq 'CODE' ) {
            @fields = split / / , shift @line;
        } elsif ( $code eq 'CAPTION' ) {
            my $capt_name = shift @line;
            push @captions , $capt_name;
            @line = ( "" ) if ( $#line == -1 );
            $$db_name{'caption'}{$capt_name} = shift @line;
        } else {
            push @codes , $code;
            for my $field ( @fields ) {
                @line = ( "" ) if ( $#line == -1 );
                my $value = shift @line;
                $$db_name{$code}{$field} = $value;
                }
            }
        }
    close DBF;

    $$db_name{'fields'} = [ @fields ];
    $$db_name{'codes'} = [ @codes ];
    $$db_name{'save'} = [ @codes ];
    $$db_name{'captions'} = [ @captions ];
    }

sub printHeader {
   my $id = shift;
   my $outval;
   $outval .= "<TR>\n";

   foreach $field ( @{$renderParams{$id}{'fields'}} ) {
      $f = $field; $f =~ s/::[^:]+$//;
      $outval .= "<TD $renderParams{$id}{'headerStyle'}>$f</TD>\n";
      }
   $outval .= "</TR>\n";
   return $outval;
   }

sub printRecord {
   my ( $code , $id , $dbhash ) = @_;
   my $outval;
   $outval .= "<TR>\n";
   foreach $field ( @{$renderParams{$id}{'fields'}} ) {
      if ( $field =~ /^(.*)::([^:]+)$/ ) {
         $outval .= '<TD BGCOLOR="#EFECE3" valign="top">'.
           "<A HREF='$$dbhash{$code}{$2}'>$$dbhash{$code}{$1}</A></TD>";
      } else {
         $outval .= '<TD BGCOLOR="#EFECE3">'."$$dbhash{$code}{$field}</TD>\n";
         }
      }
   $outval .= "</TR>\n";
   return $outval;
   }

sub renderTable {
    my ( $id , $dbname , $dbFields ) = @_;

    my %DATABASE;
    ReadDB "$dbname.db" , \%DATABASE ;

    $fields = $dbFields || $DATABASE{'caption'}{'shown'};
    if ( $fields ) {
       @{$renderParams{$id}{'fields'}} = split / / , $fields;
    } else {
       @{$renderParams{$id}{'fields'}} = @{$DATABASE{'fields'}};
       }

    my $html = '<TABLE BGCOLOR="#888877" BORDER="0" CELLPADDING="4" CELLSPACING="1">';
    $html .= printHeader $id;

    foreach $code ( @{$DATABASE{'codes'}} ) {
       next unless eval $renderParams{$id}{'select'} ;
       $html .= printRecord( $code, $id , \%DATABASE );
       }

    $html .= "</TABLE>\n";

    $html =~ s+@+<IMG SRC="/iconos/template/arr.gif">+g;
    return $html
    }

sub renderList {
    my ( $id , $dbname ) = @_ ;

    my %DATABASE;
    ReadDB "$dbname.db" , \%DATABASE ;

    $html = "<UL>\n";
    foreach $code ( @{$DATABASE{'codes'}} ) {
       next unless eval $renderParams{$id}{'select'} ;
       $html .= "<LI>";
       $html .= eval $renderParams{$id}{'template'} ;
       $html .= "\n" ;
       }

    $html .= "</UL>\n";
    $html =~ s+@+<IMG SRC="/iconos/template/arr.gif">+g;
    return $html
    }

sub Multiple {
   $var = $_[0] ;

   foreach $id ( split / / , $$var{'tables'} ) {
      my $dbname = $$var{$id.'.dbName'};

      if ( $$var{$id.'.dbSelect'} ) {
         $renderParams{$id}{'select'} = $$var{$id.'.dbSelect'};
         $renderParams{$id}{'select'} =~ s/\$\{([^{}]+)\}/\$DATABASE{\$code}{'$1'}/g;
      } else {
         $renderParams{$id}{'select'} = 1;
         }

      if ( $$var{$id.'.liTempl'} ) {
         $renderParams{$id}{'template'} = $$var{$id.'.liTempl'};
         $renderParams{$id}{'template'} =~ s/\$\{([^{}]+)\}/\$DATABASE{\$code}{'$1'}/g;

         $htmlPiece{$id} = renderList ( $id , $dbname );
      } else {

         if ( $$var{$id.'.tblType'} ) {
            $renderParams{$id}{'headerStyle'} = $tblStyle{$$var{$id.'.tblType'}};
         } else {
            $renderParams{$id}{'headerStyle'} = $tblStyle{'default'};
            }

         $htmlPiece{$id} = renderTable( $id , $dbname , $$var{$id.'.dbFields'} );
         }

      $$var{'wbbOut'} =~ s+<TABLE DB=$id/>+$htmlPiece{$id}+i;
      }

   }

sub Single {
   $var = $_[0] ;

   my $id = 'single';
   my $dbname = $$var{'dbName'};

   if ( $$var{'dbSelect'} ) {
      $renderParams{$id}{'select'} = $$var{'dbSelect'};
      $renderParams{$id}{'select'} =~ s/\$\{([^{}]+)\}/\$DATABASE{\$code}{'$1'}/g;
   } else {
      $renderParams{$id}{'select'} = 1;
      }

   if ( $$var{'liTempl'} ) {
      $renderParams{$id}{'template'} = $$var{'liTempl'};
      $renderParams{$id}{'template'} =~ s/\$\{([^{}]+)\}/\$DATABASE{\$code}{'$1'}/g;

      $htmlPiece = renderList ( $id , $dbname );
   } else {
      if ( $$var{'tblType'} ) {
         $renderParams{$id}{'headerStyle'} = $tblStyle{$$var{'tblType'}};
      } else {
         $renderParams{$id}{'headerStyle'} = $tblStyle{'default'};
         }

      $htmlPiece = renderTable( $id , $dbname , $$var{'dbFields'} );
      }

   $$var{'wbbOut'} =~ s+<TABLE/>+$htmlPiece+i;
   }

if ($0 =~ /$name/) { &help; die ("\n"); }

1;
