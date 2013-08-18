package MoopsX::Ception::Parser;

use Moo;
extends 'Moops::Parser';

around keywords => sub {
	my $next = shift;
	my $class = shift;
	
	my @kw = $class->$next;
	push @kw, 'exception';
	return @kw;
};

around relationships => sub {
	my $next = shift;
	my $self = shift;
	
	return qw(extends with using)
		if $self->keyword eq 'exception';
	
	return $self->$next;
};

around class_for_code_generator => sub {
	my $next = shift;
	my $self = shift;
	
	if ($self->keyword eq 'exception') {
		require MoopsX::Ception::CodeGenerator::Exception;
		return 'MoopsX::Ception::CodeGenerator::Exception';
	}
	
	return $self->$next;
};

1;
