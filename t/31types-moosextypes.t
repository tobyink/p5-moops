=pod

=encoding utf-8

=head1 PURPOSE

Check that type constraints work with L<Moose> and L<MooseX::Types>, using
fully-qualified type constraint names.

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
use Test::Requires { 'MooseX::Types::Common::Numeric' => '0.001008' };
use Test::Fatal;

BEGIN {
	'MooseX::Types::Common::Numeric'->VERSION eq '0.001011'
		and plan skip_all => 'MooseX::Types::Common::Numeric 0.001011 is broken';
};

use Moops;

class Foo using Moose {
	has num => (is => 'rw', isa => MooseX::Types::Common::Numeric::PositiveInt);
	method add ( MooseX::Types::Common::Numeric::PositiveInt $addition ) {
		$self->num( $self->num + $addition );
	}
}

my $foo = 'Foo'->new(num => 20);
isa_ok($foo, 'Moose::Object');
is($foo->num, 20);
is($foo->num(40), 40);
is($foo->num, 40);
is($foo->add(2), 42);
is($foo->num, 42);

like(
	exception { $foo->num("Hello") },
	qr{Must be a positive integer},
);

like(
	exception { $foo->add("Hello") },
	qr{Must be a positive integer},
);

like(
	exception { 'Foo'->new(num => "Hello") },
	qr{Must be a positive integer},
);

done_testing;
