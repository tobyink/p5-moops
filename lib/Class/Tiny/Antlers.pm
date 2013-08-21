use strict;
use warnings;

package Class::Tiny::Antlers;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.014';

use Class::Tiny 0.003 ();

sub import
{
	shift;
	my $caller = caller;
	no strict 'refs';
	*{"$caller\::has"}     = sub { unshift @_, $caller; goto \&has };
	*{"$caller\::extends"} = sub { unshift @_, $caller; goto \&extends };
	*{"$caller\::with"}    = sub { unshift @_, $caller; goto \&with };
}

sub croak
{
	require Carp;
	my ($fmt, @values) = @_;
	Carp::croak(sprintf($fmt, @values));
}

sub has
{
	my $caller = shift;
	my ($attr, %spec) = @_;

	if (defined($attr) and ref($attr) eq q(ARRAY))
	{
		has($caller, $_, %spec) for @$attr;
		return;
	}

	if (!defined($attr) or ref($attr) or $attr !~ /^[^\W\d]\w*$/s)
	{
		croak("Invalid accessor name '%s'", $attr);
	}
	
	my $init_arg = exists($spec{init_arg}) ? delete($spec{init_arg}) : \undef;
	my $is       = delete($spec{is}) || 'rw';
	my $isa      = delete($spec{isa});
	my $required = delete($spec{required});
	
	if (keys %spec)
	{
		croak("Unknown options in attribute specification (%s)", join ", ", sort keys %spec);
	}
	
	if ($required and 'Class::Tiny'->can('new') == $caller->can('new'))
	{
		croak("Class::Tiny::new does not support required attributes; please manually override the constructor to enforce required attributes");
	}
	
	if ($isa)
	{
		croak("Class::Tiny does not support type constraints");
	}
	
	if ($init_arg and ref($init_arg) eq 'SCALAR' and not defined $$init_arg)
	{
		# ok
	}
	elsif (!$init_arg or $init_arg ne $attr)
	{
		croak("Class::Tiny does not support init_arg");
	}
	
	if ($is eq 'ro')
	{
		eval "package $caller; sub $attr :method { \$_[0]{'$attr'} }; use Class::Tiny qw($attr);";
	}
	elsif ($is eq 'rwp')
	{
		eval "package $caller; sub $attr :method { \$_[0]{'$attr'} }; sub _set_$attr :method { \$_[0]{'$attr'} = \$_[1] }; use Class::Tiny qw($attr);";
	}
	elsif ($is eq 'rw')
	{
		eval "package $caller; use Class::Tiny qw($attr);";
	}
	else
	{
		croak("Class::Tiny::Antlers does not support $is accessors");
	}
}

sub extends
{
	my $caller = shift;
	my (@parents) = @_;
	
	for my $parent (@parents)
	{
		eval "require $parent";
	}
	
	no strict 'refs';
	@{"$caller\::ISA"} = @parents;
}

sub with
{
	my $caller = shift;
	require Role::Tiny::With;
	goto \&Role::Tiny::With::with;
}

1;


__END__

=pod

=encoding utf-8

=head1 NAME

Class::Tiny::Antlers - Moose-like syntax for Class::Tiny

=head1 SYNOPSIS

   {
      package Point;
      use Class::Tiny;
      use Class::Tiny::Antlers;
      has x => (is => 'ro');
      has y => (is => 'ro');
   }
   
   {
      package Point3D;
      use Class::Tiny;
      use Class::Tiny::Antlers;
      extends 'Point';
      has z => (is => 'ro');
   }

=head1 DESCRIPTION

Class::Tiny::Antlers provides L<Moose>-like C<has>, C<extends> and C<with>
keywords for L<Class::Tiny>. (The C<with> keyword requires L<Role::Tiny>.)

Class::Tiny doesn't support all Moose's attribute options; C<has> should
throw you an error if you try to do something it doesn't support (like
builders, triggers or type constraints).

Class::Tiny::Antlers does however hack in support for C<< is => 'ro' >>
and Moo-style C<< is => 'rwp' >>.

Class::Tiny::Antlers is currently distributed as part of L<Moops>, but
is fairly independent of the rest of it, and may be spun off as a
separate release in the future.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Moops>.

=head1 SEE ALSO

L<Class::Tiny>, L<Moose>, L<Moo>.

L<Moops>.

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
