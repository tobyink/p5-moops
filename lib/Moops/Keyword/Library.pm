use v5.14;
use strict;
use warnings FATAL => 'all';
no warnings qw(void once uninitialized numeric);

package Moops::Keyword::Library;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.021';

use Moo;
extends 'Moops::Keyword';
use namespace::sweep;

around generate_package_setup => sub
{
	my $orig = shift;
	my $self = shift;
	
	return (
		$self->$orig(@_),
		$self->generate_type_library_setup,
	);
};

sub generate_type_library_setup
{
	my $self = shift;
	
	my $use_type_library = "use Type::Library -base";
	if (@{ $self->relations->{declares} || [] })
	{
		my @types = @{$self->relations->{declares}};
		$use_type_library .= ", -declare => qw(@types)";
	}
	
	my $extends;
	if (@{ $self->relations->{extends} || [] })
	{
		my @parents = @{$self->relations->{extends}};
		$extends = "BEGIN { extends qw(@parents) }";
	}
	
	return (
		"$use_type_library;",
		"use Type::Utils -all;",
		($extends ? "$extends;" : ()),
	);
}

sub arguments_for_function_parameters
{
	my $class = shift;
	
	return +{
		fun => {
			name                 => 'optional',
			default_arguments    => 1,
			check_argument_count => 1,
			named_parameters     => 1,
			types                => 0,
		},
	};
}

sub known_relationships
{
	return qw/ extends declares /;
}

sub qualify_relationship
{
	$_[1] eq 'extends';
}

sub version_relationship
{
	$_[1] eq 'extends' or $_[1] eq 'types';
}

1;
