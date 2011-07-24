package MBPrintf;

use strict;
use warnings;

BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    $VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)/g;

    @ISA         = qw(Exporter);
    @EXPORT      = qw(&mbprintf &mbsprintf);
    %EXPORT_TAGS = ( );
    @EXPORT_OK   = qw();
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

    my $n = 0;
    for my $arg (@args) {
	next if not defined $arg;
	next if $arg !~ /$wchar_re/;

	my $len;
	my $save = $arg;
	while ($arg =~ m/($wchar_re+)|./g) {
	    $len += $1 ? length($1) * 2 : 1;
	}
	$arg = pack("CC", $n / 5 + 1, $n % 5 + 1) . ("_" x ($len - 2));
	push(@list, [$arg, $save]);
	$n++;
    }
    my $result = sprintf($format, @args);
    while (@list) {
	my($from, $to) = @{shift @list};
	$result =~ s/$from/$to/;
    }
    $result;
}

sub mbprintf {
    print mbsprintf(@_);
}

1;
