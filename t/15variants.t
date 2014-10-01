use strict;
use warnings;
use Test::More;

BEGIN {
	plan skip_all => "test does not support Function::Parameters"
		if $ENV{MOOPS_FUNCTION_PARAMETERS_EVERYWHERE};
};

package Local::Wocal;

use Moops;

class Nipple 1.0;

class Animal 1.1 :ro
{
	has name => (isa => Str, required => 1);
}

multi class Species (Str :$common_name, Str :$binomial, Bool :$is_mammal?)
	extends Animal 1.0
{
	method binomial { $binomial }
	method "is_\L$common_name" { 1 }
	
	if ($is_mammal)
	{
		has nipples => (is => 'ro', isa => ArrayRef[Object], required => true);
		method get_nipples { @{$self->nipples} }
	}
}

my $Reindeer = Species(
	common_name => 'Reindeer',
	binomial => 'Rangifer tarandus',
	is_mammal => 1,
);

my $Chameleon = Species(
	common_name => 'Chameleon',
	binomial => 'Chamaeleo chamaeleon',
);

::isnt($Reindeer, $Chameleon);

my $sven = $Reindeer->new(name => "Sven", nipples => [ map Local::Wocal::Nipple->new, 1..4 ]);
my $pascal = $Chameleon->new(name => "Pascal");

::is($sven->name, "Sven");
::is($sven->binomial, "Rangifer tarandus");
::ok($sven->is_reindeer);
::ok($sven->can('get_nipples'));
::is_deeply(
	[ $sven->get_nipples ],
	[ map Local::Wocal::Nipple->new, 1..4 ],
);

::isa_ok($sven, $Reindeer);

::is($pascal->name, "Pascal");
::is($pascal->binomial, 'Chamaeleo chamaeleon');
::ok($pascal->is_chameleon);
::ok(!$pascal->can('nipples'));
::ok(!$pascal->can('get_nipples'));

::isa_ok($pascal, $Chameleon);

::done_testing;
