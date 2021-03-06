use v5.14;
use strict;
use warnings FATAL => 'all';
no warnings qw(void once uninitialized numeric);

package Moops::TraitFor::Keyword::rw;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.038';

use Moo::Role;

around arguments_for_moosex_mungehas => sub {
	my $next = shift;
	my $self = shift;
	return ('is_rw', $self->$next(@_));
};

1;
