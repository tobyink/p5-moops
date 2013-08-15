use Moops;

class Calculator {
	define PI = 3.2;
	method circular_area (Num :$r) {
		return PI * $r**2;
	}
}

my $calc = Calculator->new;
say "The circle's area is ", $calc->circular_area(r => 1.0);
