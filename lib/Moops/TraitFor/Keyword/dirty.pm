use v5.14;
use strict;
use warnings FATAL => 'all';
no warnings qw(void once uninitialized numeric);

package Moops::TraitFor::Keyword::dirty;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.028';

use Moo::Role;

around generate_package_setup => sub {
	my $next = shift;
	my $self = shift;
	grep !/^use namespace::sweep/, $self->$next(@_);
};

1;
