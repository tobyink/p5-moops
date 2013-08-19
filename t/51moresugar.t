=pod

=encoding utf-8

=head1 PURPOSE

Check that L<Try::Tiny>, C<confess> and C<blessed> are imported into
packages, and work as expected, but get cleaned away by L<namespace::sweep>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

use Moops;

class Foo;

class Bar {
	our $last_err;
	method assert_blessed ($x) {
		state $errstr = "ERROR: ";
		blessed($x) or confess($errstr . $x);
	}
	method check_blessed ($x) {
		my $check = 0;
		try {
			$self->assert_blessed($x);
			$check++;
		}
		catch {
			my @lines = split /\n/;
			$last_err = $lines[0];
		};
		return $check;
	}
}

my $bar = 'Bar'->new;
is($bar->check_blessed('Foo'), 0);
like($Bar::last_err, qr{\AERROR: Foo at});
is($bar->check_blessed('Foo'->new), 1);

ok(not 'Bar'->can('try'));
ok(not 'Bar'->can('catch'));
ok(not 'Bar'->can('finally'));
ok(not 'Bar'->can('blessed'));
ok(not 'Bar'->can('confess'));

done_testing;
