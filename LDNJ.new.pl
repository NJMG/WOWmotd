#!/usr/bin/env perl
# use strict;
# use warnings;
# use File::Basename;
use File::Spec;
# require "/usr/njperl/motdcorenew.pl";
my $fpath = File::Spec->rel2abs( __FILE__ );
# my $dir =  dirname($fpath);
my ($vol,$dir,$file) = File::Spec->splitpath($fpath);
my $sep = File::Spec->catfile('', '');
# assume "wowmotdcore.pl" in the same directory of the current script:
require $dir . $sep ."wowmotdcore.pl";
#####################################################
#####################################################
#####################################################
# GetTerminalSize from Term::ReadKey ( loaded via motdcorenew.pl)
# get term char sizes ( make it package variables, global with our )
# $wchar : nb of column (characters) in the current terminal
# $hchar : nb of lines in the current terminal
#( our $wchar, our $hchar, our $wpixels, our $hpixels ) = GetTerminalSize();

#####################################################
#####################################################
#####################################################
# template in the same directory of the script( same basename with extension .tpl ):
my $tpl = $dir . $sep . "LDNJ122.new4.utf8ans";

# if ($wchar < 116 ) {
# $tpl =~ s{\.[^.]*?$}{.80.tpl};
# } else {
# $tpl =~ s{\.[^.]*?$}{.120.tpl};
# }

# print $fpath, "\n";

# print $tpl, "\n";
#####################################################
#####################################################
#####################################################
# your custom variables :

# our $VAR1;
# our $VAR1 = `hostname -f | xargs -r`;
# chomp: remove newline in the command if any:
# our $cmdctl = `hostnamectl`;
# our $vreg = $cmdctl;
# $vreg =~ /.*hostname:\s(.+)\s*?$/gm;
# $vreg = $1;


our $Fcmd = "figlet -f small \"$ENV{NJMOTD_HOST}\"";

our $figletarrayref = genfigletaref($Fcmd);

our $T01 = "\e[38;05;21m" . $figletarrayref->[0] . "\e[0m";
our $T02 = "\e[38;05;27m" . $figletarrayref->[1] . "\e[0m";
our $T03 = "\e[38;05;33m" . $figletarrayref->[2] . "\e[0m";
our $T04 = "\e[38;05;39m" . $figletarrayref->[3] . "\e[0m";
our $T05 = "\e[38;05;45m" . $figletarrayref->[4] . "\e[0m";

our $T1 = "SYSTEM INFORMATION:";
our $T11 = ['Hostname:', '.', $ENV{NJMOTD_HOST}];


# $vreg = $cmdctl;
# $vreg =~ /.*System:\s(.+)\s*?$/gm;
# $vreg = $1;
our $T12 = ["\e[0m\e[100;38;5;7m" . "System:", ".", "\e[0m\e[100;38;5;15m" . $ENV{NJMOTD_SYSTEM} ];



# $vreg = $cmdctl;
# $vreg =~ /.*Kernel:\s(.+)\s*?$/gm;
our $T13 = $ENV{NJMOTD_KERNEL};

# our $VAR4 = ['Uptime:', '.', format_uptime('uptime')];

# our ($uptime) = qx(cat /proc/uptime | cut -d'.' -f1);
# our $uptime = qx(cat /proc/uptime | awk '{print $1}');


# # my @parts = gmtime($uptime);
    # # 0    1    2     3     4    5     6     7
# my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) = gmtime($uptime);

# my $prettytime;
# if ( $yday ) { $prettytime .= "$yday" .'d ' ;}
# if ( $yday || $hour ) { $prettytime .= "$hour".'h ' ;}
# if ( $hour || $min ) { $prettytime .= "$min".'m ' ;}
# if ( ! $hour && $sec ) { $prettytime .= "$sec".'s' ;}

# our $VAR4 = ['Uptime:', '.', getfuptime()];
our $T22 = [ '.', getfuptime()];
# our $VAR4 = [ getfuptime(), '.'];


# sub parse_duration {
    # use integer;
    # sprintf("%02d:%02d:%02d", $_[0]/3600, $_[0]/60%60, $_[0]%60);
# }

# printf ("%4d %4d %4d %4d\n",@parts[7,2,1,0]);


# print $1, "\n";
# chomp(our $cmd = `hostname -f | xargs -r`);

# chomp(our $cmd );
# our $VAR1 = $cmd;
# our $VAR1 = ['hostname:', '.', $1];
# our @VAR2 = ('hostname:', '.', $cmd); <= cela ne fct pas

# $VAR1 =~ s/[\r\n]+$//; # remove the newline of the commande if any!

#####################################################
#####################################################
#####################################################
# then run with templates file arg:
# runtpl($tpl);

# $opts{'fixedCol'} = 122;
# $opts{'TplColumns'} = 122;
runnew($tpl);