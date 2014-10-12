use v5.14;
use strict;
use warnings FATAL => 'all';
no warnings qw(void once uninitialized numeric);

package Moops::Keyword;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.034';

use Moo;
use B qw(perlstring);
use Devel::GlobalDestruction;
use Module::Runtime qw(module_notional_filename use_package_optimistically);
use namespace::autoclean;

has 'keyword'        => (is => 'ro');
has 'ccstash'        => (is => 'ro');
has 'package'        => (is => 'ro');
has 'version'        => (is => 'ro', predicate => 'has_version');
has 'relations'      => (is => 'ro');
has 'is_empty'       => (is => 'ro');
has 'imports'        => (is => 'ro', predicate => 'has_imports');
has 'version_checks' => (is => 'ro');
has '_guarded'       => (is => 'lazy', default => sub { [] });

sub should_support_methods { 0 }

sub BUILD
{
	my $self = shift;
	@{ $self->relations->{types} ||= [] }
		or push @{$self->relations->{types}}, 'Types::Standard';
}

sub generate_code
{
	my $self = shift;
	my $class = ref $self;
	my $package = $self->package;
	
	# Create the package declaration and version
	my $inject = "package $package;";
	$inject .= (
		$self->has_version
			? "BEGIN { our \$VERSION = '${\ $self->version }' };"
			: "BEGIN { our \$VERSION = '' };"
	);
	$inject .= "BEGIN { \$INC{${\ perlstring module_notional_filename $package }} = __FILE__ };";
	
	# Standard imports
	$inject .= join q[], $self->generate_package_setup;
	
	# Additional imports
	$inject .= $self->imports->generate_code($package) if $self->has_imports;
	
	# Stuff that must happen at runtime rather than compile time
	$inject .= "'Moops'->at_runtime('$package');";
	
	my @guarded = @{ $self->_guarded };
	state $i = 0;
	if (@guarded)
	{
		$inject .= sprintf(
			'my $__GUARD__%d_%d = "Moops::Keyword"->scope_guard(sub { %s });',
			++$i,
			100_000 + int(rand 899_000),
			join(q[;], @guarded),
		);
	}
	
	return $inject;
}

sub generate_package_setup
{
	my $self = shift;
	
	return (
		$self->generate_type_constraint_setup,
		$self->generate_package_setup_oo,
	) if $self->is_empty;
	
	return (
		'use Carp qw(confess);',
		'use PerlX::Assert;',
		'use PerlX::Define;',
		'use Scalar::Util qw(blessed);',
		'use Try::Tiny;',
		'BEGIN { (*true, *false) = (\&Moops::_true, \&Moops::_false) };',
		$self->generate_type_constraint_setup,
		$self->generate_package_setup_oo,
		$self->generate_package_setup_methods,
		'use v5.14;',
		'use strict;',
		'no warnings;',
		'use warnings FATAL => @Moops::FATAL_WARNINGS;',
	);
}

sub generate_package_setup_oo
{
	return;
}

sub generate_package_setup_methods
{
	my $self = shift;
	my @args = $self->arguments_for_kavorka($self->package);
	return "use Kavorka qw(@args);";
}

sub generate_type_constraint_setup
{
	my $self = shift;
	return map {
		my $lib = use_package_optimistically($_);
		$lib->isa('Type::Library')
			? "use $lib -types;"
			: $lib->can('type_names')
				? do {
					require Type::Registry;
					"use $lib ('$lib'->type_names); BEGIN { 'Type::Registry'->for_me->add_types(q[$lib]) };"
				}
				: do {
					require Carp;
					Carp::croak("'$lib' is not a recognized type constraint library")
				};
	} @{ $self->relations->{types} || [] };
}

sub arguments_for_kavorka
{
	return qw/ multi fun /;
}

sub known_relationships
{
	return qw/ types /;
}

sub qualify_relationship
{
	1;
}

sub version_relationship
{
	1;
}

sub check_prerequisites
{
	my $self = shift;
	for my $prereq (@{$self->version_checks})
	{
		&use_package_optimistically(@$prereq) if defined $prereq->[1];
	}
}

sub _mk_guard
{
	my $self = shift;
	push @{$self->_guarded}, @_;
}

use Variable::Magic qw(wizard cast);
sub scope_guard {
	shift;
	state $wiz = wizard(
		data => sub { $_[1] },
		free => sub { $_[1]() },
	);
	cast my($magic), $wiz, $_[0];
	\$magic;
}

1;
