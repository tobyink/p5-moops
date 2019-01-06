use v5.14;
use strict;
use warnings FATAL => 'all';
no warnings qw(void once uninitialized numeric);

package Moops::TraitFor::Keyword::req;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.036';

use Moo::Role;

around arguments_for_moosex_mungehas => sub {
	my $next = shift;
	my $self = shift;
	require MooseX::MungeHas;
	MooseX::MungeHas->VERSION('0.011');
	return ('always_required', $self->$next(@_));
};

1;
