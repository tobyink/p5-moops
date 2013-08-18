package MoopsX::Ception::CodeGenerator::Exception;

use Moo;
extends 'Moops::CodeGenerator::Class';

use Throwable ();

sub BUILD {
	my $self = shift;
	unshift @{ $self->relations->{with} ||= [] }, 'Throwable';
}

1;
