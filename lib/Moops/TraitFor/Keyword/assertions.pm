use v5.14;
use strict;
use warnings FATAL => 'all';
no warnings qw(void once uninitialized numeric);

package Moops::TraitFor::Keyword::assertions;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.021';

use Moo::Role;

around generate_package_setup => sub {
	my $next = shift;
	my $self = shift;
	return map {
		s/use PerlX::Assert;/use PerlX::Assert -check;/; $_
	} $self->$next(@_);
};

1;
