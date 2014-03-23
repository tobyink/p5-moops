use 5.008;
use strict;
use warnings;

use Moose ();
use Function::Parameters ();
use Function::Parameters::Info ();

my $dummy = 'Function::Parameters::Info'->new(
	keyword              => 'sub',
	slurpy               => 'Function::Parameters::Param'->new(type => undef, name => '@_'),
	invocant             => undef,
	_positional_required => [],
	_named_required      => [],
	_positional_optional => [],
	_named_optional      => [],
);

{
	package MooseX::FunctionParametersInfo;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.031';
	
	sub _unwrap
	{
		my $coderef = shift;
		$MooseX::FunctionParametersInfo::WRAPPERS{"$coderef"} || $coderef;
	}
	
	sub import
	{
		my $meta = Class::MOP::class_of(scalar caller);
		Moose::Util::MetaRole::apply_metaroles(
			for             => $meta,
			role_metaroles  => {
				method          => ['MooseX::FunctionParametersInfo::Trait::Method'],
			},
			class_metaroles => {
				method          => ['MooseX::FunctionParametersInfo::Trait::Method'],
				wrapped_method  => ['MooseX::FunctionParametersInfo::Trait::WrappedMethod'],
			},
		);
	}
}

{
	package MooseX::FunctionParametersInfo::Trait::Method;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.031';
	
	use Moose::Role;
	
	has _info => (
		is        => 'ro',
		lazy      => 1,
		builder   => '_build_info',
		handles   => {
			declaration_keyword            => 'keyword',
			slurpy_parameter               => 'slurpy',
			invocant_parameter             => 'invocant',
			positional_required_parameters => 'positional_required',
			named_required_parameters      => 'named_required',
			positional_optional_parameters => 'positional_optional',
			named_optional_parameters      => 'named_optional',
			minimum_parameters             => 'args_min',
			maximum_parameters             => 'args_max',
		},
	);
	
	sub _build_info
	{
		my $self = shift;
		Function::Parameters::info(
			MooseX::FunctionParametersInfo::_unwrap($self->body)
		) or $dummy;
	}
	
	sub positional_parameters
	{
		my $self = shift;
		( $self->positional_required_parameters, $self->positional_optional_parameters );
	}
	
	sub named_parameters
	{
		my $self = shift;
		( $self->named_required_parameters, $self->named_optional_parameters );
	}
}

{
	package MooseX::FunctionParametersInfo::Trait::WrappedMethod;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.031';
	
	use Moose::Role;
	with 'MooseX::FunctionParametersInfo::Trait::Method';
	
	around _build_info => sub
	{
		my $orig = shift;
		my $self = shift;
		Function::Parameters::info(
			MooseX::FunctionParametersInfo::_unwrap($self->get_original_method->body)
		) or $dummy;
	};
}

1;

__END__

=pod

=encoding utf-8

=for stopwords invocant

=head1 NAME

MooseX::FunctionParametersInfo - make Function::Parameters::info() data available within the meta object protocol

=head1 SYNOPSIS

   package Foo {
      use Function::Parameters;
      use Moose;
      use MooseX::FunctionParametersInfo;
      
      method bar (Str $x, Int $y) {
         ...;
      }
   }
   
   my $method = Class::MOP::class_of('Foo')->get_method('bar');
   printf("%s %s\n", $_->type, $_->name)
      for $method->positional_parameters;
   
   __END__
   Str $x
   Int $y

=head1 DESCRIPTION

L<Function::Parameters> provides declarative sugar for processing arguments
to subs, and provides a small API to query the declarations.

L<Moose> provides a comprehensive introspection API for Perl classes.

MooseX::FunctionParametersInfo marries them together, injecting information
from Function::Parameters into Moose's meta objects.

MooseX::FunctionParametersInfo is currently distributed as part of L<Moops>,
but is fairly independent of the rest of it, and may be spun off as a
separate release in the future.

=head2 Methods

MooseX::FunctionParametersInfo adds the following methods to the
L<Moose::Meta::Method> objects for your class. If your method is wrapped,
it is the info from the original (wrapped) method that is reported; not
the info from the wrapper. If your method was not declared via
Function::Parameters (e.g. it was declared using the Perl built-in
C<< sub >> keyword) then we make a best guess.

Methods that return parameters, return L<Function::Parameters::Parameter>
objects, which have C<name> and C<type> methods. The type (if any) will be
a blessed type constraint object, such as a L<Moose::Meta::TypeConstraint>
or L<Type::Tiny> object.

=over

=item C<declaration_keyword>

Returns the name of the keyword used to declare the method;
e.g. C<< "sub" >> or C<< "method" >>.

=item C<slurpy_parameter>

The array parameter into which additional arguments will be
slurped, or undef.

=item C<invocant_parameter>

The parameter which is the method's invocant (typically,
C<< $self >> or C<< $class >>), or undef.

=item C<positional_required_parameters>,
C<positional_optional_parameters>
C<named_required_parameters>,
C<named_optional_parameters>

Returns the appropriate parameters as a list.

=item C<positional_parameters>, C<named_parameters>

A list of the required parameters followed by optional parameters.

=item C<minimum_parameters>, C<maximum_parameters>

The minimum and maximum number of parameters the method can take.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Moops>.

=head1 SEE ALSO

L<Moose>, L<Function::Parameters>, L<Function::Parameters::Info>.

L<Moops>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
