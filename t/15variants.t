use strict;
use warnings;
use Test::More;

package Local::Wocal;

use Moops;

class Person 1.1 :ro {
	has name => (isa => Str, required => 1);
}

multi class GenderedPerson ( Str :$gender ) extends Person 1.0 {
	method gender { $gender }
}

my $alice = GenderedPerson(gender => "female")->new(name => "Alice");
my $bob   = GenderedPerson(gender => "male")->new(name => "Bob");

::is($alice->name, "Alice");
::is($alice->gender, "female");
::is($bob->name, "Bob");
::is($bob->gender, "male");

::isnt(ref $alice, ref $bob);

::done_testing;
