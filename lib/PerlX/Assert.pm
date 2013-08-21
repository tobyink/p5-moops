use v5.14;
use strict;
use warnings FATAL => 'all';
no warnings qw(void once uninitialized numeric);

package PerlX::Assert;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.014';

use Keyword::Simple ();

sub import
{
	shift;
	
	my $active = 0+!!( $_[0] eq '-check' );
	$ENV{$_} && $active++ for qw/
		AUTHOR_TESTING
		AUTOMATED_TESTING
		EXTENDED_TESTING
		RELEASE_TESTING
	/;
	
	Keyword::Simple::define('assert' => sub
	{
		my $ref = shift;
		_eat_space($ref);
		
		my $name;
		if ($$ref =~ /\A(qq\b|q\b|'|")/)
		{
			require Text::Balanced;
			$name = Text::Balanced::extract_quotelike($$ref);
			_eat_space($ref);
			
			if ($$ref =~ /\A,/)
			{
				substr($$ref, 0, 1) = '';
				_eat_space($ref);
				$$ref =~ /\A\{/ and do {
					require Carp;
					Carp::croak("Unexpected comma between assertion name and block");
				};
			}
		}
		
		my $do = ($$ref =~ /\A\{/) ? 'do' : '';
		
		if ($active and defined $name)
		{
			substr($$ref, 0, 0) = "die sprintf('Assertion failed: %s', $name) unless $do";
		}
		elsif ($active)
		{
			substr($$ref, 0, 0) = "die 'Assertion failed' unless $do";
		}
		else
		{
			substr($$ref, 0, 0) = "0 and $do";
		}
	});
}

sub _eat_space
{
	my $ref = shift;
	my $X;
	while (
		($$ref =~ m{\A( \s+ )}x and $X = 1)
		or ($$ref =~ m{\A\#} and $X = 2)
	) {
		$X==2
			? ($$ref =~ s{\A\#.+?\n}{}sm)
			: (substr($$ref, 0, length($1)) = '');
	}
	return;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

PerlX::Assert - yet another assertion keyword

=head1 SYNOPSIS

   use PerlX::Assert;
   
   assert { 1 >= 10 };

=head1 DESCRIPTION

PerlX::Assert is a framework for embedding assertions in Perl code.
Under normal circumstances, assertions are not checked; they are
optimized away at compile time.

However if, at compile time, any of the following environment variables
is true, assertions are checked, and if they fail, throw an exception.

=over

=item *

C<AUTHOR_TESTING>

=item *

C<AUTOMATED_TESTING>

=item *

C<EXTENDED_TESTING>

=item *

C<RELEASE_TESTING>

=back

That is, assertions will only typically be checked when the test suite
is being run on the authors' machine, or being run by CPAN smoke testers.

You can also force assertions to be checked using:

   use PerlX::Assert -check;

Or if using Moops, use the ':assertions' trait to force assertion
checking:

   class Whiner :assertions {
      # ...
   }

There are four syntaxes for expressing assertions:

   assert EXPR;
   assert { BLOCK };
   assert "name", EXPR;
   assert "name" { BLOCK };

Assertions can be named, which is probably a good idea because this
module (and the rest of Moops) screws up Perl's reporting of line
numbers. Names must be a quoted string. (Single or double quotes, or
the C<q> or C<qq> quote-like operators.) An assertion is a statement,
so must be followed by a semicolon, unless it's the last statement in
a block.

PerlX::Assert is currently distributed as part of L<Moops>, but is
fairly independent of the rest of it, and may be spun off as a
separate release in the future.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Moops>.

=head1 SEE ALSO

L<Devel::Assert>, L<Carp::Assert>.

L<Moops>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
