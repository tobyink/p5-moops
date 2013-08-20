use v5.14;
use strict;
use warnings FATAL => 'all';
no warnings qw(void once uninitialized numeric);

package Moops::AssertKeyword;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.011';

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
	
	require Keyword::Simple;
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
		
		$$ref =~ s/ \A (.+?) (;|\z) / { $1; } /xsm unless $$ref =~ /\A\{/;
		
		if ($active and defined $name)
		{
			substr($$ref, 0, 0) = "die sprintf('Assertion failed: %s', $name) unless do ";
		}
		elsif ($active)
		{
			substr($$ref, 0, 0) = "die 'Assertion failed' unless do ";
		}
		else
		{
			substr($$ref, 0, 0) = "0 and do ";
		}
	})
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
	