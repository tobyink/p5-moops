use v5.14;
use strict;
use warnings FATAL => 'all';
no warnings qw(void once uninitialized numeric);

package Moops::Keyword::Role;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.011';

use Moo;
use B qw(perlstring);
extends qw( Moops::Keyword );

around arguments_for_function_parameters => sub
{
	require Moops::MethodModifiers;
	
	my $orig     = shift;
	my $class    = shift;
	my $keywords = $class->$orig(@_);
	my $reify    = $keywords->{fun}{reify_type};
	
	$keywords->{method} = {
		name                 => 'optional',
		default_arguments    => 1,
		check_argument_count => 1,
		named_parameters     => 1,
		types                => 1,
		reify_type           => $reify,
		attrs                => ':method',
		shift                => '$self',
		invocant             => 1,
	};
	$keywords->{ lc($_) } = {
		name                 => 'required',
		default_arguments    => 1,
		check_argument_count => 1,
		named_parameters     => 1,
		types                => 1,
		reify_type           => $reify,
		attrs                => ":$_",
		shift                => '$self',
		invocant             => 1,
	} for qw( Before After Around );
	
	return $keywords;
};

sub arguments_for_moosex_mungehas
{
	shift;
	return qw(eq_1);
}

around generate_package_setup => sub
{
	my $orig = shift;
	my $self = shift;
	
	return (
		$self->$orig(@_),
		$self->generate_package_setup_oo,
	);
};

my %using = (
	Moo   => 'use Moo::Role; use MooX::late;',
	Moose => 'use Moose::Role;',
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
	
	my @lines = 'use namespace::sweep;';
	push @lines, "use MooseX::MungeHas qw(@{[ $self->arguments_for_moosex_mungehas ]});"
		if $using{$using} =~ /^Mo/;
	
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
	
	return unless @roles;
	return sprintf "with(%s);", join ",", map perlstring($_), @roles;
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

1;
