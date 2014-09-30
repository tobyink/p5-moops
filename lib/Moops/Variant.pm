package Moops::Variant;

use Moo::Role;
use Package::Variant ();
use Parse::Keyword {};
use Parse::KeywordX;

has moops_parser => (
	is => 'ro',
	required => 1,
	handles => [qw/ known_relationships qualify_relationship version_relationship /],
);

around multi_parse => sub
{
	my $next  = shift;
	my $class = shift;
	my (undef, $keyword) = @_;
	
	my $parser_class = $^H{'Moops/parser_class'};
	if ($parser_class and grep $_ eq $keyword, $parser_class->keywords)
	{
		my ($parse_method, undef, @args) = @_;
		return $class->$parse_method(
			@args,
			multi_type => $class,
			moops_parser => $parser_class->new(
				keyword => $keyword,
				ccstash => Parse::Keyword::compiling_package(),
			),
		);
	}
	
	$class->$next(@_);
};

sub default_attributes { return; }
sub default_invocant   { return; }
sub forward_declare    { return; }
sub invocation_style   { 'fun'; }

after parse_subname => sub {
	my $self = shift;
	$self->moops_parser->_set_package($self->qualified_name);
};

around inject_prelude => sub {
	my $next = shift;
	my $self = shift;
	
	my $meta = $self->moops_parser->keyword_object;
	$meta->{package} = $self->qualified_name;  # ARGH
	
	Moo::Role::->apply_roles_to_object($meta, 'Moops::Variant::_LineHacker');
	
	my $inject = join "" => (
		$meta->generate_code,
		'local our ($variable,$variant)=(shift,shift);',
		$self->$next(@_),
	);
	
	return $inject;
};

sub install_sub
{
	no strict 'refs';
	
	my $self = shift;
	my $name = $self->qualified_name;
	my $code = $self->body;
	
	*{ $name .  "::make_variant" } = $code;
	*{ $name } = sub { Package::Variant::->build_variant_of( $name, @_ ) };
	
	$code;
}

after parse_traits => sub
{
	my $self = shift;
	lex_read_space;
	
	my $moops = $self->moops_parser;
	my $rels  = join "|", map quotemeta, $self->known_relationships;
	
	while (lex_peek(40) =~ m{ \A ($rels) \s }xsm)
	{
		my $kw = $1;
		my $with_version = $self->version_relationship($kw);
		
		my @names;
		lex_read(length($kw));
		lex_read_space;
		my ($name, undef, $args) = parse_trait;
		$name = $moops->qualify_module_name($name, $kw);
		lex_read_space;
		push @names, $name;
		
		if ($with_version and lex_peek(40) =~ m{ \A (v?[0-9._]+) }xsm)
		{
			my $ver = $1;
			lex_read(length $ver);
			lex_read_space;
			push @{ $self->moops_parser->version_checks }, [ $name, $ver ];
		}
		
		while (lex_peek(1) eq ',')
		{
			my ($name, undef, $args) = parse_trait;
			$name = $moops->qualify_module_name($name, $kw);
			lex_read_space;
			push @names, $name;
			
			if ($with_version and lex_peek(40) =~ m{ \A (v?[0-9._]+) }xsm)
			{
				my $ver = $1;
				lex_read(length $ver);
				lex_read_space;
				push @{ $self->moops_parser->version_checks }, [ $name, $ver ];
			}
		}
		
		push @{ $moops->relations->{$kw} }, @names;
		
		$moops->keyword_object->check_prerequisites;
	}
};

{
	package #
		Moops::Variant::_LineHacker;
	use Moo::Role;
	around generate_package_setup => sub
	{
		my $next = shift;
		my $self = shift;
		
		my (@mods, @subs);
		my @got = map {
			
			if (/^use (Moo|Moo::Role); use MooX::late;/) {
				push @mods, $1;
				push @subs, qw/ has extends with before after around /;
				();
			}
			elsif (/^use (Moose|Moose::Role|Mouse|Mouse::Role);(.*)/) {
				push @mods, $1;
				push @subs, qw/ has extends with before after around super inner augment override /;
				$2;
			}
			elsif (/^use Kavorka/) {
				my @args = $self->arguments_for_kavorka;
				"use Kavorka -traits => [qw/Moops::Variant::_SubHacker/], qw(@args);";
			}
			else {
				$_;
			}
			
		} $self->$next(@_);
		
		require Data::Dumper;
		local $Data::Dumper::Terse  = 1;
		local $Data::Dumper::Indent = 0;
		(
			sprintf(
				'use Package::Variant importing => %s, subs => %s;',
				Data::Dumper::Dumper(\@mods),
				Data::Dumper::Dumper(\@subs),
			),
			@got,
		);
	};
}

{
	package #
		Moops::Variant::_SubHacker;
	use Moo::Role;
	
	our $_anon;
	BEGIN { $_anon = 1 };
	around is_anonymous => sub { $_anon };
	
	around install_sub => sub {
		my $next = shift;
		my $self = shift;
		
		my $variant = do {
			no strict qw(refs);
			${ $self->package . "::variant" };
		};
		
		my $orig_pkg  = $self->package;
		my $orig_qn   = $self->qualified_name;
		my $orig_body = $self->body;
		
		$self->{package} = $variant;
		$self->_set_qualified_name($variant . "::" . $self->declared_name);
		$self->{body} = do {
			my $level = 0;
			++$level until caller($level) eq $orig_pkg;
			my $pad = PadWalker::peek_my($level+1);
			sub { $self->_poke_pads($pad); goto $orig_body };
		};
		
		local $_anon = 0;
		my $r = $self->$next(@_);
		
		$self->{package} = $orig_pkg;
		$self->_set_qualified_name($orig_qn);
		$self->{body} = $orig_body;
		
		$r;
	};
}

1;