use Moops;

class Scissors;
class Paper;
class Rock;
class Lizard;
class Spock;

class Game {
	use Kavorka qw( multi method );
	multi method play (Paper    $x, Rock     $y) { 1 }
	multi method play (Paper    $x, Spock    $y) { 1 }
	multi method play (Scissors $x, Paper    $y) { 1 }
	multi method play (Scissors $x, Lizard   $y) { 1 }
	multi method play (Rock     $x, Scissors $y) { 1 }
	multi method play (Rock     $x, Lizard   $y) { 1 }
	multi method play (Lizard   $x, Paper    $y) { 1 }
	multi method play (Lizard   $x, Spock    $y) { 1 }
	multi method play (Spock    $x, Rock     $y) { 1 }
	multi method play (Spock    $x, Scissors $y) { 1 }
	multi method play (Any      $x, Any      $y) { 0 }
}

my $game = Game->new;
say $game->play(Paper->new, Rock->new);
say $game->play(Spock->new, Paper->new);
say $game->play(Spock->new, Scissors->new);
