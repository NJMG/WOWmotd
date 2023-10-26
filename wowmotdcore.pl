#!/usr/bin/env perl

use strict;
use warnings;
no strict 'refs';    # else Can't use string ("value") as a SCALAR ref

# use feature "switch"; # remplacer par du pure perl ( for; foreach)
#use v5.14; # like use feature "switch , given ,then ";
#no warnings 'experimental'; # given, when is experimental


use Time::HiRes qw(usleep nanosleep);
use Scalar::Util qw(looks_like_number);
##use utf8;
## Solve Perl "Wide Character in Print": no warnings 'utf8' or (and) use  open ":std", ":encoding(UTF-8)";
no warnings 'utf8';
use open ":std", ":encoding(UTF-8)";
## test if in shell term else exit:
my $is_tty = -t STDIN && -t STDOUT;

if ( !$is_tty ) {
    exit(0);
}
#####################################################
#####################################################
#####################################################
# init global:
# get term char sizes ( make it package variables, global with our )
# $wchar : nb of column (characters) in the current terminal
# $hchar : nb of lines in the current terminal
our $wchar;
our $hchar;
our $wpixels;
our $hpixels;

if ( $ENV{COLUMNS} ) {
    $wchar = $ENV{COLUMNS} + 0;
    $hchar = $ENV{LINES} + 0;
}
else {
    use Term::ReadKey;

   # ( our $wchar, our $hchar, our $wpixels, our $hpixels ) = GetTerminalSize();
    ( $wchar, $hchar, $wpixels, $hpixels ) = GetTerminalSize();
}

our $debug = 0;

# init array lines:
our @Alines;
our @Alines2;
our @Alfinn;
our @Ahexpanse;
our $hexpanse = 0;
our $lmax;
our $GTmpLen = 0;

# default values
our %opts = (
    ConfLine => 0,
    Align    => "left",
    FillChar => " ",
    FGColor  => "\e[0m",
    BGColor  => "\e[0m",
    MaxWs    => 0,
    MaxLines => 0,

    ClearScreen => 0,

    # ScrollTimeSec => 0,
    ScrollDurationSec => 0,
    ScrollDelay       => 0,
    GetMaxCol         => 0,

    # fixedCol => 0,
    TplColumns => 0,

    Delim_Scalar      => ':',
    Delim_FillChar    => '*',
    Delim_FillLine    => '%',
    Delim_RepeatWLine => '+',
    Delim_EOL         => '$',
);

#####################################################
#####################################################
#####################################################

sub runnew {
    my ($file) = @_;
    if ( not defined $file ) {
        die "run() need the template file";
    }
    if ( -e $file ) {
        open( my $info, '<:encoding(UTF-8)', $file )
          or die "Could not open $file: $!";
        @Alines = <$info>;
        close($info);
        linesnewread(@Alines);
    }
    else {
        die "Could not find: $file: $!";
    }
}

###########################################################################################
sub runwall {
    my ( $wall, $tpl ) = @_;
    if ( not defined $wall ) {
        die "run() need the wall template file";
    }
    if ( -e $wall ) {
        open( my $info, '<:encoding(UTF-8)', $wall )
          or die "Could not open $wall: $!";
        @Alines = <$info>;
        close($info);

        # lineswallread(@Alines);
    }
    else {
        die "Could not find: $wall: $!";
    }
    if ( $tpl && -e $tpl ) {
        open( my $info, '<:encoding(UTF-8)', $tpl )
          or die "Could not open $tpl: $!";
        @Alines2 = <$info>;
        close($info);

        # lineswallread(@Alines);
    }
    if (@Alines) { lineswallread(@Alines); }
}

###########################################################################################
sub linesnewread {
    my (@alines) = @_;
    my $confline;
    my $lilen;
    my $tplCol;

    if (@alines) {
        $confline = testopts1( $alines[0] );
        if ($confline) {
            shift(@alines);
        }
        if ($debug) {
            print "align: ",    $opts{'Align'},    "\n";
            print "FillChar: ", $opts{'FillChar'}, "\n";
            print "BGColor: ",  $opts{'BGColor'},  "\n";
            print "FGColor: ",  $opts{'FGColor'},  "\n";
            print "FGColor: ",  $opts{'FGColor'},  "\n";
            print "Maxlines: ", $opts{'MaxLines'}, "\n";
        }

        if ( $opts{'ScrollDurationSec'} && ( scalar @alines > $hchar ) ) {
            $opts{'MaxLines'} = 0;
        }

        if ( $opts{'MaxLines'} ) {
            $lmax = $opts{'MaxLines'};
        }
        else {
            $lmax = scalar @alines;
        }
        $tplCol = $opts{'TplColumns'};
        foreach my $i ( 0 .. $#alines ) {
            my $li = $alines[$i];

            # if ($li) {
            $li =~
              s/[\r\n]+$//;  # remove line endings \n ( & win line endings \r\n)
            if ( $li !~ /^\s*$/ ) {    # if not only spaces:
                $lilen = length( delcolors($li) );
                if ( $tplCol and ( $tplCol > $lilen ) ) {
                    $li = str_w_spaces( $li, $tplCol, 1 );
                }
            }

            genarr( $li, $i );

            # }

        }

        if ($hexpanse) {
            if ( !$opts{'MaxLines'} ) {
                $lmax = $hchar;
            }
            prosaexp( $hexpanse, scalar @alines );
        }
        genarline(@Alfinn);
    }
}

###########################################################################################
sub lineswallread {
    my (@alines) = @_;
    my $lmax;

    $opts{'MaxLines'} = $hchar - 3;
    $lmax = $opts{'MaxLines'};

    if ( $#alines < $lmax ) {
        $lmax = $#alines;
    }

    foreach my $i ( 0 .. $lmax ) {
        my $li = $alines[$i];
        $li //= '';
        if ($li) {
            $li =~
              s/[\r\n]+$//;  # remove line endings \n ( & win line endings \r\n)
        }
        genlinewall($li);
    }
}

###########################################################################################
sub genlinewall {
    my ($li) = @_;
    my @ecolors = hecolors( $li, $wchar );
    my $linecut;
    if (@ecolors) {
        my $add = $wchar - int( $ecolors[-1][0] );
        $linecut = substr( $li, 0, $ecolors[-1][1] + $add );
    }
    else {
        $linecut = substr( $li, 0, $wchar );
    }
    print $linecut , "\n";
}

sub hecolors {
    my ( $li, $charmax ) = @_;
    my @ecolors;
    my $totlength = 0;
    my $realpos   = 0;
    my $count     = 0;
    while ( $li =~ m/(\e\[[0-9;]*m(?:\e\[K)?)+/g ) {
        my $cpos = pos($li);
        $totlength += length($1);
        $realpos = $cpos - $totlength + 0;

        # stop while si $realpos > $wchar
        last if ( $realpos >= $charmax );

        $ecolors[ $count++ ] = [ $realpos, $cpos, length($1), $1 ];

    }
    return @ecolors;
}

###########################################################################################
sub testopts1 {
    my ($lconf) = @_;
    my @optsa;
    my $align;
    my $str;
    my $len;

    if ( $lconf =~ /<\!([^>]+)>/ ) {
        my $match1 = \$1;    #  ex => <!C>
        if ($$match1) {
            @optsa = split( /,/, $$match1 );
            foreach my $i ( 0 .. $#optsa ) {
                $str = ltrim( $optsa[$i] );
                $len = length( ltrim( $optsa[$i] ) );
                if ($len) {
                    if ($debug) {
                        print $str , '::', $len, "\n";
                    }
                    testoptskeys( $str, $len );
                }
            }
            return $opts{'ConfLine'} = 1;
        }
    }
}

sub testoptskeys {
    my ( $str, $len ) = @_;
    my ( $key, $val ) = split( /:/, $str );

    # given (substr($str, 0, 2)) {
    # given ($key) {
        # when ('AC') { $opts{'Align'} = 'center'; }
        # when ('AL') { $opts{'Align'} = 'left'; }
        # when ('AR') { $opts{'Align'} = 'right'; }
        # when ('CHR') { getchartofill($val); }
        # when ('BGC') { bgcolortofill($val); }
        # when ('FGC') { fgcolortofill($val); }
        # when ('ML')  { maxlines($val); }
        # when ('SC')  { scroller($val); }
        # when ('SD')  { scrolldelay($val); }
        # when ('CLR') { clearer($val); }
        # when ('TC')  { setcolums($val); }
    # }

	for ($key) {
		if ($key eq 'AC') { $opts{'Align'} = 'center'; last; }
		if ($key eq 'AL') { $opts{'Align'} = 'left'; last; }
		if ($key eq 'AR') { $opts{'Align'} = 'right'; last; }
		if ($key eq 'CHR') { getchartofill($val); last; }
		if ($key eq 'BGC') { bgcolortofill($val); last; }
		if ($key eq 'FGC') { fgcolortofill($val); last; }
		if ($key eq 'ML') { maxlines($val); last; }
		if ($key eq 'SC') { scroller($val); last; }
		if ($key eq 'SD') { scrolldelay($val); last; }
		if ($key eq 'CLR') { clearer($val); last; }
		if ($key eq 'TC') { setcolums($val); last; }
	}

}

sub isnumb {
    my ($val) = @_;
    if ( looks_like_number($val) ) { return 1; }
}


sub setcolums {
    my ($val) = @_;
    if ( isnumb($val) ) {
        $opts{'TplColumns'} = $val + 0;
    }
}

sub getchartofill {
    my ($val) = @_;
    $opts{'FillChar'} = $val;
}

sub bgcolortofill {
    my ($val) = @_;
    $opts{'BGColor'} = $val;
}

sub fgcolortofill {
    my ($val) = @_;
    $opts{'FGColor'} = $val;
}



sub maxlines {
    my ($val) = @_;
    if ( isnumb($val) ) {
        $val = int($val);
        if ( $val < 0 ) {
            $opts{'MaxLines'} = $hchar + $val;
        }
        else {
            $opts{'MaxLines'} = $val;
        }
    }
}

sub scroller {
    my ($val) = @_;

    # $val = int($val);
    # print $val, "\n";
    if ( isnumb($val) && $val > 0 ) {
        $opts{'Scroll'}            = 1;
        $opts{'ScrollDurationSec'} = $val + 0;
    }
}

sub scrolldelay {
    my ($val) = @_;

    # $val = int($val);s
    # print $val, "\n";
    if ( isnumb($val) && $val > 0 ) {
        $opts{'ScrollDelay'} = $val + 0;
    }
}

sub clearer {
    my ($val) = @_;

    # $val = int($val);
    # print $val, "\n";

    if ( isnumb($val) && $val > 0 ) {
        $opts{'ClearScreen'} = 1;
    }

}

###########################################################################################
sub genarr {
    my ( $li, $i ) = @_;
    my @Vitems;
    my @Fitems;
    my @Litems;
    my $lilen;

    while ( $li =~ /(<(.)([^<]*?)>)+?/g ) {
        my $match1 = \$1;
        my $match2 = \$2;
        my $match3 = \$3;

        # ex :	$match1 = <:V1>
        #		$match2 = :
        #		$match3 = V1
        if ($$match2) {
            if ( not defined $$match3 || $$match3 eq '' ) {
                $$match3 = ' ';
            }    # '<*>' is like fill with spaces
            # given ($$match2) {

                # #### when (':') { push @Vitems, [$$match1, $$match3]; } # <:V1>
                # when ( $opts{'Delim_Scalar'} ) {
                    # push @Vitems, [ $$match1, $$match3 ];
                # }    # <:V1>

                # # '*' fill with chars or spaces
                # #### when ('*') { push @Fitems, [1, $$match1, $$match3]; } # [ 1, <*█>, █ ]
                # when ( $opts{'Delim_FillChar'} ) {
                    # push @Fitems, [ 1, $$match1, $$match3 ];
                # }    # [ 1, <*█>, █ ]

                # # '@' fill with void space ( for tpl incrustation with runwall)
                # # when ('@') { push @Fitems, [ 0, $$match1, $$match3 ]; }

                # #### when ('%') { push @Litems, [1, $$match1]; }
                # # when ('-') { push @Litems, [ 0, $$match1 ]; }
                # when ( $opts{'Delim_FillLine'} ) {
                    # push @Litems, [ 1, $$match1 ];
                # }
                # when ( $opts{'Delim_RepeatWLine'} ) {
                    # push @Litems, [ 2, $$match1 ];
                # }
                # when ( $opts{'Delim_EOL'} ) { push @Litems, [ 3, $$match1 ]; }
            # }

			for ($$match2) {
				if ( $$match2 eq $opts{'Delim_Scalar'}) {
                    push @Vitems, [ $$match1, $$match3 ]; last;
                } # <:V1>

				if ($$match2 eq $opts{'Delim_FillChar'}) {
                    push @Fitems, [ 1, $$match1, $$match3 ]; last;
                } # [ 1, <*█>, █ ]

				if ($$match2 eq $opts{'Delim_FillLine'}) {
					push @Litems, [ 1, $$match1 ]; last;
                }

				if ($$match2 eq $opts{'Delim_RepeatWLine'}) {
					push @Litems, [ 2, $$match1 ]; last;
				}

				if ($$match2 eq $opts{'Delim_EOL'}) {
					push @Litems, [ 3, $$match1 ]; last;
				}
			}
        }
    }

    # 1 SCALAR ref process first!
    if (@Vitems) {
        $li = sgenvars( $li, \@Vitems );
    }

    # 2.1 remove Litems tag(s) from string
    if (@Litems) {

        # 1 remove Litems tag(s) from string:
        $li = remlitems( $li, \@Litems );
    }

    # 2.2 check line lenght :
    $li = checkwarnlenght( $li, $i, \@Fitems );

    # 2.3 repeatwline if Litems =  Delim_RepeatWLine :
    if ( @Litems and $Litems[0][0] == 2 ) {
        $li = repeatwline( $li, \@Litems );
    }

    # 3 FILL process:
    if (@Fitems) {
        $li = sgenfill( $li, \@Fitems );
    }

    # recalculate $lilen
    $lilen = length( delcolors($li) );


    # 4 line expance
    # if Delim_FillLine :
    if ( @Litems and $Litems[0][0] == 1 ) {

        # $li = sgenhline($li,\@Litems); # WORK
        # $Alfinn[$i] = [ $Litems[0][0] , $li];
        ##$Alfinn[$i] = [$li];
        ##$Alfinn[$i] = { EXL => $li };


        # array $Alfinn[$i] = [$line, $linelength, $expanse]:
        $Alfinn[$i] = [$li, $lilen, 1];
        ++$hexpanse;
    }
    else {
        $Alfinn[$i] = [$li, $lilen, 0];
    }
}
#####################################################

sub checkwarnlenght {
    my ( $li, $i, $Fitems_aref ) = @_;
    my $linb;

    # if is 100% whitespace:
    if ( $li =~ /^\s*$/ ) {
        $li = '';
        return $li;
    }

    my $sa = scalar @$Fitems_aref + 0;
    # $GTmpLen variable globale
    $GTmpLen = length( delcolors($li) );

    my $tmpLen = $GTmpLen - ( $sa * 2 );

    if ( $tmpLen > $wchar ) {
        $linb = $i + 1;

        # $li = "Error: Line bigger than terminal size";
        die "Error: in Line $linb ($GTmpLen char) bigger than terminal size: $wchar !";
    }

    return $li;

}

# a Tester
sub repeatwline {
    my ( $li, $Litems_aref ) = @_;

    # my $lilen = length( delcolors($li) );
    my $lilen = $GTmpLen;
    my $linecut;
    my $coeff;
    my $addnbchars;
    my $add;
    my $addcut;

    # print "\$lilen: ", $lilen, "\n";
    if ( $lilen < $wchar ) {

        $addnbchars = $wchar - $lilen;

        # print "\$addnbchars: ", $addnbchars, "\n";

        if ( $addnbchars > $lilen ) {
            $coeff = int( $addnbchars / $lilen );

            # print "\$coeff: ", $coeff, "\n";
            $li         = $li x ( $coeff + 1 );
            # $lilen      = length( delcolors($li) );
            $lilen      = $GTmpLen x ( $coeff + 1 );
            $addnbchars = $wchar - $lilen;

            # print "\$addnbchars: ", $addnbchars, "\n";
        }

        my @ecolors = hecolors( $li, $addnbchars );
        if (@ecolors) {
            $add = $addnbchars - int( $ecolors[-1][0] );
            $addcut = $ecolors[-1][1] + $add;
            $linecut = substr( $li, 0, $ecolors[-1][1] + $add );
        }
        else {
            $addcut = $addnbchars;
            $linecut = substr( $li, 0, $addnbchars );
        }

        $li = $li . $linecut;
        # update $GTmpLen:
        $GTmpLen = $lilen + $addcut + 0;


    }
    return $li;
}

sub prosaexp {
    my ( $hex, $nbalines ) = @_;
    my $Llen    = $lmax - $nbalines + $hex;
    my $Lmodulo = $Llen % $hex;
    my $Ldiv;

    foreach my $i ( 0 .. ( $hex - 1 ) ) {
        $Ldiv = int( $Llen / $hex );
        if ($Lmodulo) {
            ++$Ldiv;
            --$Lmodulo;
        }

        # print "\$Ldiv: ", $Ldiv, "\n";
        $Ahexpanse[$i] = $Ldiv;
    }
}
#####################################################

sub genarline {
    my (@Alfinn) = @_;
    my @Alnew;
    my $li;
    my $exp;
    my $count  = 0;
    my $micros = 0;

    # my $scroll = 0;
    my $delay           = 0;
    my $scrolllinestart = 0;

    if ($hexpanse) {
        foreach my $i ( 0 .. $#Alfinn ) {
            # if ( ref( $Alfinn[$i] ) eq 'ARRAY' ) {
            #     $exp = shift @Ahexpanse;
            #     $li  = sgenalign( $Alfinn[$i][0] ) . "\n";
            # }


            # if ( ref( $Alfinn[$i] ) eq 'HASH' ) {
            #     $exp = shift @Ahexpanse;
            #     $li  = sgenalign( $Alfinn[$i]{EXL} ) . "\n";
            # }
            # else {
            #     $exp = 1;
            #     $li  = sgenalign( $Alfinn[$i] ) . "\n";
            # }
            $exp = 1;
            if ( $Alfinn[$i][2] == 1 ) {
                  $exp = shift @Ahexpanse;
            }
            $li  = sgenalign( $Alfinn[$i][0], $Alfinn[$i][1] ) . "\n";

            if ( $exp > 1 ) {
                foreach my $i ( 1 .. $exp ) {
                    $Alnew[ $count++ ] = $li;
                }
            }
            else {
                $Alnew[ $count++ ] = $li;
            }

            # print $li x $exp;
        }
    }
    else {
        foreach my $i ( 0 .. ( $lmax - 1 ) ) {

            if ( $Alfinn[$i][0] ) {
                $li = sgenalign( $Alfinn[$i][0], $Alfinn[$i][1] ) . "\n";
            }
            else {
                $li = "\n";
            }

            # print $li;
            $Alnew[ $count++ ] = $li;
        }
    }

    if ( $opts{'ClearScreen'} ) {
        clearterm();
    }

    # print $opts{'ScrollTimeSec'} ,"\n";
    if ( ( $opts{'ScrollDurationSec'} + 0 ) > 0 ) {

        # $scroll = 1;
        $micros = ( $opts{'ScrollDurationSec'} * 1000000 ) / ( $#Alnew + 1 );

        if ( $opts{'ScrollDelay'} > 0 ) {
            $delay = $opts{'ScrollDelay'} + 0;
        }

        if ( $opts{'ScrollafterLine'} ) {
            $scrolllinestart = $opts{'ScrollafterLine'};
        }

        if ( $opts{'ScrollafterVisible'} ) {
            $scrolllinestart = $hchar - 1;
        }

        if ( !$scrolllinestart ) {
            print "\n" x $hchar;
        }

    }

    foreach my $i ( 0 .. $#Alnew ) {

        # system "sleep 0.02";
        # Sleep for 25 milliseconds
        # select(undef, undef, undef, 0.025);
        # 10 millisecond == 10000 microseconds
        if ( $micros && ( $i >= $scrolllinestart ) ) {

            if ($delay) {
                usleep( $delay * 1000000 );
                $delay = 0;
            }

            usleep( int($micros) );
        }

        print $Alnew[$i];
    }

}

#####################################################

sub sgenalign {
    my ($li, $lilen) = @_;
    my $align = $opts{'Align'};

    # my $fixedCol = $opts{'fixedCol'};

    # is 100% whitespace (remember 100% of the empty string is also whitespace)
    # use /^\s+$/ if you want to exclude the empty string
    if ( $li =~ /^\s*$/ ) {
        return $li;
    }

    #my $lilen = length( delcolors($li) );

    # if ( $fixedCol and ($fixedCol > $lilen)) {
    # $li = str_w_spaces( $li, ($fixedCol), 1);
    # # $lilen = length(delcolors($li));
    # $lilen = $fixedCol;
    # }

    my $lentoWFill = $wchar - $lilen;
    my $lentoWFilldiv2;
    my $modulo;

    if ( $lentoWFill > 0 ) {
        $lentoWFilldiv2 = int( $lentoWFill / 2 );
        # given ($align) {
            # when ('left')  { $li = $li . ' ' x $lentoWFill; }
            # when ('right') { $li = ' ' x $lentoWFill . $li; }
            # when ('center') {
                # $modulo = $lentoWFill % 2;
                # if ( $modulo > 0 ) {
                    # $li =
                        # ' ' x $lentoWFilldiv2
                      # . $li
                      # . ' ' x ( $lentoWFilldiv2 + 1 );
                # }
                # else {
                    # $li = ' ' x $lentoWFilldiv2 . $li . ' ' x $lentoWFilldiv2;
                # }
            # }
        # }

		for ($align) {
			if ($align eq 'left') 	{ $li = $li . ' ' x $lentoWFill; last; }
			if ($align eq 'right') 	{ $li = ' ' x $lentoWFill . $li; last; }
			if ($align eq 'center') {
				$modulo = $lentoWFill % 2;
                if ( $modulo > 0 ) {
                    $li =
                        ' ' x $lentoWFilldiv2
                      . $li
                      . ' ' x ( $lentoWFilldiv2 + 1 );
                }
                else {
                    $li = ' ' x $lentoWFilldiv2 . $li . ' ' x $lentoWFilldiv2;
                }
			last;
			}
		}


    }
    return $li;
}

#####################################################

sub remlitems {
    my ( $li, $Litems_aref ) = @_;
    my $tag;

    for my $row (@$Litems_aref) {
        $tag = quotemeta "@{$row}[1]";

        # remove tag and all spaces after if any:
        # $li =~ s/$tag\s*?$//;
        # remove tag and all chars after if any:
        $li =~ s/$tag.*?$//;
    }
    return $li;
}

#####################################################
sub sgenvars {
    my ( $li, $array_ref ) = @_;
    my $var;
    my $lenforvars;
    for my $row (@$array_ref) {
        $var        = trim( delcolors( @{$row}[1] ) );
        $lenforvars = length( delcolors( @{$row}[0] ) );
        if ( ref($$var) eq 'ARRAY' ) {
            $$var = formavar( $$var, $lenforvars );
        }
        $li =
          str_replace( @{$row}[0], str_w_spaces( $$var, $lenforvars ), $li );
    }
    return $li;
}

#####################################################
sub sgenfill {
    my ( $li, $Fitems_aref ) = @_;
    # my $lilen = length( delcolors($li) );
    my $lilen = $GTmpLen;
    my $lentoFill;
    my $Fmodulo;
    my $Fstrlen;
    my $Fchar;
    my $Fitems_len = 0;
    my $Fvoids_len = 0;

    for my $row (@$Fitems_aref) {

        # pi : @{$row}[0] = 0 or 1
        # pi : @{$row}[1] = $$match1 :: <*█>
        # pi : @{$row}[2] = $$match1 :: █
        $lilen -= length( delcolors( @{$row}[1] ) );
        ++$Fitems_len;
    }
    $lentoFill = $wchar - $lilen;
    $Fmodulo   = $lentoFill % $Fitems_len;
    for my $row (@$Fitems_aref) {
        $Fstrlen = int( $lentoFill / $Fitems_len );
        if ($Fmodulo) {
            ++$Fstrlen;
            --$Fmodulo;
        }
        $Fchar = substr( delcolors( @{$row}[2] ), 0, 1 );
        if ( $Fchar eq '' ) { $Fchar = ' '; }    # if <*> => <* > ou <@> => <* >
        $li = str_replace( @{$row}[1], $Fchar x $Fstrlen, $li );
    }
    return $li;
}

#####################################################
#####################################################
#####################################################

sub delcolors {
    my ($this_str) = @_;
    $this_str //= '';
    $this_str =~ s/\e\[[0-9;]*m(?:\e\[K)?//g;
    return $this_str;
}

sub getcolors {
    my ($this_str) = @_;
    $this_str //= '';
    $this_str =~ m/(\e\[[0-9;]*m(?:\e\[K)?)+/;
    if ($1) {
        return $1;
    }
}

sub str_replace {

    # str_replace($1, $2, $3) => return new $3
    # my $replace_this = shift; # $1
    # my $with_this  = shift; # $2
    # my $string   = shift; # $3
    my ( $replace_this, $with_this, $string ) = @_;
    $replace_this //= '';
    $with_this    //= '';
    $string       //= '';
    my $strlen = length($string);
    my $target = length($replace_this);

    for ( my $i = 0 ; $i < $strlen - $target + 1 ; $i++ ) {
        if ( substr( $string, $i, $target ) eq $replace_this ) {
            $string =
                substr( $string, 0, $i )
              . $with_this
              . substr( $string, $i + $target );
            return $string;    # Comment this if you want a global replace
        }
    }
    return $string;
}

sub str_w_spaces {

    # my $this_str = shift; # $1 ( str )
    # my $total_length = shift; # $2 ( length to expect )
    my ( $this_str, $total_length, $nocolor ) = @_;
    my $lenstr;
    $this_str     //= '';
    $total_length //= 0;
    $nocolor      //= 0;

    $nocolor
      ? ( $lenstr = length( delcolors($this_str) ) )
      : ( $lenstr = length($this_str) );

    my $addlength = $total_length - $lenstr;
    if ( $addlength > 0 ) {
        return $this_str . ( ' ' x $addlength );
    }
    return $this_str;
}

sub trimmer {
    my ($str) = @_;
    $str =~ s/^\s+|\s+$|\n$//g;
    return $str;
}

# trim remove white space from both ends of a string
sub trim {
    my ($str) = @_;
    $str =~ s/^\s+|\s+$//g;
    return $str;
}

sub ltrim {
    my ($str) = @_;
    $str =~ s/^\s+//;
    return $str;
}

sub rtrim {
    my ($str) = @_;
    $str =~ s/\s+$//;
    return $str;
}

sub formavar {
    my ( $array_ref, $lenforvars ) = @_;
    my $sizerray = scalar @$array_ref;
    my $delim;
    my $delimcolor;
    my $lensize;
    my $str;
    my $b_right //= 0;

    if ( $sizerray == 2 ) {

        if ( length( delcolors( $array_ref->[0] ) ) > 1 ) {
            $str        = $array_ref->[0];
            $delimcolor = getcolors( $array_ref->[1] );
            $delim      = delcolors( $array_ref->[1] );
        }
        else {
            $str        = $array_ref->[1];
            $delim      = delcolors( $array_ref->[0] );
            $delimcolor = getcolors( $array_ref->[0] );
            $b_right    = 1;
        }

        $lensize = $lenforvars - length( delcolors($str) );

        $delimcolor //= "";
        if ($b_right) {
            return $delimcolor . $delim x $lensize . $str;
        }
        else {
            return $str . $delimcolor . $delim x $lensize;
        }
    }

    if ( $sizerray == 3 ) {
        $delim = substr( delcolors( $array_ref->[1] ), 0, 1 );
        $delimcolor = getcolors( $array_ref->[1] );

        # if ($delimcolor) { print "delimcolor:$delimcolor" ;}
        $lensize =
          $lenforvars -
          (
            length( delcolors( $array_ref->[0] ) ) +
              length( delcolors( $array_ref->[2] ) ) );
        if ( $lensize < 0 ) {
            $lensize = 0;
        }
        $delimcolor //= "";
        return
            $array_ref->[0]
          . $delimcolor
          . $delim x $lensize
          . $array_ref->[2];
    }

    # return scalar @$array_ref;
}

###########################################################################################
sub getfuptime {
    my $prettytime;
    my $uptime = qx(cat /proc/uptime | awk '{print \$1}');
    $uptime //= 0;

    # my @parts = gmtime($uptime);
    #     0    1    2     3     4    5     6     7
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday ) =
      gmtime($uptime);
    if ($yday) { $prettytime .= "$yday" . 'd '; }
    if ( $yday || $hour ) { $prettytime .= "$hour" . 'h '; }
    if ( $hour || $min )  { $prettytime .= "$min" . 'm '; }
    if ( !$hour ) { $prettytime .= "$sec" . 's'; }

    return $prettytime;
}

###########################################################################################
# figlet
sub genfigletaref {
    my ($cmd) = @_;
    my $fgc;
    my @afgc;
    if ($cmd) {
        $fgc = qx($cmd);
        @afgc = split( "\n", "$fgc" );

        # return ref array
        return \@afgc;
    }
}

###########################################################################################
# clear term
sub clearterm {
    system $^O eq 'MSWin32' ? 'cls' : 'clear';
}

# need to be true :
1;
