package Text::MBPrintf;

use strict;
use warnings;

use Carp;

BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    $VERSION = sprintf "%d.%03d", q$Revision: 1.7 $ =~ /(\d+)/g;

    @ISA         = qw(Exporter);
    @EXPORT      = qw(&mbprintf &mbsprintf);
    %EXPORT_TAGS = ( );
    @EXPORT_OK   = qw(&mbwidth $wchar_re $Ambiguous);
}
our @EXPORT_OK;

our $Ambiguous;
our $wchar_re;

END { }

BEGIN {
    my $wide = "\\p{East_Asian_Width=Wide}";
    my $fullwidth = "\\p{East_Asian_Width=FullWidth}";
    my $ambiguous = "\\p{East_Asian_Width=Ambiguous}";

    if ($Ambiguous) {
	$wchar_re = qr/[${wide}${fullwidth}${ambiguous}]/;
    } else {
	$wchar_re = qr/[${wide}${fullwidth}]/;
    }
}

sub mbsprintf {
    my($format, @args) = @_;
    my @list;

    my $uniqstr = _sub_uniqstr();
    for my $arg (@args) {
	next if not defined $arg;
	next if $arg !~ /$wchar_re/;
	push(@list, $arg);
	push(@list, $arg = $uniqstr->(mbwidth($arg)));
    }
    my $result = sprintf($format, @args);
    while (my($orig, $tmp) = splice(@list, 0, 2)) {
	$result =~ s/$tmp/$orig/;
    }
    $result;
}

sub mbprintf {
    print mbsprintf(@_);
}

sub mbwidth {
    my $arg = shift;
    my $len = length($arg);
    while ($arg =~ m/($wchar_re+)/g) {
	$len += length($1);
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

__END__

=pod

=encoding utf8

=head1 NAME

MBPrintf - printf family functions to handle multi-byte characters

=head1 SYNOPSIS

use MBPrintf;

mbprintf(FORMAT, LIST)

mbsprintf(FORMAT, LIST)

=head1 DESCRIPTION

C<MBPrintf> is a almost-printf-compatible library with a capability of
handling multi-byte wide characters properly.

=head1 FUNCTIONS

=over 4

=item mbprintf(FORMAT, LIST)

=item mbsprintf(FORMAT, LIST)

Use just like perl's I<printf> and I<sprintf> functions
except that I<printf> does not take FILEHANDLE as a first argument.

=back

=head1 IMPLEMENTATION NOTES

Strings in the LIST which contains wide-width character are replaced
before formatting, and recovered after the process.  Number of
replaced arguments are limited by 25.

Unique replacement string contains a combination of control characters
(Control-A to Control-E).  So, if the FORMAT contains a string in this
range, it has a chance to be a subject of replacement.

Wide-character judgement is done based on Unicode property
B<East_Asian_Width> is B<Wide> or B<FullWidth>.  There is another
value B<Ambiguous> and treatment of this type characters are literaly
B<ambiguous>.  Set module variable C<$Text::MBPrintf::Ambiguous> in
advance to use these characters as wide.

    BEGIN {
        $Text::MBPrintf::Ambiguous = 1;
    }
    use Text::MBPrintf qw($wchar_re);

=head1 AUTHOR

Copyright (c) 2011-2014 Kazumasa Utashiro.  All rights reserved.

=head1 LICENSE

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
