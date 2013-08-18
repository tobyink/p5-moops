=pod

=encoding utf-8

=head1 PURPOSE

Check that defining constants works.

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

use Moops;

class MyClass {
	define PI => 3.2;
	method get_true () { true; }
	method get_false () { false; }
}

ok not 'MyClass'->can('true');
ok not 'MyClass'->can('false');
ok     'MyClass'->can('get_true');
ok     'MyClass'->can('get_false');
ok     'MyClass'->can('PI');

ok(    'MyClass'->get_true);
ok(not 'MyClass'->get_false);

is(MyClass::PI,   3.2);
is(MyClass::PI(), 3.2);
is('MyClass'->PI, 3.2);

done_testing;
