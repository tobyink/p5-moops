use Moops;
 
role Moops::TraitFor::Keyword::MS {
	around generate_package_setup () {
		return map {
			/\Ause Function::Parameters/ ? 'use Method::Signatures;' : $_
		} $self->${^NEXT}, q[use experimental "smartmatch";];
	}
}
 
# Now this class uses Method::Signatures!
class Foo :MS {
	method foo ( Int $score where [0..10] ) {
		say "Got: $score";
	}
}
 
Foo->foo(3);    # says 'Got: 3'
Foo->foo(12);   # dies
