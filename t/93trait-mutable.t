=pod

=encoding utf-8

=head1 PURPOSE

Test C<< :mutable >> trait.

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
use Test::Requires { 'Moose' => '2.0600' };
use Test::Fatal;

use Moops;

class Foo using Moose :mutable;
class Bar using Moose;

'Foo'->meta->add_attribute('foo', { is => 'ro' });
my $foo = 'Foo'->new(foo => 42);
is($foo->foo, 42);

like(
	exception { 'Bar'->meta->add_attribute('bar', { is => 'ro' }) },
	qr{^The '?add_attribute'? method cannot be called on an immutable instance},
);

done_testing;
