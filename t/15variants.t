use strict;
use warnings;
use Test::More;

use Moops;

class Person :ro {
	has name => (isa => Str, required => 1);
}

multi class GenderedPerson ( Str $gender ) {
	extends Person;
	method gender { $gender }
}

my $alice = GenderedPerson("female")->new(name => "Alice");
my $bob   = GenderedPerson("male")->new(name => "Bob");

is($alice->name, "Alice");
is($alice->gender, "female");
is($bob->name, "Bob");
is($bob->gender, "male");

isnt(ref $alice, ref $bob);

done_testing;
