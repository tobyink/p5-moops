use v5.14;
use strict;
use warnings FATAL => 'all';
no warnings qw(void once uninitialized numeric);

package MooX::Aspartame::CodeGenerator::Class;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

use Moo;
extends qw( MooX::Aspartame::CodeGenerator::Role );

{
	my %using = (
		Moo   => 'use Moo; use MooX::late;',
		Moose => 'use Moose;',
		Mouse => 'use Mouse;',
	);
	
	sub generate_package_setup_oo
	{
		my $self  = shift;
		my $using = $self->relations->{using}[0] // 'Moo';
		
		exists($using{$using})
			or Carp::croak("Cannot create a package using $using; stopped");
		
		return (
			$using{$using},
			$self->generate_package_setup_relationships,
			'use namespace::sweep;',
		);
	}
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

1;
