package MoopsX::Keyword::Exception;

use Moo;
extends 'Moops::Keyword::Class';

use Throwable ();

sub BUILD {
	my $self = shift;
	unshift @{ $self->relations->{with} ||= [] }, 'Throwable';
}

sub known_relationships {
	return qw(extends with using);
}

1;
