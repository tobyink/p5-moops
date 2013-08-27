=pod

=encoding utf-8

=head1 PURPOSE

Check that Moops gives us sufficient tools to declare and use a
type constraint library in the same file.

Compile time versus run time might be an issue.

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
use Test::TypeTiny;

use Moops;

namespace MyTypes {
	use Type::Library -base, -declare => qw( RainbowColour );
	use Type::Utils -all;
	BEGIN { extends 'Types::Standard' };
	declare RainbowColour,
		as Enum[qw/ red orange yellow green blue indigo violet /];
}

should_pass('indigo', MyTypes::RainbowColour);
should_fail('magenta', MyTypes::RainbowColour);

class MyClass types MyTypes {
	method capitalize_colour ( $class: RainbowColour $r ) {
		return uc($r);
	}
}

is('MyClass'->capitalize_colour('indigo'), 'INDIGO');

ok exception { 'MyClass'->capitalize_colour('magenta') };

done_testing;
