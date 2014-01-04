=pod

=encoding utf-8

=head1 PURPOSE

Check that type constraints work with L<Mouse>.

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
use Test::Requires { 'Mouse' => '1.00' };
use Test::Fatal;

use Moops;

class Foo using Mouse {
	has num => (is => 'rw', isa => Num);
	method add ( Num $addition ) {
		$self->num( $self->num + $addition );
	}
}

my $foo = 'Foo'->new(num => 20);
isa_ok($foo, 'Mouse::Object');
is($foo->num, 20);
is($foo->num(40), 40);
is($foo->num, 40);
is($foo->add(2), 42);
is($foo->num, 42);

like(
	exception { $foo->num("Hello") },
	qr{Value "Hello" did not pass type constraint "Num"},
);

like(
	exception { $foo->add("Hello") },
	qr{Value "Hello" did not pass type constraint "Num"},
);

like(
	exception { 'Foo'->new(num => "Hello") },
	qr{Value "Hello" did not pass type constraint "Num"},
);

done_testing;
