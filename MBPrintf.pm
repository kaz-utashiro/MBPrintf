package MBPrintf;

use strict;
use warnings;

use Carp;

BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    $VERSION = sprintf "%d.%03d", q$Revision: 1.3 $ =~ /(\d+)/g;

    @ISA         = qw(Exporter);
    @EXPORT      = qw(&mbprintf &mbsprintf);
    %EXPORT_TAGS = ( );
    @EXPORT_OK   = qw(&mbwidth);
}
our @EXPORT_OK;

END { }

my $wchar_re;
if (1) {
    $wchar_re = qr/[\p{East_Asian_Width=Wide}\p{East_Asian_Width=FullWidth}]/;
} else {
    $wchar_re = qr/[\p{East_Asian_Width=Wide}\p{East_Asian_Width=FullWidth}\p{East_Asian_Width=Ambiguous}]/;
}

sub mbsprintf {
    my($format, @args) = @_;
    my @list;

    my $uniqstr = _sub_uniqstr();
    for my $arg (@args) {
	next if not defined $arg;
	next if $arg !~ /$wchar_re/;

	my $save = $arg;
	$arg = $uniqstr->(mbwidth($arg));
	push(@list, $arg, $save);
    }
    my $result = sprintf($format, @args);
    while (my($from, $to) = splice(@list, 0, 2)) {
	$result =~ s/$from/$to/;
    }
    $result;
}

sub mbprintf {
    print mbsprintf(@_);
}

sub mbwidth {
    my $arg = shift;
    my $len;
    while ($arg =~ m/($wchar_re+)|./g) {
	$len += $1 ? length($1) * 2 : 1;
    }
    $len;
}

sub _sub_uniqstr {
    my $n = 0;
    sub {
	my $len = shift;
	croak "Illegal length" if $len < 2;
	croak "Too many arguments" if $n >= 25;
	my $s = pack("CC", $n / 5 + 1, $n % 5 + 1) . ("_" x ($len - 2));
	$n++;
	$s;
    }
}

1;
