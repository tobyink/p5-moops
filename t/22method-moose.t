=pod

=encoding utf-8

=head1 PURPOSE

Check that the C<method> keyword works with L<Moose>.

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
use Test::Requires { 'Moose' => '2.0600' };
use Test::Fatal;

use Moops;

class Foo using Moose {
	method foo (Int $a) { return $a * 2 }
}

role Bar using Moose {
	method bar (Int $a) { return $a * 2 }
}

is(Foo->foo(21), 42);
is(Bar->bar(21), 42);

like($_, qr{Undef did not pass type constraint "Int"}) for (
	exception { Foo->foo(undef) },
	exception { Bar->bar(undef) },
);

my $method = Class::MOP::class_of('Foo')->get_method('foo');
my ($parm) = $method->can('positional_parameters')
	? $method->positional_parameters
	: $method->signature->positional_params;

is($parm->name, '$a');
isa_ok($parm->type, 'Type::Tiny');
is($parm->type->name, 'Int');

done_testing;
