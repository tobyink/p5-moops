use v5.14;
use strict;
use warnings FATAL => 'all';
no warnings qw(void once uninitialized numeric);

package Moops::TraitFor::Keyword::fp;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.027';

use Moo::Role;
use Moops::MethodModifiers ();

around generate_package_setup_methods => sub
{
	my $next = shift;
	my $self = shift;
	return (
		"use Function::Parameters '${\ ref($self) }'->arguments_for_function_parameters(q[${\ $self->package }]);",
	);
};

around generate_package_setup_oo => sub
{
	my $next = shift;
	my $self = shift;
	my @orig = $self->$next(@_);
	s/MooseX::KavorkaInfo/MooseX::FunctionParametersInfo/g for @orig;
	return @orig;
};

sub arguments_for_function_parameters
{
	my $class = shift;
	my ($pkg) = @_;
	
	state $reify = sub {
		state $guard = do { require Type::Utils };
		Type::Utils::dwim_type($_[0], for => $_[1]);
	};
	
	my $keywords = {
		fun => {
			name                 => 'optional',
			runtime              => 0,
			default_arguments    => 1,
			check_argument_count => 1,
			check_argument_types => 1,
			named_parameters     => 1,
			types                => 1,
			reify_type           => $reify,
		},
	};
	
	if ($class->should_support_methods)
	{
		$keywords->{method} = {
			name                 => 'optional',
			runtime              => 0,
			default_arguments    => 1,
			check_argument_count => 1,
			check_argument_types => 1,
			named_parameters     => 1,
			types                => 1,
			reify_type           => $reify,
			attrs                => ':method',
			shift                => '$self',
			invocant             => 1,
		};
		$keywords->{ lc($_) } = {
			name                 => 'required',
			runtime              => 0,
			default_arguments    => 1,
			check_argument_count => 1,
			check_argument_types => 1,
			named_parameters     => 1,
			types                => 1,
			reify_type           => $reify,
			attrs                => ":$_",
			shift                => '$self',
			invocant             => 1,
		} for qw( Before After Around );
	}
	
	return $keywords;
}

1;
