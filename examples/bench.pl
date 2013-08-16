=pod

=head1 PURPOSE

The following test case benchmarks performance between L<Moops> and
the more established L<MooseX::Declare> by defining equilavent classes
using each.

The benchmarked code includes object construction and destruction,
accessor calls, method calls and type constraint checks.

Typical results (run on a fairly underpowered netbook) are:

	        Rate   MXD Moops
	MXD   8.82/s    --  -98%
	Moops  389/s 4307%    --

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Benchmark ':all';
use Test::More;
use Test::Fatal;
use IO::Callback;

# Declare class using Moops and Moose
#
{
	use Moops;
	class Foo::Moops using Moose {
		has n => (is => 'ro', writer => '_set_n', isa => Int, default => 0);
		method add (Int $x) {
			$self->_set_n( $self->n + $x );
		}
	}
}

# Declare equivalent class using MooseX::Declare
#
{
	use MooseX::Declare;
	class Foo::MXD {
		has n => (is => 'ro', writer => '_set_n', isa => 'Int', default => 0);
		method add (Int $x) {
			$self->_set_n( $self->n + $x );
		}
	}
}

# Test each class works as expected
#
for my $class ('Foo::Moops', 'Foo::MXD') {
	
	like(
		exception { $class->new(n => 1.1) },
		qr{(Validation failed for 'Int')|(did not pass type constraint "Int")},
		"Class '$class' throws error on incorrect constructor call",
	);
	
	my $o = $class->new(n => 0);
	like(
		exception { $o->add(1.1) },
		qr{(^Validation failed)|(did not pass type constraint "Int")},
		"Objects of class '$class' throw error on incorrect method call",
	);
	
	$o->add(40);
	$o->add(2);
	is($o->n, 42, "Objects of class '$class' function correctly");
	
}

# Ensure benchmarks run with TAP-friendly output.
#
my $was = select(
	'IO::Callback'->new('>', sub {
		my $data = shift;
		$data =~ s/^/# /g;
		print STDOUT $data;
	})
);

# Actually run benchmarks.
cmpthese(-1, {
	Moops => q{
		my $sum = 'Foo::Moops'->new(n => 0);
		$sum->add($_) for 0..100;
	},
	MXD => q{
		my $sum = 'Foo::MXD'->new(n => 0);
		$sum->add($_) for 0..100;
	},
});

select($was);

done_testing;

__END__
ok 1 - Class 'Foo::Moops' throws error on incorrect constructor call
ok 2 - Objects of class 'Foo::Moops' throw error on incorrect method call
ok 3 - Objects of class 'Foo::Moops' function correctly
ok 4 - Class 'Foo::MXD' throws error on incorrect constructor call
ok 5 - Objects of class 'Foo::MXD' throw error on incorrect method call
ok 6 - Objects of class 'Foo::MXD' function correctly
#         Rate   MXD Moops
# MXD   8.82/s    --  -98%
# Moops  389/s 4307%    --
1..6
