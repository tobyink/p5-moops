use v5.14;
use strict;
use warnings FATAL => 'all';
no warnings qw(void once uninitialized numeric);

package MooX::Aspartame::CodeGenerator;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

use Moo;
use B qw(perlstring);
use Module::Runtime qw(module_notional_filename);
use namespace::sweep;

has 'keyword'    => (is => 'ro');
has 'ccstash'    => (is => 'ro');
has 'package'    => (is => 'ro');
has 'version'    => (is => 'ro', predicate => 'has_version');
has 'relations'  => (is => 'ro');
has 'is_empty'   => (is => 'ro');
has 'imports'    => (is => 'ro', predicate => 'has_imports');

sub generate
{
	my $self = shift;
	my $class = ref $self;
	my $package = $self->package;
	
	# Create the package declaration and version
	my $inject = "package $package;";
	$inject .= "BEGIN { our \$VERSION = '${\ $self->version }' };" if $self->has_version;
	$inject .= "BEGIN { \$INC{${\ perlstring module_notional_filename $package }} = __FILE__ };";
	
	# Standard imports
	$inject .= $self->_package_preamble;
	
	# Additional imports
	$inject .= $self->imports->_generate_code if $self->has_imports;
	
	# Stuff that must happen at runtime rather than compile time
	$inject .= "'MooX::Aspartame'->_at_runtime('$package');";
	
	return $inject;		
}

sub _package_preamble
{
	my $self = shift;
	
	my @lines = (
		$self->_package_preamble_relationship_using,
		$self->_package_preamble_always,
	);
	
	my $rels = $self->relations;
	for my $key (sort keys %$rels)
	{
		next if $key eq 'using';
		my $method = "_package_preamble_relationship_$key";
		push @lines, $self->$method;
	}
	
	join " ", @lines;
}

sub _package_preamble_always
{
	my $self = shift;
	
	return if $self->is_empty;
	
	my $kw      = $self->keyword;
	my $class   = ref($self);
	my $package = $self->package;
	
	require MooX::Aspartame::MethodModifiers;
	return (
		'use Carp qw(confess);',
		"use Function::Parameters '$class'->_function_parameters_args(q[$kw], q[$package]);",
		'use MooX::Aspartame::DefineKeyword;',
		'use Scalar::Util qw(blessed);',
		'use Try::Tiny;',
		'use Types::Standard qw(-types);',
		'use constant { true => !!1, false => !!0 };',
		"use strict; use warnings FATAL => 'all'; no warnings qw(void once uninitialized numeric);",
	);
}

sub _package_preamble_relationship_extends
{
	my $self    = shift;
	my @classes = @{ $self->relations->{extends} || [] };
	
	return unless @classes;
	return sprintf "extends(%s);", join ",", map perlstring($_), @classes;
}

sub _package_preamble_relationship_with
{
	my $self  = shift;
	my @roles = @{ $self->relations->{with} || [] };
	
	return unless @roles;
	return sprintf "with(%s);", join ",", map perlstring($_), @roles;
}

{
	my %TEMPLATE1 = (
		Moo   => { class => 'use Moo; use MooX::late;',                role => 'use Moo::Role; use MooX::late;' },
		Moose => { class => 'use Moose;',                              role => 'use Moose::Role;' },
		Mouse => { class => 'use Mouse;',                              role => 'use Mouse::Role;' },
		Tiny  => {                                                     role => 'use Role::Tiny;' },
		(map { $_ => { role => "use $_;" } } qw/ Role::Basic Role::Tiny Moo::Role Mouse::Role Moose::Role /)
	);
	my %TEMPLATE2 = (
		class    => 'use namespace::sweep;',
		role     => 'use namespace::sweep;',
	);
	
	# For use with missing 'using' option
	$TEMPLATE1{''} = +{
		%{ $TEMPLATE1{'Moo'} },
		namespace => '',
	};
	
	sub _package_preamble_relationship_using
	{
		my $self  = shift;
		my $kw    = $self->keyword // 'namespace';
		my $using = $self->relations->{using}[0] // '';
		
		return (
			($TEMPLATE1{$using}{$kw} // croak("Cannot build $kw using $using")),
			($TEMPLATE2{$kw}//''),
		);
	}
}

sub _function_parameters_args
{
	my $class = shift;
	my ($kw, $pkg) = @_;
	
	my $reify = sub {
		require Type::Utils;
		Type::Utils::dwim_type($_[0], for => $_[1]);
	};
	
	my %keywords = (
		fun => {
			name                 => 'optional',
			default_arguments    => 1,
			check_argument_count => 1,
			named_parameters     => 1,
			types                => 1,
			reify_type           => $reify,
		},
	);
	
	if ($kw eq 'class' or $kw eq 'role')
	{
		$keywords{method} = {
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
		$keywords{ lc($_) } = {
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
	}
	
	return \%keywords;
}

1;
