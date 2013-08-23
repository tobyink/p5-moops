=pod

=encoding utf-8

=head1 PURPOSE

Check that type constraints can be imported using the C<types> option.

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
use Test::Requires { 'MooseX::Types::Common' => '0.001000' };
use Test::Fatal;

use Moops;

class NummyNummy types MooseX::Types::Common::Numeric using Moose :rwp :dirty
{
	has i => (isa => PositiveInt);
	
	method set_by_int ( PositiveInt $i )
	{
		$self->_set_i($i);
	}
	
	method set_by_num ( PositiveNum $n )
	{
		$self->_set_i($n);
	}
}

my $nummy = NummyNummy->new(i => 127);

like(
	exception { $nummy->_set_i(-4) },
	qr{Must be a positive integer},
);

is($nummy->i, 127);

$nummy->set_by_num(64);
is($nummy->i, 64);

like(
	exception { $nummy->set_by_int("Hello") },
	qr{Must be a positive integer},
);

$nummy->set_by_num(42);
is($nummy->i, 42);

like(
	exception { $nummy->set_by_num('World') },
	qr{Must be a positive number},
);

like(
	exception { $nummy->set_by_num("3.2") },
	qr{Must be a positive integer},
	"a value that slides by the method's type constraint, but not the attribute's"
);

ok exists(&NummyNummy::PositiveInt);
ok !exists(&NummyNummy::FileHandle);

done_testing;
