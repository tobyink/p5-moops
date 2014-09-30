use strict;
use warnings;
use Test::More;

BEGIN {
	plan skip_all => "test does not support Function::Parameters"
		if $ENV{MOOPS_FUNCTION_PARAMETERS_EVERYWHERE};
};

package Local::Wocal;

use Moops;

class Person 1.1 :ro {
	has name => (isa => Str, required => 1);
}

multi class GenderedPerson (:$gender) extends Person 1.0
{
	method gender { $gender }
	method "is_$gender" { 1 }
	
	if ($gender eq 'male')
	{
		method has_penis { 1 }
	}
}

my $alice = GenderedPerson(gender => "female")->new(name => "Alice");
my $bob   = GenderedPerson(gender => "male")->new(name => "Bob");

::isnt(ref $alice, ref $bob);

::is($alice->name, "Alice");
::is($alice->gender, "female");
::ok($alice->is_female);
::ok(not $alice->can('has_penis'));

::is($bob->name, "Bob");
::is($bob->gender, "male");
::ok($bob->is_male);
::ok($bob->can('has_penis'));

::done_testing;
