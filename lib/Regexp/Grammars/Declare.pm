package Regexp::Grammars::Declare;

use Moose;
use Devel::Declare ();
use B::Hooks::EndOfScope;
use Text::Balanced 'extract_bracketed';
use Sub::Install 'install_sub', 'reinstall_sub';
use aliased 'Regexp::Grammars::Declare::Grammar';
use aliased 'Devel::Declare::Context::Simple', 'DDContext';
use namespace::autoclean;

has ctx => (
    is      => 'ro',
    isa     => DDContext,
    builder => '_build_ctx',
    handles => [qw/init skip_declarator skipspace strip_name shadow inject_if_block get_linestr offset set_linestr strip_proto/],
);

has class => (
    is       => 'ro',
    required => 1,
);

our %Grammar;

sub _build_ctx {
    return DDContext->new;
}

sub import {
    my ($class) = @_;
    my $for = caller;
    $class->setup_for($for);
}

sub _setup_keyword {
    my ($class, $for, $keyword, $parser) = @_;

    Devel::Declare->setup_for($for, {
        $keyword => {
            const => sub {
                my $self = $class->new(class => $for);
                $self->init(@_);
                return $self->${\"parse_$keyword"};
            },
        },
    });

    install_sub({
        code => sub {},
        into => $for,
        as   => $keyword,
    });
}

sub setup_for {
    my ($class, $for) = @_;
    $class->_setup_keyword($for, 'grammar');
}

sub install_grammar_keywods {
    my ($self) = @_;
    for my $keyword (qw/token rule/) {
        $self->_setup_keyword($self->class, $keyword);
    }
}

sub uninstall_grammar_keywords {
    my ($self) = @_;
    # TODO
}

sub scope_injector_call {
    my ($self, $code) = @_;
    $code =~ s/'/\\'/g;
    return qq[BEGIN { ${\ref $self}->inject_scope('${code}') }];
}

sub inject_scope {
    my ($class, $code) = @_;
    on_scope_end {
        my $line = Devel::Declare::get_linestr();
        return unless defined $line;
        my $offset = Devel::Declare::get_linestr_offset();
        substr($line, $offset, 0) = $code;
        Devel::Declare::set_linestr($line);
    };
}

sub got_block {
    my ($self, $buf) = @_;
    return 0 unless defined $buf && length $buf;
    my ($extracted, $remaining, $prefix) = extract_bracketed($buf, '{}');
    return 0 if !defined $extracted || !length $extracted;
    return 0 if defined $prefix && length $prefix;
    return length $remaining;
}

sub slurp_block {
    my ($self) = @_;
    my $buf = '';

    my $linestr = $self->get_linestr;

    confess 'expected block'
        if substr($linestr, $self->offset, 1) ne '{';

    my $remainder;
    while (!($remainder = $self->got_block($buf))) {
        $self->skipspace;
        $linestr = $self->get_linestr;
        $buf .= substr($linestr, $self->offset);
        substr($linestr, $self->offset) = '';
        $self->set_linestr($linestr);
    }

    my $rest = substr($buf, length($buf) - $remainder);
    substr($buf, length($buf) - $remainder) = '';
    substr($linestr, $self->offset, 0) = $rest;
    $self->set_linestr($linestr);

    substr($buf, 0, 1) = '';
    substr($buf, length($buf) - 1, 1) = '';
    return $buf;
}

sub parse_grammar {
    my ($self) = @_;

    $self->skip_declarator;
    $self->skipspace;

    my $name = $self->strip_name;

    $self->skipspace;
    $self->inject_if_block($self->scope_injector_call(';'), 'sub');

    $self->install_grammar_keywods;

    install_sub({
        code => sub { confess 'grammar not compiled yet' },
        as   => $name,
        into => $self->class,
    }) if defined $name && length $name;

    $self->shadow(sub {
        my ($body) = @_;
        local %Grammar;
        $body->();
        $self->uninstall_grammar_keywords;
        my $grammar = Grammar->new(\%Grammar);

        reinstall_sub({
            code => sub { $grammar },
            as   => $name,
            into => $self->class,
        }) if defined $name && length $name;

        return $grammar;
    });
}

sub _parse_regexish {
    my ($self, $type) = @_;

    $self->skip_declarator;
    $self->skipspace;

    my $name = $self->strip_name;
    confess "anonymous ${type}s not allowed"
        if !defined $name || !length $name;

    $self->skipspace;
    my $block = $self->slurp_block;
    $block =~ s/'/\\'/g;
    $block =~ s/^\n+//;

    my $linestr = $self->get_linestr;
    substr($linestr, $self->offset, 0) = qq[(sub { '$block' });];
    $self->set_linestr($linestr);

    $self->shadow(sub {
        my $val = shift->();
        if ($name eq 'TOP') {
            $Grammar{top} = $val;
        }
        else {
            push @{ $Grammar{qq{${type}s}} }, [$name => $val];
        }
        return $val;
    });
}

sub parse_rule {
    my ($self) = @_;
    $self->_parse_regexish('rule');
}

sub parse_token {
    my ($self) = @_;
    $self->_parse_regexish('token');
}

1;
