#!/usr/bin/env perl
use Moops;
use Carp 'verbose';

class myApp  {
	use Moo;
	use MooX::Options;

	option 'show_this_file' => (
		is       => 'ro',
		format   => 's',
		required => 1,
		doc      => 'the file to display'
	);

	method BUILD {
		open( my $fh, "<", $self->show_this_file ) or die  "cannot open < $self->show_this_file: $!";
		while (<$fh>) {
			print $_;
		}
	}
}

#main has to come after myApp
class main {
	my $opt = myApp->new_with_options;
}
