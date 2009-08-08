package Regexp::Grammars::Declare::Grammar;

use Moose;
use MooseX::Types::Structured qw/Tuple/;
use MooseX::Types::Moose qw/HashRef ArrayRef Str RegexpRef/;
use namespace::clean -except => 'meta';

use overload '~~' => 'match';

has top => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has rules => (
    is       => 'ro',
    isa      => ArrayRef[Tuple[Str, Str]],
);

has tokens => (
    is  => 'ro',
    isa => ArrayRef[Tuple[Str, Str]],
);

has grammar => (
    is      => 'ro',
    isa     => RegexpRef,
    lazy    => 1,
    builder => '_build_grammar',
);

sub _build_grammar {
    my ($self) = @_;
    use re 'eval';
    use Regexp::Grammars;

    my $grammar = $self->top . "\n\n";

    for my $rule (@{ $self->rules || [] }) {
        $grammar .= qq[<rule: ${\$rule->[0]}>\n];
        $grammar .= qq[  ${\$rule->[1]}\n\n];
    }

    for my $token (@{ $self->tokens || [] }) {
        $grammar .= qq[<token: ${\$token->[0]}>\n];
        $grammar .= qq[  ${\$token->[1]}\n\n];
    }

    return qr{ $grammar }xms
}

sub match {
    my ($self, $input) = @_;
    return unless $input =~ $self->grammar;
    return \%/;
}

1;
