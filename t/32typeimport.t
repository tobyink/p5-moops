=pod

=encoding utf-8

=head1 PURPOSE

Check that type constraints can be imported using the C<types> option.

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
use Test::Requires { 'Types::XSD::Lite' => '0.003' };
use Test::Fatal;

use Moops;

class BiteyBitey types Types::XSD::Lite :rwp :dirty
{
	has byte => (isa => UnsignedByte);
	
	method set_by_number ( UnsignedByte $i )
	{
		$self->_set_byte($i);
	}
	
	method set_by_character ( (String[length=>1]) $c )
	{
		$self->_set_byte(ord $c);
	}
	
	method _known_type (Str $name --> Maybe[Object])
	{
		try { Type::Registry->for_me->lookup($name) };
	}
}

my $bitey = BiteyBitey->new(byte => 127);

like(
	exception { $bitey->_set_byte(300) },
	qr{^Value "300" did not pass type constraint "UnsignedByte"},
);

is($bitey->byte, 127);

$bitey->set_by_number(64);
is($bitey->byte, 64);

ok(
	exception { $bitey->set_by_number(-1) },
);

$bitey->set_by_character('*');
is($bitey->byte, 42);

ok(
	exception { $bitey->set_by_character('XXXX') },
);

like(
	exception { $bitey->set_by_character("\x{2639}") },
	qr{^Value "9785" did not pass type constraint "UnsignedByte"},
	"a value that slides by the method's type constraint, but not the attribute's"
);

ok exists(&BiteyBitey::UnsignedByte);
ok !exists(&BiteyBitey::FileHandle);

ok !!BiteyBitey->_known_type('UnsignedByte');
ok  !BiteyBitey->_known_type('MonkeyBizness');

done_testing;
