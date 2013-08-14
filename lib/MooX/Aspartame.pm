package MooX::Aspartame;

my @crud;
BEGIN { @crud = qw(void once uninitialized numeric) };

use 5.014;
use warnings FATAL => 'all';
no warnings @crud;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use B                               qw(perlstring);
use Carp                            qw(croak);
use Devel::Pragma         0.54      qw(ccstash);
use Exporter::TypeTiny    0.014     qw(mkopt);
use Function::Parameters  1.0104    qw();
use Import::Into          1.000000  qw();
use Keyword::Simple       0.01      qw();
use Module::Runtime       0.013     qw($module_name_rx module_notional_filename use_package_optimistically);
use Moo                   1.002000  qw();
use MooX::late            0.014     qw();
use Scalar::Util          1.24      qw();
use Try::Tiny             0.12      qw();
use Type::Utils           0.022     qw();
use namespace::sweep      0.006;
use true                  0.18;

my @IMPORTS;

sub unimport
{
	shift;
	Keyword::Simple::undefine $_ for qw/ class role namespace /;
}

sub import
{
	my $class  = shift;
	my $caller = caller;
	
	our $_;
	$_->[0]->import::into($caller, @{ $_->[1] || [] })
		for (
			[ strict      => [] ],
			[ warnings    => [ FATAL => 'all' ] ],
			[ feature     => [ ':5.14' ] ],
			[ true        => [] ],
		);
	warnings->unimport(@crud);
	
	my $imports = mkopt($_[0] || []);
	push @IMPORTS, $imports;
	my $id = $#IMPORTS;
	
	for my $kw (qw/class role namespace/)
	{
		Keyword::Simple::define $kw => sub
		{
			# Figure out the parent package holding the declaration.
			my $caller = ccstash;
			
			# First thing after the keyword is the name of the package
			# being declared.
			my $ref = shift;
			my ($space1, $package, $space2) = ($$ref =~ /^(\s*)((?:::)?$module_name_rx)\b(\s*)/sm);
			substr($$ref, 0, length($space1.$package.$space2)) = "";
			
			# This is optionally followed by a version number.
			my $ver;
			if (my ($version, $space4) = ($$ref =~ /^(v?[0-9._]+)\b(\s*)/sm))
			{
				$ver = $version;
				substr($$ref, 0, length($version.$space4)) = "";
			}
			
			# Then a list of relationships such as `extends Foo`.
			my $RELS = join '|', map quotemeta, $class->_relationships($kw);
			my %relationships;
			while ($$ref =~ /^($RELS)(\s+)((?:::)?$module_name_rx(?:\s*,\s*(?:::)?$module_name_rx)*)\b(\s*)/sm)
			{
				my $rel = $1; my $space1 = $2; my $modules = $3; my $space2 = $4;
				substr($$ref, 0, length($rel.$space1.$modules.$space2)) = "";
				my @modules = split /\s*,\s*/, $modules;
				push @{ $relationships{$rel}||=[] }, map $class->_qualify($_, $caller, $rel), @modules;
			}
			
			# Next we expect either the start of a block, or a semicolon.
			die "syntax error near $kw $package - expected '{' or ';' - got '".substr($$ref, 0, 6)."'"
				unless $$ref =~ m/^([\{;])/;
			my $empty = ($1 eq ';');
			$$ref =~ s/^\{//;
			
			# Create the package declaration
			$package = $class->_qualify($package, $caller, 'package');
			my $inject = "{ package $package; ";
			$inject .= "BEGIN { our \$VERSION = '$ver' };" if defined $ver;
			$inject .= "BEGIN { \$INC{${\ perlstring module_notional_filename $package }} = __FILE__ };";
			$inject .= $class->_package_preamble($kw, $package, $empty, %relationships);
			$inject .= "BEGIN { '$class'->_do_imports('$package', $id) };" if @$imports && !$empty;
			$inject .= "'$class'->_at_runtime('$package');";
			$inject .= "}" if $empty;
			
			# Inject it!
			substr($$ref, 0, 0) = $inject;
		}
	}
}

sub _relationships
{
	shift;
	my ($kw) = @_;
	return qw(with using)          if $kw eq q(role);
	return qw(with extends using)  if $kw eq q(class);
	return qw();
}

sub _should_qualify
{
	shift;
	return 1 if $_[0] =~ /^(package|with|extends)$/;
}

sub _qualify
{
	my $class = shift;
	my ($bareword, $caller, $rel) = @_;
	return $1                    if $bareword =~ /^::(.+)$/;
	return $bareword             if $caller eq 'main';
	return $bareword             if $bareword =~ /::/;
	return "$caller\::$bareword" if $class->_should_qualify($rel);
	return $bareword;
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
		method => {
			name                 => 'optional',
			default_arguments    => 1,
			check_argument_count => 1,
			named_parameters     => 1,
			types                => 1,
			reify_type           => $reify,
			attrs                => ':method',
			shift                => '$self',
			invocant             => 1,
		},
	);
	
	if ($kw eq 'class' or $kw eq 'role')
	{
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

sub _package_preamble
{
	my $class = shift;
	my ($kw, $package, $empty, %relationships) = @_;
	
	my @lines = (
		$class->_package_preamble_relationship_using(
			$kw,
			$package,
			$empty,
			$relationships{using}[0],
		),
		$class->_package_preamble_always(
			$kw,
			$package,
			$empty,
		),
	);
	
	for my $key (sort keys %relationships)
	{
		next if $key eq 'using';
		
		my $method = "_package_preamble_relationship_$key";
		push @lines, $class->$method(
			$kw,
			$package,
			$empty,
			$relationships{$key},
		);
	}
	
	join "\n", @lines;
}

sub _package_preamble_always
{
	my $class = shift;
	my ($kw, $package, $empty) = @_;
	
	return if $empty;
	
	return (
		'use Carp qw(confess);',
		"use Function::Parameters $class\->_function_parameters_args(q[$kw], q[$package]);",
		'use Scalar::Util qw(blessed);',
		'use Try::Tiny;',
		'use Types::Standard qw(-types);',
		'use constant { true => !!1, false => !!0 };',
		"no warnings qw(@crud);",
	);
}

sub _package_preamble_relationship_extends
{
	my $class = shift;
	my ($kw, $package, $empty, $classes) = @_;
	
	return unless @$classes;
	return sprintf "extends(%s);", join ",", map perlstring($_), @$classes;
}

sub _package_preamble_relationship_with
{
	my $class = shift;
	my ($kw, $package, $empty, $roles) = @_;
	
	return unless @$roles;
	return sprintf "with(%s);", join ",", map perlstring($_), @$roles;
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
		my $class = shift;
		my ($kw, $package, $empty, $using) = @_;
		(
			($TEMPLATE1{$using//''}{$kw} // croak("Cannot build $kw using $using")),
			($TEMPLATE2{$kw} // ''),
		)
	}
}

sub _do_imports
{
	shift;
	my ($package, $importset) = @_;
	
	my $imports = $IMPORTS[$importset];
	
	for my $import (@$imports)
	{
		my ($module, $params) = @$import;
		use_package_optimistically($module)->import::into(
			$package,
			(ref($params) eq q(HASH) ? %$params : ref($params) eq q(ARRAY) ? @$params : ()),
		);
	}
}

sub _at_runtime
{
	my $class = shift;
	my ($pkg) = @_;
	for my $task (@{ $MooX::Aspartame::AT_RUNTIME })
	{
		my ($code, @args) = @$task;
		eval "package $pkg; \$code->(\@args)";
	}
}

package MooX::Aspartame::MethodModifiers
{
	use Attribute::Handlers;
	
	sub handle
	{
		my ($pkg, $glob, $code, $modifier) = @_;
		my ($subname) = ("${\*$glob}" =~ /(\w+)$/);
		sweep($pkg, $subname);
		my $installer = find_installer($pkg, $subname, $code, $modifier)
			or Carp::croak("No '$modifier' method modifier for package '$pkg'; stopped");
		my @at_runtime = ($installer, $subname, wrap_method($pkg, $subname, $code, $modifier));
		push @{ $MooX::Aspartame::AT_RUNTIME }, \@at_runtime;
	}
	
	# stolen from namespace::sweep,
	# which stole it from namespace::clean.
	sub sweep
	{
		my $package = shift;
		my $ps      = 'Package::Stash'->new($package);
		my @symbols = map {
			my $name = $_ . $_[0];
			my $def = $ps->get_symbol( $name );
			defined($def) ? [$name, $def] : ()
		} '$', '@', '%', '';
		$ps->remove_glob( $_[0] );
		$ps->add_symbol( @$_ ) for @symbols;
	}
	
	sub find_installer
	{
		my ($pkg, undef, undef, $modifier) = @_;
		no strict 'refs';
		\&{$pkg.'::'.lc($modifier)};
	}
	
	sub wrap_method
	{
		my ($pkg, undef, $code, $modifier) = @_;
		return eval qq{
			sub {
				package $pkg;
				local \${^NEXT} = shift(\@_);
				\$code->(\@_);
			}
		} if lc($modifier) eq 'around';
		return $code;
	}
	
	sub UNIVERSAL::Before :ATTR(BEGIN) { goto \&MooX::Aspartame::MethodModifiers::handle; }
	sub UNIVERSAL::After  :ATTR(BEGIN) { goto \&MooX::Aspartame::MethodModifiers::handle; }
	sub UNIVERSAL::Around :ATTR(BEGIN) { goto \&MooX::Aspartame::MethodModifiers::handle; }
};

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

This is something like a lightweight L<MooseX::Declare>. It gives you
three keywords:

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

This provides C<fun> and C<method> keywords.

Within roles and classes, it also provides C<before>, C<after>
and C<around> modifiers. Unlike Moo/Moose, within around modifiers
the coderef being wrapped is I<not> available in C<< $_[0] >>, but
is instead in the magic global variable C<< ${^NEXT} >>.

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

