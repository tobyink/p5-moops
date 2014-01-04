=pod

=encoding utf-8

=head1 PURPOSE

Test Moop extensibility via traits.

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

use Moops;

BEGIN {
	role Moops::TraitFor::Keyword::Quux {
		has quux_n => (is => 'ro', default => 0);
		around generate_package_setup {
			my $n = $self->quux_n + 0;
			return ($self->${^NEXT}, qq!sub quux_method { $n }!);
		}
	}
}

class Foo :Quux(n => 42);

can_ok('Foo', 'quux_method');
is('Foo'->new->quux_method, 42, '... which works');

done_testing;
