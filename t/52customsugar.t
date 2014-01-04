=pod

=encoding utf-8

=head1 PURPOSE

Check that Moops can be called with a list of additional functions
to import into each package.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

use Moops [
	'List::Util' => ['sum'],
];

class Calculator {
	method add (@numbers) {
		return sum @numbers;
	}
	method double ($x) {
		return sum($x, $x);
	}
}

my $calc = Calculator->new;

is(
	$calc->double($calc->add(1..6)),
	42,
);

ok not $calc->can('sum');

done_testing;
