use v5.14;
use strict;
use warnings FATAL => 'all';
no warnings qw(void once uninitialized numeric);

package Moops::Parser;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.022';

use Moo;
use Module::Runtime qw($module_name_rx);
use namespace::sweep;

has 'keyword'    => (is => 'ro');
has 'ccstash'    => (is => 'ro');
has 'ref'        => (is => 'ro');

# Not set in constructor; set by parse method.
has 'package'        => (is => 'rwp', init_arg => undef);
has 'version'        => (is => 'rwp', init_arg => undef, predicate => 'has_version');
has 'relations'      => (is => 'rwp', init_arg => undef, default => sub { +{} });
has 'version_checks' => (is => 'rwp', init_arg => undef, default => sub { [] });
has 'traits'         => (is => 'rwp', init_arg => undef, default => sub { +{} });
has 'is_empty'       => (is => 'rwp', init_arg => undef, default => sub { 0 });
has 'done'           => (is => 'rwp', init_arg => undef, default => sub { 0 });

has 'class_for_keyword' => (
	is      => 'lazy',
	builder => 1,
	handles => {
		known_relationships  => 'known_relationships',
		qualify_relationship => 'qualify_relationship',
		version_relationship => 'version_relationship',
	},
);

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
	my ($rel) = @_;
	my $pkg = $self->_eat(qr{(?:::)?$module_name_rx});
	return $self->qualify_module_name($pkg, $rel);
}

sub _eat_package_and_version
{
	my $self = shift;
	my ($rel) = @_;
	
	my $pkg = $self->_eat(qr{(?:::)?$module_name_rx});
	$self->_eat_space;
	
	my $ver = $self->_peek_version ? $self->_eat_version : undef;
	
	return (
		$self->qualify_module_name($pkg, $rel),
		$ver,
	);
}

{
	my $v_re = qr{v?[0-9._]+};
	sub _peek_version { shift->_peek($v_re) }
	sub _eat_version  { shift->_eat($v_re) }
}

sub _eat_relations
{
	my $self = shift;
	
	my $RELS = join '|', map quotemeta, $self->known_relationships;
	$RELS = qr/\A($RELS)/sm;
	
	my (%relationships, @vchecks);
	while ($self->_peek($RELS))
	{
		my $rel = $self->_eat($RELS);
		$self->_eat_space;
		
		my $with_version = $self->version_relationship($rel);
		
		my ($pkg, $ver) = $with_version ? $self->_eat_package_and_version($rel) : $self->_eat_package($rel);
		my @modules = $pkg;
		push @vchecks, [$pkg, $ver] if $ver;
		$self->_eat_space;
		while ($self->_peek(qr/\A,/))
		{
			$self->_eat(',');
			$self->_eat_space;
			my ($pkg, $ver) = $with_version ? $self->_eat_package_and_version($rel) : $self->_eat_package($rel);
			push @modules, $pkg;
			push @vchecks, [$pkg, $ver] if $ver;
			$self->_eat_space;
		}
		
		push @{ $relationships{$rel}||=[] }, @modules;
	}
	
	wantarray ? (\%relationships, \@vchecks) : \%relationships;
}

sub _eat_traits
{
	my $self = shift;
	
	my %traits;
	while ($self->_peek(qr/[A-Za-z]\w+/))
	{
		my $trait = $self->_eat(qr/[A-Za-z]\w+/);
		$self->_eat_space;
		
		if ($self->_peek(qr/\(/))
		{
			require Text::Balanced;
			my $code = Text::Balanced::extract_codeblock(${$self->ref}, '()');
			my $ccstash = $self->ccstash;
			# stolen from Attribute::Handlers
			my $evaled = eval("package $ccstash; no warnings; no strict; local \$SIG{__WARN__}=sub{die}; +{ $code }");
			$traits{$trait} = $evaled;
			$self->_eat_space;
		}
		else
		{
			$traits{$trait} = undef;
		}
		
		if ($self->_peek(qr/:/))
		{
			$self->_eat(':');
			$self->_eat_space;
		}
	}
	
	\%traits;
}

sub parse
{
	my $self = shift;
	return if $self->done;
	
	$self->_eat_space;
	
	$self->_set_package(
		$self->_eat_package
	);
	
	$self->_eat_space;
	
	$self->_set_version(
		$self->_eat_version
	) if $self->_peek_version;
	
	$self->_eat_space;
	
	if ($self->known_relationships)
	{
		my ($rels, $vchecks) = $self->_eat_relations;
		$self->_set_relations( $rels );
		$self->_set_version_checks( $vchecks );
	}
	
	$self->_eat_space;
	
	if ($self->_peek(qr/:/))
	{
		$self->_eat(':');
		$self->_eat_space;
		$self->_set_traits($self->_eat_traits);
		$self->_eat_space;
	}
	
	$self->_peek(qr/;/) ? $self->_set_is_empty(1) : $self->_eat('{');
	
	$self->_set_done(1);
}

sub keywords
{
	qw/ class role namespace library /;
}

sub qualify_module_name
{
	my $self = shift;
	my ($bareword, $rel) = @_;
	my $caller = $self->ccstash;
	
	return $1                    if $bareword =~ /^::(.+)$/;
	return $bareword             if $caller eq 'main';
	return $bareword             if $bareword =~ /::/;
	return "$caller\::$bareword" if !defined($rel) || $self->qualify_relationship($rel);
	return $bareword;
}

sub _build_class_for_keyword
{
	my $self = shift;
	my $kw = $self->keyword;
	
	if ($kw eq 'class')
	{
		require Moops::Keyword::Class;
		return 'Moops::Keyword::Class';
	}
	elsif ($kw eq 'role')
	{
		require Moops::Keyword::Role;
		return 'Moops::Keyword::Role';
	}
	elsif ($kw eq 'library')
	{
		require Moops::Keyword::Library;
		return 'Moops::Keyword::Library';
	}
	
	require Moops::Keyword;
	return 'Moops::Keyword';
}

sub keyword_object
{
	my $self = shift;
	my (%attrs) = @_;
	
	my $class = $self->class_for_keyword;
	
	if (my %traits = %{$self->traits || {}})
	{
		require Moo::Role;
		$class = 'Moo::Role'->create_class_with_roles(
			$self->class_for_keyword,
			map("Moops::TraitFor::Keyword::$_", keys %traits),
		);
		
		for my $trait (keys %traits)
		{
			next unless defined $traits{$trait};
			$attrs{sprintf('%s_%s', lc($trait), $_)} = $traits{$trait}{$_}
				for keys %{$traits{$trait}};
		}
	}
	
	$class->new(
		package        => $self->package,
		(version       => $self->version) x!!($self->has_version),
		relations      => $self->relations,
		is_empty       => $self->is_empty,
		keyword        => $self->keyword,
		ccstash        => $self->ccstash,
		version_checks => $self->version_checks,
		%attrs,
	);
}

1;
