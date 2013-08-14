use v5.14;
use strict;
use warnings FATAL => 'all';
no warnings qw(void once uninitialized numeric);

package MooX::Aspartame;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

use Devel::Pragma qw(ccstash);
use Exporter::TypeTiny qw(mkopt);
use Keyword::Simple qw();
use Module::Runtime qw(use_package_optimistically);
use true qw();

sub class_for_import_set
{
	require MooX::Aspartame::ImportSet;
	'MooX::Aspartame::ImportSet';
}

sub class_for_parser
{
	require MooX::Aspartame::Parser;
	'MooX::Aspartame::Parser';
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
	
	for my $kw (qw/class role namespace/)
	{
		Keyword::Simple::define $kw => sub
		{
			my $ref = $_[0];
			
			my $parser = $class->class_for_parser->new(
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
	for my $task (@{ $MooX::Aspartame::AT_RUNTIME })
	{
		my ($code, @args) = @$task;
		eval "package $pkg; \$code->(\@args)";
	}
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

MooX::Aspartame - it seems sweet, but it probably has long-term adverse health effects

=head1 SYNOPSIS

   use MooX::Aspartame;
   
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

=head1 DESCRIPTION

This is something like a lightweight L<MooseX::Declare>. (Only 40% as
many dependencies; and loads in about 25% of the time.)

It gives you three keywords:

=over

=item C<class>

Declares a class. By default this uses L<Moo>. But it's possible to
promote a class to L<Moose> with the C<using> option:

   class Employee using Moose { ... }

Other options for classes are C<extends> for setting a parent class,
and C<with> for composing roles.

   class Employee extends Person with Employment;

Note that if you're not directly defining any methods for a class,
you can use a trailing semicolon (as above) rather than an empty
C<< { } >> pair.

=item C<role>

Declares a role using L<Moo::Role>. This also supports C<< using Moose >>,
and C<with>.

=item C<namespace>

Declares a package without giving it any special semantics.

=back

Note that the names of the declared things get qualified like subs. So:

   package Foo;
   use MooX::Aspartame;
   
   class Bar {     # declares Foo::Bar
      role Baz {   # declares Foo::Bar::Baz
         ...;
      }
      class Xyzzy with Baz;
   }
   class ::Quux {  # declares Quux
      ...;
   }
   
   package main;
   use MooX::Aspartame;
   
   class Bar {     # declares Bar
      ...;
   }

Within the packages declared by these keywords, the following features are
always available:

=over

=item *

Perl 5.14 features. (MooX::Aspartame requires Perl 5.14.)

=item *

Strictures, including C<FATAL> warnings. 

But not C<uninitialized>, C<void>, C<once> or C<numeric> warnings,
because those are irritating.

=item *

L<Function::Parameters> (in strict mode).

This provides the C<fun> keyword.

Within roles and classes, it also provides C<method>, and the
C<before>, C<after> and C<around> method modifiers. Unlike Moo/Moose,
within C<around> modifiers the coderef being wrapped is I<not> available
in C<< $_[0] >>, but is instead found in the magic global variable
C<< ${^NEXT} >>.

=item *

A C<define> keyword to declare constants:

   use MooX::Aspartame;
   
   class Calculator {
      define PI = 3.2;
      method circular_area (Num $r) {
         return PI * ($r ** 2);
      }
   }
   
   my $calc = Calculator->new;
   say "The circle's area is ", $calc->circular_area(r => 1.0);

=item *

L<Try::Tiny>

=item *

L<Types::Standard> type constraints

=item *

L<Carp>'s C<confess>

=item *

L<Scalar::Util>'s C<blessed>

=item *

Constants for C<true> and C<false>.

=item *

L<namespace::sweep> (only for classes and roles).

=back

It is possible to inject other functions into all packages using:

   use MooX::Aspartame [
      'List::Util'      => [qw( first reduce )],
      'List::MoreUtils' => [qw( any all none )],
   ];

In the "outer" package (where MooX::Aspartame is used), strictures and
L<true> are provided.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooX-Aspartame>.

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

