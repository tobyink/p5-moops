=pod

=encoding utf-8

=head1 PURPOSE

Class C<ReturnsTrueAgain> used by 05true.t.

This class needs to be defined externally because we are testing
whether Moops-based modules automatically return a true value.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Moops;
class ReturnsTrueAgain {
	method foo { 42 }
}

# should be an implicit "1;" here
