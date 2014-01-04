=pod

=encoding utf-8

=head1 PURPOSE

Test that Moops does not make line numbers insane!

=head1 DEPENDENCIES

Keyword::Simple 0.02, otherwise this test is skipped.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

#line 27
use strict;
use warnings;
use Test::More;
use Test::Requires { 'Keyword::Simple' => '0.02' };

use Moops;

#line 35
class Bar;
BEGIN { ::is(__LINE__, 36) }

#line 39
class Foo {
	namespace TraitFor {
		role Baz { ::is(__LINE__, 41) }
	}
}

#line 46
class
Quux
extends
Foo
{
	namespace
	TraitFor
	{
		role
		Quuux
		with
		Foo::TraitFor::Baz
		{
			::is(__LINE__, 59)
		}
	}
}

done_testing;
