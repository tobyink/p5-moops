use 5.008;
use strict;
use warnings;

use Moose ();
use Kavorka ();
use Kavorka::Signature ();
use Sub::Identify ();

{
	package MooseX::KavorkaInfo::DummyInfo;
	use Moo;
	with 'Kavorka::Sub';
}

{
	package MooseX::KavorkaInfo;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.024';
	
	sub _unwrap
	{
		my $coderef = shift;
		$MooseX::FunctionParametersInfo::WRAPPERS{"$coderef"} || $coderef;
	}
	
	sub import
	{
		my $meta = Class::MOP::class_of(scalar caller);
		Moose::Util::MetaRole::apply_metaroles(
			for             => $meta,
			role_metaroles  => {
				method          => ['MooseX::KavorkaInfo::Trait::Method'],
			},
			class_metaroles => {
				method          => ['MooseX::KavorkaInfo::Trait::Method'],
				wrapped_method  => ['MooseX::KavorkaInfo::Trait::WrappedMethod'],
			},
		);
	}
}

{
	package MooseX::KavorkaInfo::Trait::Method;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.024';
	
	use Moose::Role;
	
	has _info => (
		is        => 'ro',
		lazy      => 1,
		builder   => '_build_info',
		handles   => {
			declaration_keyword  => 'keyword',
		},
	);
	
	sub _build_info
	{
		my $self = shift;
		Kavorka->info(
			MooseX::KavorkaInfo::_unwrap($self->body)
		) or MooseX::KavorkaInfo::DummyInfo->new(
			keyword         => 'sub',
			qualified_name  => Sub::Identify::sub_fullname( $self->body ),
			body            => $self->body,
			signature       => 'Kavorka::Signature'->new(params => [], yadayada => 1),
		);
	}
	
	sub slurpy_parameter {
		shift->_info->signature->slurpy_param;
	}
	
	sub invocant_parameters {
		shift->_info->signature->invocants;
	}
	
	sub named_parameters {
		shift->_info->signature->named_params;
	}
	
	sub positional_parameters {
		shift->_info->signature->positional_params;
	}
}

{
	package MooseX::KavorkaInfo::Trait::WrappedMethod;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.024';
	
	use Moose::Role;
	with 'MooseX::KavorkaInfo::Trait::Method';
	
	around _build_info => sub
	{
		my $orig = shift;
		my $self = shift;
		Kavorka->info(
			MooseX::KavorkaInfo::_unwrap($self->get_original_method->body)
		) or MooseX::KavorkaInfo::DummyInfo->new(
			keyword         => 'sub',
			qualified_name  => Sub::Identify::sub_fullname( $self->get_original_method->body ),
			body            => $self->get_original_method->body,
			signature       => 'Kavorka::Signature'->new(params => [], yadayada => 1),
		);
	};
}

1;
