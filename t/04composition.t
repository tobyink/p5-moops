=pod

=encoding utf-8

=head1 PURPOSE

Simple test composing a role into a class.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::More;
use Moops;

role Local::Role1
{
	requires "method1";
	method method2 {
		666;
	}
}

class Local::Class1 with Local::Role1
{
	method method1 {
		42;
	}
}

is( Local::Class1->new->method1, 42 );
is( Local::Class1->new->method2, 666 );

done_testing;
