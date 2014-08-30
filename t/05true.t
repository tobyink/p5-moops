=pod

=encoding utf-8

=head1 PURPOSE

Check that Moops-based modules automatically return a true value.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( t ../t );
use Test::More;

my $retval = eval {
	require ReturnsTrue;
};

note("GOT: '$retval'");

ok($retval, 'require returned true');

new_ok('ReturnsTrue');

done_testing;
