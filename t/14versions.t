=pod

=encoding utf-8

=head1 PURPOSE

Check that package versions can be specified.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( t ../t );
use Test::More;
use Test::Fatal;

use Moops;

class Foo 1.2;
class Bar 1.1 extends Foo 1.1;
role Baz 0.9;

is(Foo->VERSION, 1.2);
is(Bar->VERSION, 1.1);
is(Baz->VERSION, 0.9);

# To catch this error, we need to load it from an external file!
like(
	exception { require QuuxDie },
	qr{\ABaz version 1.0 required},
);

done_testing;
