=pod

=encoding utf-8

=head1 PURPOSE

Check that the C<before>, C<after> and C<around> keywords work.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

use Moops;

class Parent {
	method process ( ScalarRef[Int] $n ) {
		$$n *= 3;
	}
}

role Sibling {
	after process ( ScalarRef[Int] $n ) {
		$$n += 2;
	}
}

class Child extends Parent with Sibling {
	before process ( ScalarRef[Int] $n ) {
		$$n += 5;
	}
}

my $thing_one = Child->new;

my $n = 1;
$thing_one->process(\$n);
is($n, 20);

class Grandchild extends Child {
	around process ( ScalarRef[Num] $n ) {
		my ($int, $rest) = split /\./, $$n;
		$rest ||= 0;
		$self->${^NEXT}(\$int);
		$$n = "$int\.$rest";
	}
}

my $thing_two = Grandchild->new;

my $m = '1.2345';
$thing_two->process(\$m);
is($m, '20.2345');

done_testing;
