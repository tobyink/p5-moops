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

around class_for_keyword => sub {
	my $next = shift;
	my $self = shift;
	
	if ($self->keyword eq 'exception') {
		require MoopsX::Ception::Keyword::Exception;
		return 'MoopsX::Ception::Keyword::Exception';
	}
	
	return $self->$next;
};

1;
