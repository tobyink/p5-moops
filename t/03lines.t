=pod

=encoding utf-8

=head1 PURPOSE

Test that Moops does not make line numbers insane!

This test is currently skipped because
L<RT#88970|https://rt.cpan.org/Ticket/Display.html?id=88970>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


#line 24
use strict;
use warnings;
use Test::More skip_all => 'todo - RT#88970';

use Moops;

BEGIN { ::is(__LINE__, 30); }

#line 33
class Bar;
BEGIN { ::is(__LINE__, 34); }

#line 37
class Foo {
	namespace TraitFor {
		role Baz { ::is(__LINE__, 39) }
	}
}

#line 44
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
			::is(__LINE__, 57)
		}
	}
}

done_testing;
