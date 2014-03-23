use strict;
use warnings;
use Test::More;

use Config;
BEGIN {
	plan skip_all => "your perl does not support ithreads"
		unless $Config{useithreads};
};

use threads;

{
	package ThreadedExample;
	use Moops;
	class Foo;
}

my $subref = sub {
	my $id = shift;
	note("id:$id");
	return $id;
};

my @threads;
my @idents = qw/bar1 bar2 bar3 bar4 bar5 bar6/;
foreach my $foo_id (@idents)
{
	push @threads, threads->create($subref, $foo_id);
}

my @results;
for my $thread (@threads) {
	note("joining thread $thread");
	push @results, $thread->join;
}

is_deeply(
	[ sort @results ],
	[ sort @idents ],
	'expected return values',
);

done_testing;
