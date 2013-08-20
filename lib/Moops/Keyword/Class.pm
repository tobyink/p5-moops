use v5.14;
use strict;
use warnings FATAL => 'all';
no warnings qw(void once uninitialized numeric);

package Moops::Keyword::Class;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.012';

use Moo;
use Devel::GlobalDestruction;
use B 'perlstring';
extends qw( Moops::Keyword::Role );

my %using = (
	Moo   => 'use Moo; use MooX::late;',
	Moose => 'use Moose;',
	Mouse => 'use Mouse;',
	Tiny  => 'use Class::Tiny; use Class::Tiny::Antlers;',
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
	
	my @lines = (
		'use namespace::sweep;',
		"use MooseX::MungeHas qw(@{[ $self->arguments_for_moosex_mungehas ]});",
#		'BEGIN { no warnings "redefine"; my $orig = \&has; *has = sub { warn __PACKAGE__." has @_"; goto $orig; } };',
	);

	if ($using eq 'Moose' or $using eq 'Mouse')
	{
		push @lines, sprintf(
			'my $__GUARD__%d = bless([__PACKAGE__], "Moops::Keyword::Class::__GUARD__");',
			100_000 + int(rand 899_000),
		);
	}
	
	if ($using eq 'Moose')
	{
		state $has_xs = !!eval('require MooseX::XSAccessor');
		push @lines, 'use MooseX::XSAccessor;' if $has_xs;
	}

	return (
		$using{$using},
		$self->generate_package_setup_relationships,
		@lines,
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
