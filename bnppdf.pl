#!/usr/bin/perl
use strict;
use warnings;

my $month = 0;
my $year = 0;
my $value;
my $dateop;
my $dateval;
my $comment;

# skip useless header
while (<>) {
  last if /^\s*Date\s+Nature/;
}

# here is the real data
while (<>) {
  # remove useless leading spaces
  $_ =~ s/^\s+//;

  # stop after this line
  last if /^TOTAL\s+DES\s+MONTANTS/;

  # skip useless lines
  next if /^$/;
  next if /^Date\s+Nature/;
  next if /^BNP\s+PARIBAS\s+SA\s+:/;
  next if /^Centre\s+de\s+Relations\s+Clients\s+:/;
  next if /^RELEVE\s+DE\s+COMPTE\s+/;
  next if /^Agence\s+:/;
  next if /^RIB\s+:/;
  next if /^du\s+[0-9]+\s+.*\s+au\s+/;

  # theses are maybe customer specific ? add yours if needed
  next if /^SCPTRELSTREPFN1/;
  next if /^504031310991/;

  # remove spaces in middle of date and amount
  $_ =~ s/([0-9]+)\s*\.\s*([0-9]+)/$1.$2/g;
  $_ =~ s/([0-9\.]+)\s*,\s*([0-9]+)/$1,$2/g;

  # retrieve starting year
  if ( $_ =~ /^SOLDE\s+.*\d{2}\.\d{2}\.20(\d{2})/ ) {
    if (not $year) {
      $year = $1;
    }
    next;
  }

  my $indent;
  my $toggle;
  my $opmonth;
  #            (dateop    )      (comment        )        (dateval   )         (value        )
  if ( $_ =~ /^([0-9\.]{5})\s{2,}((\S|\s{1,29}\S)+)\s{30,}([0-9\.]{5})((\s{2,})([0-9\.\,]{3,}))?/ ) {
    $dateop = $1;
    $comment = $2;
    $dateval = $4;
    if (defined($6)) {
      $indent = length($2.$6.$7);
      $toggle = 69;
      $value = $7;
    }

    # increase $year if we go from month 12 to month 1
    $opmonth = $dateop;
    $opmonth =~ s/\d+\.//;
    if ($opmonth < $month) {
      $year += 1;
    }
    $month = $opmonth;

    # date is expected as DD-MM-YY
    $dateop =~ s/\./-/;
    $dateop .= '-'.$year;
  }
  else {
    #            (comment        )           (value        )
    if ( $_ =~ /^((\S|\s{1,29}\S)+)((\s{30,})([0-9\.\,]{3,}))?/ ) {
      $comment .= ' '.$1;
      if (defined($4)) {
        $indent = length($1.$4.$5);
        $toggle = 165;
        $value = $5;
      }
    }
    else {
      print STDERR "Warning: line not matching any pattern !! '$_'\n";
    }
  }

  # if $value is defined, then print the operation
  if (defined($value)) {
    # remove dot as thousand separator (ie: 1.000 -> 1000)
    $value =~ s/\.//g;
    # use dot as decimal separator (ie: 10,00 -> 10.00)
    # $value =~ s/,/./;
    # if the indentation is below the limit, it is a debit
    if ($indent < $toggle) {
      $value = '-'.$value;
    }
    # debug debit/credit toggle
    #$comment .= ' ('.$indent.')';

    # remove multiple space in comment
    $comment =~ s/\s+/ /g;

    # paymode detection
    # 0 - none
      my $paymode = 0;
    # 1 - credit card
      if ( $comment =~ /^DU \d{6} / )              { $paymode = 1; }
      if ( $comment =~ /^FACTURE\(S\) CARTE / )    { $paymode = 1; }
      if ( $comment =~ /^REMBOURST CB / )          { $paymode = 1; }
    # 2 - check
      if ( $comment =~ /^CHEQUE / )                { $paymode = 2; }
    # 3 - cash
      if ( $comment =~ /^RETRAIT DAB / )           { $paymode = 3; }
    # 4 - transfer
      if ( $comment =~ /^VIRT? SEPA RECU / )       { $paymode = 4; }
      if ( $comment =~ /^VIRT? SEPA EMIS / )       { $paymode = 4; }
      if ( $comment =~ /^VIREMENT SEPA / )         { $paymode = 4; }
      if ( $comment =~ /^VIREMENT RECU TIERS / )   { $paymode = 4; }
      if ( $comment =~ /^VIREMENT FAVEUR TIERS / ) { $paymode = 4; }
      if ( $comment =~ /^VIR EUROPEEN SEPA / )     { $paymode = 4; }
    # 5 - internal transfer
      if ( $comment =~ /^VIRT? CPTE A CPTE / )     { $paymode = 5; }
    # 6 - debit card
    # 7 - standing order (prelevement in fr)
      if ( $comment =~ /^PRLV SEPA / )             { $paymode = 7; }
      if ( $comment =~ /^PRLV EUROPEEN SEPA / )    { $paymode = 7; }
      if ( $comment =~ /^PRELEVEMENT / )           { $paymode = 7; }
    # 8 - electronic payment
      if ( $comment =~ /^TELEREGLEMENT / )         { $paymode = 8; }
    # 9 - deposit
      if ( $comment =~ /^REMISE CHEQUES / )        { $paymode = 9; }
      if ( $comment =~ /^VERSEMENT D'ESPECES / )   { $paymode = 9; }
    #10 - bank fee
      if ( $comment =~ /^FRAIS DE GESTION / )      { $paymode = 10; }
      if ( $comment =~ /^\*INTERETS DEBITEURS / )  { $paymode = 10; }
      if ( $comment =~ /^\*COMMISSIONS / )         { $paymode = 10; }
      if ( $comment =~ /^TIRAGE DE CHEQUES / )     { $paymode = 10; }
      if ( $comment =~ /^COTISATION PROVISIO / )   { $paymode = 10; }

    # use this for homebank >= 4.5 (tag mandatory)
    # print "$dateop;$paymode;;;$comment;$value;;import\n";
    # use this for homebank <= 4.4 
    print "$dateop;$paymode;;;$comment;$value;\n";

    # wait next value
    undef($value);
  }
}

# end of code, below are some notes and specs extracts

# This is a one line debit operation
#15.01      COMMENT LINE 1                                                                                                         15.01                    12,34

# A two lines debit operation
#15.01      COMMENT LINE 1                                                                                                         15.01
#COMMENT LINE 2                                                                                                                                    20,00

# A three or more lines debit operation
#15.01      COMMENT LINE 1                                                                                                         15.01
#COMMENT LINE 2
#COMMENT LINE 4
#COMMENT LINE 5                                                                                                                                    22,00

# alternate : credit operation (and value>999)
#COMMENT LINE 5                                                                                                                                                      1.234,56

# CSV format for homebank ( http://homebank.free.fr/help/misc-csvformat.html )
#* date		(format must be DD-MM-YY)
#* paymode
# 0 - none
# 1 - credit card
# 2 - check
# 3 - cash
# 4 - transfer
# 5 - internal transfer
# 6 - debit card
# 7 - standing order (prelevement in fr)
# 8 - electronic payment
# 9 - deposit
#10 - bank fee
#* info 	a string
#* payee 	a payee name
#* memo 	a string
#* amount 	a number with a '.' or ',' as decimal separator, ex: -24.12 or 36,75
#* category 	a full category name (category, or category:subcategory)
#* tags 	tags separated by space (mandatory since v4.5)
#Example:
#15-02-04;0;;;Some cash;-40,00;Bill:Withdrawal of cash;tag1
#15-02-04;1;;;Internet DSL;-45,00;Inline service/Internet;tag2
