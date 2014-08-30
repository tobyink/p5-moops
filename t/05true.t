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
use Test::Fatal;

subtest "module ending in an explicit false statement returns true" => sub
{
	my $retval;
	my $exception = exception { $retval = do { require ReturnsTrue } };
	is($exception, undef, 'no exception');
	ok($retval, 'require returned true');
	new_ok('ReturnsTrue');
};

subtest "module ending in no explicit statement returns true" => sub
{
	my $retval;
	my $exception = exception { $retval = do { require ReturnsTrueAgain } };
	is($exception, undef, 'no exception');
	ok($retval, 'require returned true');
	new_ok('ReturnsTrueAgain');
};

done_testing;
