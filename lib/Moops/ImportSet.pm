use v5.14;
use strict;
use warnings FATAL => 'all';
no warnings qw(void once uninitialized numeric);

package Moops::ImportSet;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.009';

use Moo;
use Module::Runtime qw(use_package_optimistically);
use namespace::sweep;

has imports => (is => 'ro');
has ident   => (is => 'ro', init_arg => undef, default => sub { state $x = 0; ++$x });

our %SAVED;

sub BUILD {
	my $self = shift;
	$SAVED{ $self->ident } = $self->imports;
}

sub do_imports {
	shift;
	my ($package, $ident) = @_;
	
	my $imports = $SAVED{$ident};
	
	require Import::Into;
	for my $import (@$imports)
	{
		my ($module, $params) = @$import;
		use_package_optimistically($module)->import::into(
			$package,
			(ref($params) eq q(HASH) ? %$params : ref($params) eq q(ARRAY) ? @$params : ()),
		);
	}
}

sub generate_code {
	my $self = shift;
	my ($pkg) = @_;
	my $class = ref $self;
	my $ident = $self->ident;
	return "BEGIN { '$class'->do_imports(q[$pkg], $ident) };";
}

1;
