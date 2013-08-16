use v5.14;
use strict;
use warnings FATAL => 'all';
no warnings qw(void once uninitialized numeric);

package Moops::MethodModifiers;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.006';

use Attribute::Handlers;

sub handle
{
	my ($pkg, $glob, $code, $modifier) = @_;
	my ($subname) = ("${\*$glob}" =~ /(\w+)$/);
	sweep($pkg, $subname);
	my $installer = find_installer($pkg, $subname, $code, $modifier)
		or Carp::croak("No '$modifier' method modifier for package '$pkg'; stopped");
	my @at_runtime = ($installer, $subname, wrap_method($pkg, $subname, $code, $modifier));
	push @{ $Moops::AT_RUNTIME }, \@at_runtime;
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

sub UNIVERSAL::Before :ATTR(BEGIN) { goto \&Moops::MethodModifiers::handle; }
sub UNIVERSAL::After  :ATTR(BEGIN) { goto \&Moops::MethodModifiers::handle; }
sub UNIVERSAL::Around :ATTR(BEGIN) { goto \&Moops::MethodModifiers::handle; }

1;
