=pod

=encoding utf-8

=head1 PURPOSE

Check that the C<assert> keyword works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Moops;

BEGIN {
	$ENV{AUTHOR_TESTING} = $ENV{AUTOMATED_TESTING} = $ENV{EXTENDED_TESTING} = $ENV{RELEASE_TESTING} = 0;
};

class Foo {
	method go ($x) {
		assert { $x < 5 };
		return 1;
	}
}
	
die("Could not compile class Foo: $@") if $@;

ok( 'Foo'->go(6), 'class compiled with no relevant environment variables; assertions are ignored' );
ok( 'Foo'->go(4), '... and a dummy value that should not cause assertion to fail anyway' );

{
	BEGIN {
		$ENV{AUTHOR_TESTING} = $ENV{AUTOMATED_TESTING} = $ENV{EXTENDED_TESTING} = $ENV{RELEASE_TESTING} = 0;
		$ENV{AUTHOR_TESTING} = 1;
	};
	
	class Foo_AUTHOR {
		method go ($x) {
			assert { $x < 5 };
			return 1;
		}
	}
	
	like(
		exception { 'Foo_AUTHOR'->go(6) },
		qr{^Assertion failed at},
		"class compiled with \$ENV{AUTHOR_TESTING}; assertions are working",
	);
	ok( 'Foo_AUTHOR'->go(4), '... and a dummy value that should not cause assertion to fail anyway' );
}

{
	BEGIN {
		$ENV{AUTHOR_TESTING} = $ENV{AUTOMATED_TESTING} = $ENV{EXTENDED_TESTING} = $ENV{RELEASE_TESTING} = 0;
		$ENV{AUTOMATED_TESTING} = 1;
	};
	
	class Foo_AUTOMATED {
		method go ($x) {
			assert $x < 5;
			return 1;
		}
	}
	
	like(
		exception { 'Foo_AUTOMATED'->go(6) },
		qr{^Assertion failed at},
		"class compiled with \$ENV{AUTOMATED_TESTING}; assertions are working",
	);
	ok( 'Foo_AUTOMATED'->go(4), '... and a dummy value that should not cause assertion to fail anyway' );
}

{
	BEGIN {
		$ENV{AUTHOR_TESTING} = $ENV{AUTOMATED_TESTING} = $ENV{EXTENDED_TESTING} = $ENV{RELEASE_TESTING} = 0;
		$ENV{EXTENDED_TESTING} = 1;
	};
	
	class Foo_EXTENDED {
		method go ($x) {
			assert "yah-booh" { $x < 5 };
			return 1;
		}
	}
	
	like(
		exception { 'Foo_EXTENDED'->go(6) },
		qr{^Assertion failed: yah-booh at},
		"class compiled with \$ENV{EXTENDED_TESTING}; assertions are working",
	);
	ok( 'Foo_EXTENDED'->go(4), '... and a dummy value that should not cause assertion to fail anyway' );
}

{
	BEGIN {
		$ENV{AUTHOR_TESTING} = $ENV{AUTOMATED_TESTING} = $ENV{EXTENDED_TESTING} = $ENV{RELEASE_TESTING} = 0;
		$ENV{RELEASE_TESTING} = 1;
	};
	
	class Foo_RELEASE {
		method go ($x) {
			assert q[yah-booh], $x < 5;
			return 1;
		}
	}
	
	like(
		exception { 'Foo_RELEASE'->go(6) },
		qr{^Assertion failed: yah-booh at},
		"class compiled with \$ENV{RELEASE_TESTING}; assertions are working",
	);
	ok( 'Foo_RELEASE'->go(4), '... and a dummy value that should not cause assertion to fail anyway' );
}

{
	BEGIN {
		$ENV{AUTHOR_TESTING} = $ENV{AUTOMATED_TESTING} = $ENV{EXTENDED_TESTING} = $ENV{RELEASE_TESTING} = 0;
	};
	
	class Foo_attr :assertions {
		method go ($x) {
			assert q[yah-booh], $x < 5;
			return 1;
		}
	}
	
	like(
		exception { 'Foo_attr'->go(6) },
		qr{^Assertion failed: yah-booh at},
		"class compiled with :assertions trait; assertions are working",
	);
	ok( 'Foo_attr'->go(4), '... and a dummy value that should not cause assertion to fail anyway' );
}

done_testing;
