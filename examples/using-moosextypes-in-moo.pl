use Moops;

library MyWrapper
	extends MooseX::Types::Common::Numeric;

class Foo
	types MyWrapper
	using Moo
{
	has favourite_number => (
		is  => 'rwp',
		isa => PositiveInt,
	);
}

Foo->new(favourite_number => 42);
Foo->new(favourite_number => -5);
