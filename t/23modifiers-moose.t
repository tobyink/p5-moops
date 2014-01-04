=pod

=encoding utf-8

=head1 PURPOSE

Check that the C<before>, C<after> and C<around> keywords work
with L<Moose>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;
use Test::Requires { 'Moose' => '2.0600' };

use Moops;

class Parent using Moose {
	method process ( ScalarRef[Int] $n ) {
		$$n *= 3;
	}
	method xxx () {
		return 42;
	}
}

role Sibling using Moose {
	after process ( ScalarRef[Int] $n ) {
		$$n += 2;
	}
	override xxx () {
		return 666;
	}
}

class Child extends Parent with Sibling using Moose {
	before process ( ScalarRef[Int] $n ) {
		$$n += 5;
	}
}

my $thing_one = Child->new;

my $n = 1;
$thing_one->process(\$n);
is($n, 20);

class Grandchild extends Child using Moose {
	around process ( ScalarRef[Num] $x ) {
		my ($int, $rest) = split /\./, $$x;
		$rest ||= 0;
		$self->${^NEXT}(\$int);
		$$x = "$int\.$rest";
	}
}

my $thing_two = Grandchild->new;

my $m = '1.2345';
$thing_two->process(\$m);
is($m, '20.2345');

{
	my $method = Class::MOP::class_of('Child')->get_method('process');
	my ($parm) = $method->can('positional_parameters')
		? $method->positional_parameters
		: $method->signature->positional_params;

	is($parm->name, '$n');
	isa_ok($parm->type, 'Type::Tiny');
	is($parm->type->display_name, 'ScalarRef[Int]');
}

{
	local $TODO = '`around` method modifier currently breaks metadata';
	
	my $method = Class::MOP::class_of('Grandchild')->get_method('process');
	my ($parm) = $method->can('positional_parameters')
		? $method->positional_parameters
		: $method->signature->positional_params;

	is($parm && $parm->name, '$n');
	isa_ok($parm && $parm->type, 'Type::Tiny');
	is($parm && $parm->type->display_name, 'ScalarRef[Int]');
}

subtest "override works in Moose classes" => sub
{
	is(Parent->xxx, 42);
	is(Child->xxx, 666);
	done_testing;
};

done_testing;
