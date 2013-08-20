use v5.14;
use strict;
use warnings FATAL => 'all';
no warnings qw(void once uninitialized numeric);

package PerlX::Define;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.011';

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
		substr($$line, 0, $len) = "; use Moops::DefineKeyword $name => ";
	});
}

1;
