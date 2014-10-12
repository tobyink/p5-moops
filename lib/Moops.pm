use v5.14;
use strict;
use warnings FATAL => 'all';
no warnings qw(void once uninitialized numeric);

package Moops;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.034';

use Exporter::Tiny qw(mkopt);
use Keyword::Simple qw();
use Parse::Keyword qw();
use Module::Runtime qw(use_package_optimistically);
use feature qw();
use true qw();

# Disable 'experimental' warning categories because these lead to
# inconsistencies between the different Perl versions supported by
# Moops.
#
# Disable 'void', 'once', 'uninitialized' and 'numeric' because
# they are annoying.
#
# New warnings categories provided by new releases of Perl will not
# be added here (but they may be added to a @NONFATAL_WARNINGS array).
#

our @FATAL_WARNINGS = (
	'ambiguous',
	'bareword',
	'closed',
	'closure',
	'debugging',
	'deprecated',
	'digit',
	'exec',
	'exiting',
#	'experimental',
#	'experimental::lexical_subs',
#	'experimental::lexical_topic',
#	'experimental::regex_sets',
#	'experimental::smartmatch',
	'glob',
	'illegalproto',
	'imprecision',
	'inplace',
	'internal',
	'io',
	'layer',
	'malloc',
	'misc',
	'newline',
	'non_unicode',
	'nonchar',
#	'numeric',
#	'once',
	'overflow',
	'pack',
	'parenthesis',
	'pipe',
	'portable',
	'precedence',
	'printf',
	'prototype',
	'qw',
	'recursion',
	'redefine',
	'regexp',
	'reserved',
	'semicolon',
	'severe',
	'signal',
	'substr',
	'surrogate',
	'syntax',
	'taint',
	'threads',
#	'uninitialized',
	'unopened',
	'unpack',
	'untie',
	'utf8',
#	'void',
);

# Don't tamper please!
Internals::SvREADONLY(@FATAL_WARNINGS, 1);

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
	my %opts    = (
		ref($_[0]) eq 'ARRAY'              ? (imports => $_[0]) :
		(!ref($_[0]) and $_[0] eq -strict) ? (imports => ['strictures']) :
		@_
	);
	
	my $imports = ref($opts{imports}) eq 'ARRAY'
		? $class->class_for_import_set->new(imports => mkopt($opts{imports}))
		: undef;
	
	'strict'->import();
	'warnings'->unimport();
	'warnings'->import(FATAL => @FATAL_WARNINGS);
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
				ccstash   => Parse::Keyword::compiling_package(),
			);
			$parser->parse;
			
			my %attrs;
			$attrs{imports} = $imports if defined $imports;
			my $kw = $parser->keyword_object(%attrs);
			
			if ($opts{function_parameters_everywhere}
			or $ENV{'MOOPS_FUNCTION_PARAMETERS_EVERYWHERE'})
			{
				require Moo::Role;
				'Moo::Role'->apply_roles_to_object($kw, 'Moops::TraitFor::Keyword::fp');
			}
			
			$kw->check_prerequisites;
			
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

=for stopwords featureful ro rw rwp superset

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

=head2 Planned Changes

=over

=item *

Support for using Function::Parameters to handle method signatures
is likely to be dropped.

=item *

Parameterized class and parameterized role support is planned.

=item *

The internals for parsing C<class>, C<role>, C<namespace>, and C<library>
may change to use L<Parse::Keyword> rather than L<Keyword::Simple>. This
will likely break any extensions that rely on subclassing or adding traits
to the L<Moops::Parser> or L<Moops::Keyword> classes.

=back

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

   class Foo::Bar 1.2 extends Foo 1.1 with Magic::Monkeys {
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

Moops uses L<Lexical::Accessor> to provide you with private (lexical)
attributes - that is, attributes accessed via a coderef method in a
lexical variable.

   class Foo {
      lexical_has foo => (
         isa      => Int,
         accessor => \(my $_foo),
         default  => 0,
      );
      method increment_foo () {
         $self->$_foo( 1 + $self->$_foo );
      }
      method get_foo () {
         return $self->$_foo;
      }
   }
   
   my $x = Foo->new;
   $x->increment_foo();     # ok
   say $x->get_foo();       # says "1"
   $x->$_foo(42);           # dies; $_foo does not exist in this scope

Moose classes are automatically accelerated using L<MooseX::XSAccessor>
if it's installed.

Note that it is possible to declare a class with an empty body;
use a trailing semicolon.

   class Employee extends Person with Employment;

If using Moose or Mouse, classes are automatically made immutable. 

L<namespace::autoclean> is automatically used in all classes.

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

C<< :dirty >> - suppresses namespace::autoclean

=item *

C<< :fp >> - use L<Function::Parameters> instead of L<Kavorka>

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

L<namespace::autoclean> is automatically used in all roles.

Roles take similar L<Attribute::Handlers>-style attributes to
classes, but don't support C<< :mutable >>.

=head3 A note on consuming roles

In a standard:

   class MyClass with MyRole {
      ...;
   }

You should note that role composition is delayed to happen at the
I<end> of the class declaration. This is usually what you want.

However the interaction between method modifiers and roles is
complex, and I<sometimes> you'll want the role to be applied to
the class part-way through the declaration. In this case you can
use a C<with> statement I<inside> the class declaration:

   class MyClass {
      ...;
      with "MyRole";
      ...;
   }

=head2 Namespaces

The C<namespace> keyword works as above, but declares a package without
any class-specific or role-specific semantics.

   namespace Utils {
      # ...
   }

L<namespace::autoclean> is not automatically used in namespaces.

L<Attribute::Handlers>-style attributes are supported for namespaces,
but most of the built-in attributes make any sense without class/role
semantics. (C<< :assertions >> does.) Traits written as Moops extensions
may support namespaces.

=head2 Functions and Methods

Moops uses L<Kavorka> to declare functions and methods within classes
and roles. Kavorka provides the C<fun> and C<method> keywords.

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
C<namespace>; only within classes and roles.

See also L<Kavorka::Manual::Methods> and L<Kavorka::Manual::Functions>.

Within Moose classes and roles, the L<MooseX::KavorkaInfo> module is
loaded, to allow access to method signatures via the meta object
protocol. (This is currently broken for C<around> method modifiers.)

In Moops prior to 0.025, L<Function::Parameters> was used instead of
Kavorka. If you wish to continue to use Function::Parameters in a class
you can use the C<< :fp >> attribute:

   class Person :fp {
      ...;
   }

Or to do so for all classes in a lexical scope:

   use Moops function_parameters_everywhere => 1;
   class Person {
      ...;
   }

Or the environment variable C<MOOPS_FUNCTION_PARAMETERS_EVERYWHERE> can
be set to true to enable it globally, but this feature is likely to be
removed eventually.

=head2 Method Modifiers

Within classes and roles, C<before>, C<after> and C<around> keywords
are provided for declaring method modifiers. These use the same syntax
as C<method>.

If your class or role is using Moose or Mouse, then you also get
C<augment> and C<override> keywords.

See also L<Kavorka::Manual::MethodModifiers>.

=head2 Multi Methods

L<Moops> uses L<Kavorka> to implement multi subs and multi methods.

See also L<Kavorka::Manual::MultiSubs>.

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
packages. (Within classes and roles, namespace::autoclean will later remove
them from the symbol table, so they don't form part of your package's API.)
These constants can help make attribute declarations more readable.

   has name => (is => 'ro', isa => Str, required => true);

Further constants can be declared using the C<define> keyword (see
L<PerlX::Define>):

   namespace Maths {
      define PI = 3.2;
   }

Constants declared this way will I<not> be swept away by namespace::autoclean,
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

L<strict> and FATAL L<warnings> are imported into all declared packages.
However the C<uninitialized>, C<void>, C<once> and C<numeric> warning
categories are explicitly excluded, as are any warnings categories added
to Perl after version 5.14.

Perl 5.14 features, including the C<state> and C<say> keywords,
and sane Unicode string handling are imported into all declared
packages.

L<Try::Tiny> is imported into all declared packages.

L<Scalar::Util>'s C<blessed> and L<Carp>'s C<confess> are imported
into all declared packages.

=head2 Outer Sugar

The "outer" package, where the C<< use Moops >> statement appears also
gets a little sugar: strict, the same warnings as "inner" packages, and
Perl 5.14 features are all switched on.

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

There is a shortcut for injecting L<strictures> into all inner packages:

   use Moops -strict;

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

The C<qualify_relationship> class method, which, when given the name of
an inter-package relationship, indicates whether it should be subjected
to package qualification rules (like C<extends> and C<with> are, but
C<using> is not).

=item *

The C<version_relationship> class method, which, when given the name of
an inter-package relationship, indicates whether it should accept a version
number.

=item *

The C<generate_package_setup> object method which returns a list of
strings to inject into the package.

=item *

The C<arguments_for_function_parameters> object method which is used
by the default C<generate_package_setup> method to set up the arguments
to be passed to L<Function::Parameters>.

=item *

The C<check_prerequisites> method which performs certain pre-flight checks
and may throw an exception.

=back

Hopefully you'll be able to avoid overriding the C<generate_code>
method.

You can apply your trait using:

   use Moops traits => [
      'Moops::TraitFor::Parser::FooKeyword',
      'Moops::TraitFor::Parser::BarKeyword',
   ];

=head1 BUGS

Please report any other bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Moops>.

=head1 SUPPORT

B<< IRC: >> support is available through in the I<< #moops >> channel
on L<irc.perl.org|http://www.irc.perl.org/channels.html>.

For general Moose/Moo queries which don't seem to be related to Moops'
syntactic sugar, your question may be answered more quickly in the
I<< #moose >> channel.

B<< Web: >> if you ask a question on PerlMonks in
L<Seekers of Perl Wisdom|http://www.perlmonks.org/?node_id=479> with
"Moops" in the subject line, it should be answered pretty quickly.

There is a L<moops tag|http://stackoverflow.com/questions/tagged/moops>
on StackOverflow.

=head1 SEE ALSO

Similar:
L<MooseX::Declare>,
L<https://github.com/stevan/p5-mop-redux>.

Main functionality exposed by this module:
L<Moo>/L<MooX::late>, L<Kavorka>, L<Try::Tiny>, L<Types::Standard>,
L<namespace::autoclean>, L<true>, L<PerlX::Assert>.

Internals fueled by:
L<Keyword::Simple>, L<Module::Runtime>, L<Import::Into>,
L<Attribute::Handlers>.

L<http://en.wikipedia.org/wiki/The_Bubble_Boy_(Seinfeld)>.

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

