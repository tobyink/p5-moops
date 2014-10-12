use v5.14;
use strict;
use warnings FATAL => 'all';
no warnings qw(void once uninitialized numeric);

package Moops::Keyword::Role;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.034';

use Moo;
use B qw(perlstring);
extends qw( Moops::Keyword );

sub should_support_methods { 1 }

sub arguments_for_moosex_mungehas
{
	shift;
	return qw(eq_1);
}

my %using = (
	Moo   => 'use Moo::Role; use MooX::late;',
	Moose => 'use Moose::Role; use MooseX::KavorkaInfo;',
	Mouse => 'use Mouse::Role;',
	Tiny  => 'use Role::Tiny;',
	(
		map { $_ => "use $_;" }
		qw/ Role::Basic Role::Tiny Moo::Role Mouse::Role Moose::Role /
	),
);

sub default_oo_implementation
{
	'Moo';
}

sub generate_package_setup_oo
{
	my $self  = shift;
	my $using = $self->relations->{using}[0] // $self->default_oo_implementation;
	
	exists($using{$using})
		or Carp::croak("Cannot create a package using $using; stopped");
	
	my @lines = (
		'use namespace::autoclean -also => ["has", "lexical_has"];',
		'use Lexical::Accessor;',
	);
	push @lines, "use MooseX::MungeHas qw(@{[ $self->arguments_for_moosex_mungehas ]});"
		if $using =~ /^Mo/;
	
	return (
		$using{$using},
		$self->generate_package_setup_relationships,
		@lines,
	);
}

sub generate_package_setup_relationships
{
	my $self  = shift;
	my @roles = @{ $self->relations->{with} || [] };
	
	$self->_mk_guard(
		sprintf("with(%s);", join(",", map perlstring($_), @roles))
	) if @roles;
	return;
}

around known_relationships => sub
{
	my $next = shift;
	my $self = shift;
	return($self->$next(@_), qw/ with using /);
};

around qualify_relationship => sub
{
	my $next = shift;
	my $self = shift;
	$_[0] eq 'using' ? !!0 : $self->$next(@_);
};

around version_relationship => sub
{
	my $next = shift;
	my $self = shift;
	$_[0] eq 'using' ? !!0 : $self->$next(@_);
};

around arguments_for_kavorka => sub
{
	my $next = shift;
	my $self = shift;
	
	my @keywords = qw/ method before after around /;
	
	my $using = $self->relations->{using}[0] // $self->default_oo_implementation;
	push @keywords, qw/ override augment /
		if $using =~ /^Mo[ou]se\b/;
	
	return (
		$self->$next(@_),
		@keywords,
	);
};

1;
