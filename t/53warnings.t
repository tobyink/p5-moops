=pod

=encoding utf-8

=head1 PURPOSE

Check that we don't get a warning from using smart match.

(This is because the warning was added in Perl 5.18, and the warnings
categories imported by Moops should be consistent from Perl 5.14 going
forwards.)

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::More;
use Test::Requires { 'Test::Warnings' => 0 };
use Test::Warnings;

use Moops;

class Foo {
	method xxx ($val) {
		$val ~~ 1;
	}
}

ok(     Foo->xxx(1) );
ok( not Foo->xxx(2) );

done_testing;
