use v5.14;
use strict;
use warnings FATAL => 'all';
no warnings qw(void once uninitialized numeric);

package PerlX::Define;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.019';

use B ();
use Keyword::Simple ();

sub import
{
	shift;
	
	if (@_)
	{
		my ($name, $value) = @_;
		my $caller = caller;
		
		local $@;
		ref($value)
			? eval qq[
				package $caller;
				sub $name () { \$value };
				1;
			]
			: eval qq[
				package $caller;
				sub $name () { ${\ B::perlstring($value) } };
				1;
			];
		
		$@ ? die($@) : return;
	}
	
	Keyword::Simple::define('define' => sub
	{
		my $line = shift;
		my ($whitespace1, $name, $whitespace2, $equals) =
			( $$line =~ m{\A([\n\s]*)(\w+)([\n\s]*)(=\>?)}s )
			or Carp::croak("Syntax error near 'define'");
		my $len = length($whitespace1. $name. $whitespace2. $equals);
		substr($$line, 0, $len) = "; use PerlX::Define $name => ";
	});
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

PerlX::Define - cute syntax for defining constants

=head1 SYNOPSIS

   use PerlX::Define;
   
   define PI = 3.2;

=head1 DESCRIPTION

PerlX::Define is a yet another module for defining constants.

Constants defined this way, aren't "better" than the constants defined
any other way, but the syntax is cute.

PerlX::Define is currently distributed as part of L<Moops>, but is
fairly independent of the rest of it, and may be spun off as a
separate release in the future.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Moops>.

=head1 SEE ALSO

L<constant>.

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
