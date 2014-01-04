=pod

=encoding utf-8

=head1 PURPOSE

Check that the C<class> keyword works with L<Mouse>.

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
use Test::Fatal;
use Test::Requires { 'Mouse' => '1.00' };

use Moops;

class Foo using Mouse {
	has aaa => (is => 'ro');
	class Bar {
		has bbb => (is => 'ro');
	}
	class Baz #comment!
	extends Bar #comment!
	using Mouse {
		has ccc => (is => 'ro');
	}
	class ::Quux {
		has ddd => (is => 'ro');
	}
	class Quux::Quux using Mouse {
		has eee => (is => 'ro');
	}
	class ::Quux::Quux::Quux {
		has fff => (is => 'ro');
	}
}

ok( 'Foo'->can('aaa'), "Foo->can('aaa')");
ok(!'Foo'->can('bbb'), "not Foo->can('bbb')");
ok(!'Foo'->can('ccc'), "not Foo->can('ccc')");

ok(!'Foo::Bar'->can('aaa'), "not Foo::Bar->can('aaa')");
ok( 'Foo::Bar'->can('bbb'), "Foo::Bar->can('bbb')");
ok(!'Foo::Bar'->can('ccc'), "not Foo::Bar->can('ccc')");

ok(!'Foo::Baz'->can('aaa'), "not Foo::Baz->can('aaa')");
ok( 'Foo::Baz'->can('bbb'), "Foo::Baz->can('bbb')");
ok( 'Foo::Baz'->can('ccc'), "Foo::Baz->can('ccc')");

ok('Quux'->can('ddd'), "Quux->can('ddd')");
ok('Quux::Quux'->can('eee'), "Quux::Quux->can('eee')");
ok('Quux::Quux::Quux'->can('fff'), "Quux::Quux::Quux->can('fff')");

isa_ok('Foo'->new, 'Mouse::Object');

done_testing;
