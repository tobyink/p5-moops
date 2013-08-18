=pod

=encoding utf-8

=head1 PURPOSE

Check that the C<role> keyword works.

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
use Test::Fatal;

use Moops;

role Foo {
	method xyzzy () { 42 }
}

role Bar with Foo;

role Baz;

class Quux
with Bar,
Baz;

class Quuux with Bar with Baz;

ok( 'Quux'->does('Foo'), "Quux->does('Foo')" );
ok( 'Quux'->does('Bar'), "Quux->does('Bar')" );
ok( 'Quux'->does('Baz'), "Quux->does('Baz')" );
ok( 'Quux'->can('xyzzy'), "Quux->can('xyzzy')" );
is( 'Quux'->xyzzy, 42, "Quux->xyzzy == 42" );
ok( 'Quuux'->does('Foo'), "Quuux->does('Foo')" );
ok( 'Quuux'->does('Bar'), "Quuux->does('Bar')" );
ok( 'Quuux'->does('Baz'), "Quuux->does('Baz')" );
ok( 'Quuux'->can('xyzzy'), "Quuux->can('xyzzy')" );
is( 'Quuux'->xyzzy, 42, "Quuux->xyzzy == 42" );

done_testing;
