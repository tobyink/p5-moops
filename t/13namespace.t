=pod

=encoding utf-8

=head1 PURPOSE

Check that the C<namespace> keyword works.

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

use Moops;

namespace Foo {
	namespace Bar {
		namespace Baz {
			fun quux () {
				return 42;
			}
		}
	}
}

ok !eval q{ use Moops; namespace Blammo using Moose { }; 1 };
like($@, qr{^Expected});

is(Foo::Bar::Baz::quux(), 42);

done_testing;
