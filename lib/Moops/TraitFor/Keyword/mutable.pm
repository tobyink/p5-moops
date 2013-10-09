use v5.14;
use strict;
use warnings FATAL => 'all';
no warnings qw(void once uninitialized numeric);

package Moops::TraitFor::Keyword::mutable;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.025';

use Moo::Role;

around generate_package_setup => sub {
	my $next = shift;
	my $self = shift;
	
	my @lines= $self->$next(@_);
	
	unless ("@lines" =~ /\b(use Moose)\b/)
	{
		require Carp;
		Carp::carp(sprintf('%s has trait :mutable but does not appear to be a Moose class', $self->package));
	}
	
	grep !/"Moops::Keyword::Class::__GUARD__"/, @lines;
};

1;
