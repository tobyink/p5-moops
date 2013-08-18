=pod

=head1 PURPOSE

An example of extending Moops to add an C<exception> keyword.

The MoopsX::Ception module itself does little, except injects the
MoopsX::Ception::Parser module. 

MoopsX::Ception::Parser uses L<Moops::Parser>'s hooks to add support
for parsing the C<exception> keyword, and injects the
MoopsX::Ception::CodeGenerator::Exception code generator when
it is encountered.

MoopsX::Ception::CodeGenerator::Exception is a simple subclass
of L<Moops::CodeGenerator::Class> and simply adds L<Throwable> to
the list of roles that the class does.

=head1 DEPENDENCIES

Requires the L<Throwable> role which is available from CPAN.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use FindBin qw($Bin);
use lib "$Bin/lib";

use MoopsX::Ception;

exception FileError {
	has filename => (is => 'ro', isa => Str);
}

namespace Demonstration {
	fun go () {
		try {
			FileError->throw(filename => 'not-exists.txt');
		}
		catch {
			say "Caught exception: ", $_->filename;
		};
	}
}

Demonstration::go();
