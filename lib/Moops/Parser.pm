use v5.14;
use strict;
use warnings FATAL => 'all';
no warnings qw(void once uninitialized numeric);

package Moops::Parser;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.007';

use Moo;
use Module::Runtime qw($module_name_rx);
use namespace::sweep;

has 'keyword'    => (is => 'ro');
has 'ccstash'    => (is => 'ro');
has 'ref'        => (is => 'ro');

# Not set in constructor; set by parse method.
has 'package'    => (is => 'rwp', init_arg => undef);
has 'version'    => (is => 'rwp', init_arg => undef, predicate => 'has_version');
has 'relations'  => (is => 'rwp', init_arg => undef, default => sub { +{} });
has 'is_empty'   => (is => 'rwp', init_arg => undef, default => sub { 0 });
has 'done'       => (is => 'rwp', init_arg => undef, default => sub { 0 });

sub _eat
{
	my $self = shift;
	my ($bite) = @_;
	my $ref = $self->ref;
	
	if (ref($bite) and $$ref =~ /\A($bite)/sm)
	{
		my $r = $1;
		substr($$ref, 0, length($r)) = '';
		return $r;
	}
	elsif (!ref($bite))
	{
		substr($$ref, 0, length($bite)) eq $bite
			or Carp::croak("Expected $bite; got $$ref");
		substr($$ref, 0, length($bite)) = '';
		return $bite;
	}
	
	Carp::croak("Expected $bite; got $$ref");
}

sub _eat_space
{
	my $self = shift;
	my $ref = $self->ref;
	
	my $X;
	while (
		($$ref =~ m{\A( \s+ )}x and $X = 1)
		or ($$ref =~ m{\A\#} and $X = 2)
	) {
		$X==2
			? $self->_eat(qr{\A\#.+?\n}sm)
			: $self->_eat($1);
	}
	return;
}

sub _peek
{
	my $self = shift;
	my $re   = $_[0];
	my $ref  = $self->ref;
	
	return scalar($$ref =~ m{\A$re});
}

sub _eat_package
{
	my $self = shift;
	my $pkg  = $self->_eat(qr{(?:::)?$module_name_rx});
	return $self->qualify_module_name($pkg, @_);
}

sub _eat_relations
{
	my $self = shift;
	
	my $RELS = join '|', map quotemeta, $self->relationships;
	$RELS = qr/\A($RELS)/sm;
	
	my %relationships;
	while ($self->_peek($RELS))
	{
		my $rel = $self->_eat($RELS);
		$self->_eat_space;
		
		my @modules = $self->_eat_package($rel);
		$self->_eat_space;
		while ($self->_peek(qr/\A,/))
		{
			$self->_eat(',');
			$self->_eat_space;
			push @modules, $self->_eat_package($rel);
			$self->_eat_space;
		}
		
		push @{ $relationships{$rel}||=[] }, @modules;
	}
	
	return \%relationships
}

sub parse
{
	my $self = shift;
	return if $self->done;
	
	$self->_eat_space;
	
	$self->_set_package(
		$self->_eat_package('package')
	);
	
	$self->_eat_space;
	
	$self->_set_version(
		$self->_eat(qr{v?[0-9._]+})
	) if $self->_peek(qr{v?[0-9._]+});
	
	$self->_eat_space;
	
	$self->_set_relations(
		$self->_eat_relations
	) if $self->relationships;
	
	$self->_eat_space;
	
	$self->_peek(qr/\A;/) ? $self->_set_is_empty(1) : $self->_eat('{');
	
	$self->_set_done(1);
}

sub keywords
{
	qw/ class role namespace /;
}

sub relationships
{
	my $self = shift;
	my $kw   = $self->keyword;
	return qw(with using)          if $kw eq q(role);
	return qw(with extends using)  if $kw eq q(class);
	return qw();
}

sub module_name_should_be_qualified
{
	shift;
	return 1 if $_[0] =~ /^(package|with|extends)$/;
}

sub qualify_module_name
{
	my $self = shift;
	my ($bareword, $rel) = @_;
	my $caller = $self->ccstash;
	
	return $1                    if $bareword =~ /^::(.+)$/;
	return $bareword             if $caller eq 'main';
	return $bareword             if $bareword =~ /::/;
	return "$caller\::$bareword" if $self->module_name_should_be_qualified($rel);
	return $bareword;
}

sub class_for_code_generator
{
	my $self = shift;
	my $kw = $self->keyword;
	
	if ($kw eq 'class') {
		require Moops::CodeGenerator::Class;
		return 'Moops::CodeGenerator::Class';
	}
	elsif ($kw eq 'role') {
		require Moops::CodeGenerator::Role;
		return 'Moops::CodeGenerator::Role';
	}
	else {
		require Moops::CodeGenerator;
		return 'Moops::CodeGenerator';
	}
}

sub code_generator
{
	my $self = shift;
	my ($imports) = @_;
	
	$self->class_for_code_generator->new(
		package   => $self->package,
		(version  => $self->version) x!!($self->has_version),
		relations => $self->relations,
		is_empty  => $self->is_empty,
		keyword   => $self->keyword,
		ccstash   => $self->ccstash,
		(imports  => $imports) x!!(defined $imports),
	);
}

1;
