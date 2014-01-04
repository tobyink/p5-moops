=pod

=encoding utf-8

=head1 PURPOSE

Test C<< :dirty >> trait.

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

class Foo :dirty { }
class Bar { }

can_ok('Foo', 'blessed', 'confess');
ok(not 'Bar'->can('blessed') || 'Bar'->can('confess'));

done_testing;
