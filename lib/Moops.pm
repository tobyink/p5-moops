use v5.14;
use strict;
use warnings FATAL => 'all';
no warnings qw(void once uninitialized numeric);

package Moops;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.020';

use Devel::Pragma qw(ccstash);
use Exporter::TypeTiny qw(mkopt);
use Keyword::Simple qw();
use Module::Runtime qw(use_package_optimistically);
use feature qw();
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
	my $class   = shift;
	my %opts    = ref($_[0]) eq 'ARRAY' ? ( imports => $_[0] ) : @_;
	
	my $imports = ref($opts{imports}) eq 'ARRAY'
		? $class->class_for_import_set->new(imports => mkopt($opts{imports}))
		: undef;
	
	'strict'->import();
	'warnings'->import(FATAL => 'all');
	'warnings'->unimport(qw(once void uninitialized numeric));
	'feature'->import(':5.14');
	'true'->import();
	
	my $parser_class = $opts{traits}
		? do {
			require Moo::Role;
			'Moo::Role'->create_class_with_roles($class->class_for_parser, @{$opts{traits}})
		}
		: $class->class_for_parser;
	
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
			
			my %attrs;
			$attrs{imports} = $imports if defined $imports;
			my $kw = $parser->keyword_object(%attrs);
			
			my $code = $kw->generate_code;
			substr($$ref, 0, 0) = ($parser->is_empty ? "BEGIN { $code }" : "BEGIN { $code ");
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

=for stopwords featureful ro rw rwp

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

Unstable.

Until version 1.000, stuff might change, but not without good
reason.

=head1 DESCRIPTION

Moops is sugar for declaring and using roles and classes in Perl.

The syntax is inspired by L<MooseX::Declare>, and Stevan Little's
p5-mop-redux project (which is in turn partly inspired by Perl 6).

Moops has fewer than half of the dependencies as MooseX::Declare,
loads in about 25% of the time, and the classes built with it run
significantly faster. Moops does not use Devel::Declare, instead
using Perl's pluggable keyword API; I<< this requires Perl 5.14
or above >>.

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

It's also possible to create classes C<< using Tiny >> (L<Class::Tiny>),
but there's probably little point in it, because Moops uses Moo
internally, so the more capable Moo is already loaded and in memory.

(The C<using> option is exempt from the package qualification rules
mentioned earlier.)

Moops uses L<MooseX::MungeHas> in your classes so that the C<has> keyword
supports some Moo-specific features, even when you're using Moose or Mouse.
Specifically, it supports C<< is => 'rwp' >>, C<< is => 'lazy' >>,
C<< builder => 1 >>, C<< clearer => 1 >>, C<< predicate => 1 >>, and
C<< trigger => 1 >>. If you're using Moo, the L<MooX::late> extension is
enabled too, which allows Moose-isms in Moo too. With the combination of
these features, there should be very little difference between Moo, Mouse
and Moose C<has> keywords.

Moose classes are automatically accelerated using L<MooseX::XSAccessor>
if it's installed.

Note that it is possible to declare a class with an empty body;
use a trailing semicolon.

   class Employee extends Person with Employment;

If using Moose or Mouse, classes are automatically made immutable. 

L<namespace::sweep> is automatically used in all classes.

Between the class declaration and its body, L<Attribute::Handlers>-style
attributes may be provided:

   class Person :mutable {
      # ...
   }
   
   class Employee extends Person with Employment :mutable;

The following attributes are defined for classes:

=over

=item *

C<< :assertions >> - enables assertion checking (see below)

=item *

C<< :dirty >> - suppresses namespace::sweep

=item *

C<< :mutable >> - suppresses making Moose classes immutable

=item *

C<< :ro >> - make attributes declared with C<has> default to 'ro'

=item *

C<< :rw >> - make attributes declared with C<has> default to 'rw'

=item *

C<< :rwp >> - make attributes declared with C<has> default to 'rwp'

=back

=head2 Roles

Roles can be declared similarly to classes, but using the C<role> keyword.

   role Stringable
      using Moose     # we know you meant Moose::Role
   {
      # ...
   }

Roles do not support the C<extends> option.

Roles can be declared to be C<< using >> Moo, Moose, Mouse or Tiny.
(Note that if you're mixing and matching role frameworks, there are
limitations to which class builders can consume which roles. Mouse
is generally the least compatible; Moo and Moose classes should be
able to consume each others' roles; Moo can also consume Role::Tiny
roles.)

If roles use Moo, the L<MooX::late> extension is enabled.

L<namespace::sweep> is automatically used in all roles.

Roles take similar L<Attribute::Handlers>-style attributes to
classes, but don't support C<< :mutable >>.

=head2 Namespaces

The C<namespace> keyword works as above, but declares a package without
any class-specific or role-specific semantics.

   namespace Utils {
      # ...
   }

L<namespace::sweep> is not automatically used in namespaces.

L<Attribute::Handlers>-style attributes are supported for namespaces,
but most of the built-in attributes make any sense without class/role
semantics. (C<< :assertions >> does.) Traits written as Moops extensions
may support namespaces.

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

Within Moose classes and roles, the L<MooseX::FunctionParametersInfo>
module is loaded, to allow access to method signatures via the meta
object protocol. (This is currently broken for C<around> method modifiers.)

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

Type constraints can be used in attribute definitions (C<isa>) and
method signatures. Because Types::Standard is based on L<Type::Tiny>,
the same type constraints may be used whether you build your classes
and roles with Moo, Moose our Mouse.

Alternative libraries can be imported using the C<types> option; a la:

   class Document types Types::XSD::Lite {
      has title => (is => 'rw', isa => NormalizedString);
   }

Note that if an alternative type constraint library is imported, then
L<Types::Standard> is I<not> automatically loaded, and needs to be
listed explicitly:

   class Document types Types::Standard, Types::XSD::Lite {
      # ...
   }

Type libraries built with L<Type::Library>, L<MooseX::Types> and
L<MouseX::Types> should all work.

Bear in mind that type constraints from, say, a L<MooseX::Types>
library won't be usable in, say, Moo attribute definitions. However,
it's possible to wrap them with Type::Tiny, and make them usable:

   class Foo types MooseX::Types::Common::Numeric using Moo {
      use Types::TypeTiny qw( to_TypeTiny );
      
      has favourite_number => (
         is  => 'rwp',
         isa => to_TypeTiny(PositiveInt)
      );
   }

=head2 Type Libraries

You can use the C<library> keyword to declare a new type library:

   library MyTypes
      extends Types::Standard
      declares EmptyString, NonEmptyString {
      
      declare EmptyString,
         as Str,
         where { length($_) == 0 };
      
      declare NonEmptyString,
         as Str,
         where { length($_) > 0 };
   }
   
   class StringChecker types MyTypes {
      method check ( Str $foo ) {
         return "empty" if EmptyString->check($foo);
         return "non-empty" if NonEmptyString->check($foo);
         return "impossible?!";
      }
   }

Libraries declared this way can extend existing type libraries
written with L<Type::Library>, L<MooseX::Types> or L<MouseX::Types>.

Note that this also provides a solution to the previously mentioned
problem of using L<MooseX::Types> type libraries in L<Moo> classes:

   library MyWrapper
      extends MooseX::Types::Common::Numeric;
   
   class Foo types MyWrapper using Moo {
      has favourite_number => (
         is  => 'rwp',
         isa => PositiveInt,
      );
   }

=head2 Constants

The useful constants C<true> and C<false> are imported into all declared
packages. (Within classes and roles, namespace::sweep will later remove
them from the symbol table, so they don't form part of your package's API.)
These constants can help make attribute declarations more readable.

   has name => (is => 'ro', isa => Str, required => true);

Further constants can be declared using the C<define> keyword (see
L<PerlX::Define>):

   namespace Maths {
      define PI = 3.2;
   }

Constants declared this way will I<not> be swept away by namespace::sweep,
and are considered part of your package's API.

=head2 Assertions

Declared packages can contain assertions (see L<PerlX::Assert>). These
are normally optimized away at compile time, but you can force them to
be checked using the C<< :assertions >> attribute.

   class Foo {
      assert(false);    # not checked; optimized away
   }
   
   class Bar :assertions {
      assert(false);    # checked; fails; throws exception
   }

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

   use Moops imports => [
      'List::Util'      => [qw( first reduce )],
      'List::MoreUtils' => [qw( any all none )],
   ];

This is by far the easiest way to extend Moops with project-specific
extras.

=head1 EXTENDING

Moops is written to hopefully be fairly extensible.

=head2 Extending Moops via imports

The easiest way to extend Moops is to inject additional imports into
the inner packages using the technique outlined in L</Custom Sugar>
above. You can wrap all that up in a module:

   package MoopsX::Lists;
   use base 'Moops';
   use List::Util ();
   use List::MoreUtils ();
   
   sub import {
      my ($class, %opts) = @_;
      
      push @{ $opts{imports} ||= [] }, (
         'List::Util'      => [qw( first reduce )],
         'List::MoreUtils' => [qw( any all none )],
      );
      
      $class->SUPER::import(%opts);
   }
   
   1;

Now people can do C<< use MoopsX::Lists >> instead of C<< use Moops >>.

=head2 Extending Moops via keyword traits

Roles in the C<Moops::TraitFor::Keyword> namespace are automatically
loaded and applied to keyword objects when a corresponding
Attribute::Handlers-style attribute is seen.

For examples extending Moops this way, see the
L<Moops::TraitFor::Keyword::dirty>,
L<Moops::TraitFor::Keyword::mutable>,
L<Moops::TraitFor::Keyword::ro>,
L<Moops::TraitFor::Keyword::rw> and
L<Moops::TraitFor::Keyword::rwp> traits.

=head2 Extending Moops via parser traits

For more complex needs, you can create a trait which will be applied to
Moops::Parser.

Parser traits might want to override:

=over

=item *

The C<keywords> class method, which returns the list of keywords
the parser can handle.

=item *

The C<class_for_keyword> object method, which returns the name of
a subclass of Moops::Keyword which will be used for translating
the result of parsing the keyword into a string using Perl's built-in
syntax.

=back

Hopefully you'll be able to avoid overriding the C<parse>
method itself, as it has a slightly messy API.

Your C<class_for_keyword> subclass can either be a direct subclass of
Moops::Keyword, or of Moops::Keyword::Class or Moops::Keyword::Role.

The keyword subclass might want to override:

=over

=item *

The C<known_relationships> class method, which returns a list of valid
inter-package relationships such as C<extends> and C<using> for the
current keyword.

=item *

The C<qualify_relationship> object method, which, when given the name of
an inter-package relationship, indicates whether it should be subjected
to package qualification rules (like C<extends> and C<with> are, but
C<using> is not).

=item *

The C<generate_package_setup> object method which returns a list of
strings to inject into the package.

=item *

The C<arguments_for_function_parameters> object method which is used
by the default C<generate_package_setup> method to set up the arguments
to be passed to L<Function::Parameters>.

=back

Hopefully you'll be able to avoid overriding the C<generate_code>
method.

You can apply your trait using:

   use Moops traits => [
      'Moops::TraitFor::Parser::FooKeyword',
      'Moops::TraitFor::Parser::BarKeyword',
   ];

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

