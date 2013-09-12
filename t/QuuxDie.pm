=pod

=encoding utf-8

=head1 PURPOSE

Class C<QuuxDie> used by 14versions.t.

This class needs to be defined externally because its definition is
supposed to throw an exception at compile-time.

The exception is thrown because the class tries to consume role
C<< Baz 1.0 >>, but 14versions.t defines C<< Baz 0.9 >>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Moops;
class QuuxDie 1.0 extends Foo 1.0 with Baz 1.0;
