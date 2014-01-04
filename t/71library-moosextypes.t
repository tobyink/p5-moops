=pod

=encoding utf-8

=head1 PURPOSE

Declare type libraries with Moops, extending L<MooseX::Types> type libraries.

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
use Test::Requires { 'MooseX::Types::Common::Numeric' => '0' };
use Test::TypeTiny;

use Moops;

library MyTypes extends MooseX::Types::Common::Numeric declares RainbowColour
{
	declare RainbowColour,
		as Enum[qw/ red orange yellow green blue indigo violet /];
}

should_pass('indigo', MyTypes::RainbowColour);
should_fail('magenta', MyTypes::RainbowColour);

should_pass('9', MyTypes::SingleDigit);
should_fail('10', MyTypes::SingleDigit);

class MyClass types MyTypes using Moose {
	method capitalize_colour ( $class: RainbowColour $r ) {
		return uc($r);
	}
}

is('MyClass'->capitalize_colour('indigo'), 'INDIGO');

ok exception { 'MyClass'->capitalize_colour('magenta') };

done_testing;
