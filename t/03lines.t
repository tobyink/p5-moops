=pod

=encoding utf-8

=head1 PURPOSE

Test that Moops does not make line numbers insane!

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
use Test::More;

use Moops;

BEGIN { require Keyword::Simple; Keyword::Simple->VERSION >= 0.02 or plan skip_all => "need Keyword::Simple 0.02+" };

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
