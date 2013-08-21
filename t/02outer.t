=pod

=encoding utf-8

=head1 PURPOSE

Test that Moops imports Perl 5.14 features into the outer scope.

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

my $x;

sub xyz {
	state $foo = $x;
	return $foo;
}

$x = 42;
xyz();
$x = 99;

is(xyz(), 42);

done_testing;
