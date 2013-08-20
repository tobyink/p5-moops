use strict;
use warnings;

package Class::Tiny::Antlers;

use base 'Exporter';
our @EXPORT = qw( has extends with );

use Class::Tiny 0.003 ();

sub croak
{
	require Carp;
	my ($fmt, @values) = @_;
	Carp::croak(sprintf($fmt, @values));
}

sub has
{
	my ($attr, %spec) = @_;
	my $caller = caller;
	
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
	my (@parents) = @_;
	my $caller = caller;
	
	for my $parent (@parents)
	{
		eval "require $parent";
	}
	
	no strict 'refs';
	@{"$caller\::ISA"} = @parents;
}

sub with
{
	require Role::Tiny::With;
	goto \&Role::Tiny::With::with;
}

1;
