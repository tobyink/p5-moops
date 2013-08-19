use v5.14;
use strict;
use warnings FATAL => 'all';
no warnings qw(void once uninitialized numeric);

package Moops;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.009';

use Devel::Pragma qw(ccstash);
use Exporter::TypeTiny qw(mkopt);
use Keyword::Simple qw();
use Module::Runtime qw(use_package_optimistically);
use true qw();

sub class_for_import_set
{
	require Moops::ImportSet;
	'Moops::ImportSet';
}

sub class_for_parser
{
	require Moops::Parser;
	'Moops::Parser';
}

sub unimport
{
	my $class = shift;
	Keyword::Simple::undefine($_)
		for $class->class_for_parser->keywords;
}

sub import
{
	my $caller  = caller;
	my $class   = shift;
	
	my $imports = ref($_[0]) eq 'ARRAY'
		? $class->class_for_import_set->new(imports => mkopt(shift))
		: undef;
	
	'strict'->import();
	'warnings'->import(FATAL => 'all');
	'warnings'->unimport(qw(once void uninitialized numeric));
	'feature'->import(':5.14');
	'true'->import();
	
	my $parser_class = $class->class_for_parser;
	
	for my $kw ($parser_class->keywords)
	{
		Keyword::Simple::define $kw => sub
		{
			my $ref = $_[0];
			
			my $parser = $parser_class->new(
				keyword   => $kw,
				ref       => $ref,
				ccstash   => scalar(ccstash),
			);
			$parser->parse;
			
			my $code = $parser->code_generator($imports)->generate;
			substr($$ref, 0, 0) = ($parser->is_empty ? "{ $code }" : "{ $code ");
		};
	}
}

sub at_runtime
{
	my $class = shift;
	my ($pkg) = @_;
	for my $task (@{ $Moops::AT_RUNTIME{$pkg} })
	{
		my ($code, @args) = @$task;
		eval "package $pkg; \$code->(\@args)";
	}
}

sub _true  { !!1 };
sub _false { !!0 };

1;

__END__

=pod

=encoding utf-8

=for stopwords featureful

=head1 NAME

Moops - Moops Object-Oriented Programming Sugar

=head1 SYNOPSIS

   use Moops;
   
   role NamedThing {
      has name => (is => "ro", isa => Str);
   }
   
   class Person with NamedThing;
   
   class Company with NamedThing;
   
   class Employee extends Person {
      has job_title => (is => "rwp", isa => Str);
      has employer  => (is => "rwp", isa => InstanceOf["Company"]);
      
      method change_job ( Object $employer, Str $title ) {
         $self->_set_job_title($title);
         $self->_set_employer($employer);
      }
      
      method promote ( Str $title ) {
         $self->_set_job_title($title);
      }
   }

=head1 STATUS

Experimental.

I'll have more confidence in it once the test suite is complete.

=head1 DESCRIPTION

Moops is sugar for declaring and using roles and classes in Perl.

The syntax is inspired by L<MooseX::Declare>, and Stevan Little's
p5-mop-redux project (which is in turn partly inspired by Perl 6).

Moops has roughly only 40% as many dependencies as MooseX::Declare,
loads in about 25% of the time, and runs significantly faster.
Moops does not use Devel::Declare, instead using Perl's pluggable
keyword API; this requires Perl 5.14 or above.

Moops uses L<Moo> to build classes and roles by default, but allows
you to use L<Moose> if you desire. (And L<Mouse> experimentally.)

=head2 Classes

The C<class> keyword declares a class:

   class Foo {
      # ...
   }

A version number can be provided:

   class Foo 1.2 {
      # ...
   }

If no version is provided, your class' C<< $VERSION >> variable is set
to the empty string; this helps the package be seen by L<Class::Load>. 

If your class extends an existing class through inheritance, or
consumes one or more roles, these can also be provided when declaring
the class.

   class Foo::Bar 1.2 extends Foo with Magic::Monkeys {
      # ...
   }

If you use Moops within a package other than C<main>, then package
names used within the declaration are "qualified" by that outer
package, unless they contain "::". So for example:

   package Quux;
   use Moops;
   
   class Foo { }       # declares Quux::Foo
   
   class Xyzzy::Foo    # declares Xyzzy::Foo
      extends Foo { }  # ... extending Quux::Foo
   
   class ::Baz { }     # declares Baz

If you wish to use Moose or Mouse instead of Moo; include that in
the declaration:

   class Foo using Moose {
      # ...
   }

(The C<using> option is exempt from the package qualification rules
mentioned earlier.)

Note that it is possible to declare a class with an empty body;
use a trailing semicolon.

   class Employee extends Person with Employment;

If using Moose or Mouse, classes are automatically made immutable. If
using Moo, the L<MooX::late> extension is enabled.

L<namespace::sweep> is automatically used in all classes.

=head2 Roles

Roles can be declared similarly to classes, but using the C<role> keyword.

   role Stringable
      using Moose     # we know you meant Moose::Role
   {
      # ...
   }

Roles do not support the C<extends> option.

Roles can be declared to be C<< using Role::Tiny >>.

If roles use Moo, the L<MooX::late> extension is enabled.

L<namespace::sweep> is automatically used in all roles.

=head2 Namespaces

The C<namespace> keyword works as above, but declares a package without
any class-specific or role-specific semantics.

   namespace Utils {
      # ...
   }

L<namespace::sweep> is not automatically used in namespaces.

=head2 Functions and Methods

Moops uses L<Function::Parameters> to declare functions and methods within
classes and roles, which is perhaps not as featureful as L<Method::Signatures>,
but it does the job.

   class Person {
      use Scalar::Util 'refaddr';
      
      has name => (is => 'rwp');    # Moo attribute
      
      method change_name ( Str $newname ) {
         $self->_set_name( $newname )
            unless $newname eq 'Princess Consuela Banana-Hammock';
      }
      
      fun is_same_as ( Object $x, Object $y ) {
         refaddr($x) == refaddr($y)
      }
   }
   
   my $phoebe = Person->new(name => 'Phoebe');
   my $ursula = Person->new(name => 'Ursula');
   
   Person::is_same_as($phoebe, $ursula);   # false

Note function signatures use type constraints from L<Types::Standard>;
L<MooseX::Types> and L<MouseX::Types> type constraints should also
work, I<< provided you use their full names, including their package >>.

The C<is_same_as> function above could have been written as a class
method like this:

   class Person {
      # ...
      method is_same_as ( $class: Object $x, Object $y ) {
         refaddr($x) == refaddr($y)
      }
   }
   
   # ...
   Person->is_same_as($phoebe, $ursula);   # false

The C<method> keyword is not provided within packages declared using
C<namespace>; it is only available within classes and roles.

=head2 Method Modifiers

Within classes and roles, C<before>, C<after> and C<around> keywords
are provided for declaring method modifiers. These use the same syntax
as C<method>.

Unlike Moo/Mouse/Moose, for C<around> modifiers, the coderef being
wrapped is I<not> passed as C<< $_[0] >>. Instead, it's available in
the global variable C<< ${^NEXT} >>.

=head2 Type Constraints

The L<Types::Standard> type constraints are exported to each package
declared using Moops. This allows the standard type constraints to be
used as barewords.

If using type constraints from other type constraint libraries, they
should generally be usable by package-qualifying them:

   use MooseX::Types::Numeric qw();
   
   method foo ( MooseX::Types::Common::Numeric::PositiveInt $d ) {
      # ...
   }

Alternatively:

   use MooseX::Types::Common::Numeric qw(PositiveInt);
   
   method foo ( (SingleDigit) $d ) {
      # ...
   }

Note the parentheses around the type constraint in the method
signature; this is required for Function::Parameters to realise
that C<SingleDigit> is an imported symbol, and not a string to
be looked up.

(The version using the fully-qualified name should even work in
L<Moo> and L<Mouse> classes, because it forces the type constraint
to be loaded via (and wrapped by) Type::Tiny.)

=head2 Constants

The useful constants C<true> and C<false> are imported into all declared
packages. (Within classes and roles, namespace::sweep will later remove
them from the symbol table, so they don't form part of your package's API.)
These constants can help make attribute declarations more readable.

   has name => (is => 'ro', isa => Str, required => true);

Further constants can be declared using the C<define> keyword:

   namespace Maths {
      define PI = 3.2;
   }

Constants declared this way will I<not> be swept away by namespace::sweep,
and are considered part of your package's API.

=head2 More Sugar

Strictures, including fatal warnings, but excluding the 
C<uninitialized>, C<void>, C<once> and C<numeric> warning categories
is imported into all declared packages.

Perl 5.14 features, including the C<state> and C<say> keywords,
and sane Unicode string handling are imported into all declared
packages.

L<Try::Tiny> is imported into all declared packages.

L<Scalar::Util>'s C<blessed> and L<Carp>'s C<confess> are imported
into all declared packages.

=head2 Outer Sugar

The "outer" package, where the C<< use Moops >> statement appears also
gets a little sugar: strictures, the same warnings as "inner" packages,
and Perl 5.14 features are all switched on.

L<true> is loaded, so you don't need to do this at the end of your
file:

   1;

=head2 Custom Sugar

It is possible to inject other functions into all inner packages using:

   use Moops [
      'List::Util'      => [qw( first reduce )],
      'List::MoreUtils' => [qw( any all none )],
   ];

This is by far the easiest way to extend Moops with project-specific
extras.

=head1 EXTENDING

Moops is written to hopefully be fairly extensible.

=head2 The Easy Way

The easiest way to extend Moops is to inject additional imports into
the inner packages using the technique outlined in L</Custom Sugar>
above. You can wrap all that up in a module:

   package MoopsX::Lists;
   use Moops ();
   use List::Util ();
   use List::MoreUtils ();
   sub import {
      push @{ $_[1] ||= [] }, (
         'List::Util'      => [qw( first reduce )],
         'List::MoreUtils' => [qw( any all none )],
      );
      goto \&Moops::import;
   }
   1;

Now people can do C<< use MoopsX::Lists >> instead of C<< use Moops >>.

=head2 The Hard Way

For more complex needs, you should create a subclass of Moops, and
override the C<class_for_parser> method to inject your own custom
keyword parser, which should be a subclass of Moops::Parser.

The parser subclass might want to override:

=over

=item *

The C<keywords> class method, which returns the list of keywords
the parser can handle.

=item *

The C<relationships> object method, which returns a list of valid
inter-package relationships such as C<extends> and C<using> for the
current keyword (C<< $self->keyword >>).

=item *

The C<module_name_should_be_qualified> object method, which, when
given an inter-package relationship, indicates whether it should
be subjected to package qualification.

=item *

The C<class_for_code_generator> object method, which returns the name of
a subclass of Moops::CodeGenerator which will be used for translating
the result of parsing the keyword into a string using Perl's built-in
syntax.

=back

Hopefully you'll be able to avoid overriding the C<parse>
method itself, as it has a slightly messy API.

Your code generator subclass can either be a direct subclass of
Moops::CodeGenerator, or of Moops::CodeGenerator::Class or
Moops::CodeGenerator::Role.

The code generator subclass might want to override:

=over

=item *

The C<generate_package_setup> object method which returns a list of
strings to inject into the package.

=item *

The C<arguments_for_function_parameters> object method which is used
by the default C<generate_package_setup> method to set up the arguments
to be passed to L<Function::Parameters>.

=back

Hopefully you'll be able to avoid overriding the C<generate>
method.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Moops>.

=head1 SEE ALSO

Similar:
L<MooseX::Declare>,
L<https://github.com/stevan/p5-mop-redux>.

Main functionality exposed by this module:
L<Moo>/L<MooX::late>, L<Function::Parameters>, L<Try::Tiny>,
L<Types::Standard>, L<namespace::sweep>, L<true>.

Internals fueled by:
L<Keyword::Simple>, L<Module::Runtime>, L<Import::Into>, L<Devel::Pragma>,
L<Attribute::Handlers>.

L<http://en.wikipedia.org/wiki/The_Bubble_Boy_(Seinfeld)>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

