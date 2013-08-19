use v5.14;
use strict;
use warnings FATAL => 'all';
no warnings qw(void once uninitialized numeric);

package Moops::Keyword::Class;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.010';

use Moo;
use Devel::GlobalDestruction;
use B 'perlstring';
extends qw( Moops::Keyword::Role );

my %using = (
	Moo   => 'use Moo; use MooX::late;',
	Moose => 'use Moose;',
	Mouse => 'use Mouse;',
);

sub Moops::Keyword::Class::__GUARD__::DESTROY
{
	my $pkg = $_[0][0];
	$pkg->meta->make_immutable
		unless in_global_destruction;
}

sub generate_package_setup_oo
{
	my $self  = shift;
	my $using = $self->relations->{using}[0] // $self->default_oo_implementation;
	
	exists($using{$using})
		or Carp::croak("Cannot create a package using $using; stopped");
	
	my @guard;
	push @guard, sprintf('my $__GUARD__%d = bless([__PACKAGE__], "Moops::Keyword::Class::__GUARD__");', 100_000 + int(rand 899_000))
		if $using eq 'Moose' || $using eq 'Mouse';
	
	return (
		$using{$using},
		$self->generate_package_setup_relationships,
		'use namespace::sweep;',
		@guard,
	);
}

around generate_package_setup_relationships => sub
{
	my $orig = shift;
	my $self = shift;
	
	my @classes = @{ $self->relations->{extends} || [] };
	return (
		@classes ? sprintf("extends(%s);", join ",", map perlstring($_), @classes) : (),
		$self->$orig(@_),
	);
};

around known_relationships => sub
{
	my $next = shift;
	my $self = shift;
	return($self->$next(@_), qw/ extends /);
};

1;
