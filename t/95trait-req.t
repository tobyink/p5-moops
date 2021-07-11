=pod

=encoding utf-8

=head1 PURPOSE

Test C<< :req >> trait.

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

class Foo {
	has xyz => (is => 'ro');
}

my $foo;
ok not exception { $foo = Foo->new };
is($foo->xyz, undef);

my $foo2;
ok not exception { $foo2 = Foo->new(xyz => 42) };
is($foo2->xyz, 42);

class Bar :req {
	has xyz => (is => 'ro');
}

ok exception { Bar->new };

my $bar;
ok not exception { $bar = Bar->new(xyz => 42) };
is($bar->xyz, 42);

done_testing;
