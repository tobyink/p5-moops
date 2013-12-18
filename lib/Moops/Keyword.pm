use v5.14;
use strict;
use warnings FATAL => 'all';
no warnings qw(void once uninitialized numeric);

package Moops::Keyword;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.028';

use Moo;
use B qw(perlstring);
use Module::Runtime qw(module_notional_filename use_package_optimistically);
use namespace::sweep;

has 'keyword'        => (is => 'ro');
has 'ccstash'        => (is => 'ro');
has 'package'        => (is => 'ro');
has 'version'        => (is => 'ro', predicate => 'has_version');
has 'relations'      => (is => 'ro');
has 'is_empty'       => (is => 'ro');
has 'imports'        => (is => 'ro', predicate => 'has_imports');
has 'version_checks' => (is => 'ro');

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
		'use v5.14;',
		'use strict;',
		'use warnings FATAL => qw(all); no warnings qw(void once uninitialized numeric);',
		'BEGIN { (*true, *false) = (\&Moops::_true, \&Moops::_false) };',
		$self->generate_type_constraint_setup,
		$self->generate_package_setup_oo,
		$self->generate_package_setup_methods,
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
	require Type::Registry;
	return map {
		my $lib = use_package_optimistically($_);
		$lib->isa('Type::Library')
			? "use $lib -types; BEGIN { 'Type::Registry'->for_me->add_types(q[$lib]) };" :
		$lib->can('type_names')
			? "use $lib ('$lib'->type_names); BEGIN { 'Type::Registry'->for_me->add_types(q[$lib]) };" :
		do { require Carp; Carp::croak("'$lib' is not a type constraint library") };
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

1;
