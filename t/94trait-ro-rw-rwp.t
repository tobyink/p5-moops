=pod

=encoding utf-8

=head1 PURPOSE

Test C<< :ro >>, C<< :rw >> and C<< :rwp >> traits.

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
use Test::Fatal;

use Moops;

class Foo :ro {
	has xyz => ();
}

my $foo = Foo->new(xyz => 40);
ok exception { $foo->xyz( $foo->xyz + 2 ) };
is($foo->xyz, 40);
ok not $foo->can("_set_xyz");

class Bar :rw {
	has xyz => ();
}

my $bar = Bar->new(xyz => 40);
ok not exception { $bar->xyz( $bar->xyz + 2 ) };
is($bar->xyz, 42);
ok not $bar->can("_set_xyz");

class Baz :rwp {
	has xyz => ();
}

my $baz = Baz->new(xyz => 40);
ok exception { $baz->xyz( $baz->xyz + 2 ) };
is($baz->xyz, 40);
ok $baz->can("_set_xyz");
ok not exception { $baz->_set_xyz( $baz->xyz + 2 ) };
is($baz->xyz, 42);

done_testing;
