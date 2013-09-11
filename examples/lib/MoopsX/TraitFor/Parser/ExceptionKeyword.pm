package MoopsX::TraitFor::Parser::ExceptionKeyword;

use Moo::Role;

around keywords => sub {
	my $next = shift;
	my $self = shift;
	return ('exception', $self->$next(@_));
};

around class_for_keyword => sub {
	my $next = shift;
	my $self = shift;
	
	if ($self->keyword eq 'exception') {
		require MoopsX::Keyword::Exception;
		return 'MoopsX::Keyword::Exception';
	}
	
	return $self->$next(@_);
};

1;
