use Moops;

class Foo
{
	multi method xxx (ClassName $class: Int $x) {
		say "CLASS METHOD - value $x";
	}
	multi method xxx (Object $self: Int $x) {
		say "OBJECT METHOD - value $x";
	}
}

Foo->xxx(1);

my $foo = Foo->new;
$foo->xxx(2);
