use strict;
use warnings;
use Test::More;

use Regexp::Grammars::Declare;

grammar LaTeX {
    rule TOP {
        <file>
    }

    rule file {
        <[element]>*
    }

    rule element {
        <command> | <literal>
    }

    rule command {
        \\ <name=literal>  <options>?  <args>?
    }

    rule options {
        \[  <[option]> ** (,)  \]
    }

    rule args {
        \{  <[element]>*  \}
    }

    rule literal {
        [^][\$&%#_{}~^\s]+
    }
}

sub LaTeX () {}

my $input = do { local $/; <DATA> };
my $ast = $input ~~ LaTeX;
ok($ast, 'matched');

diag explain $ast;

done_testing;

__DATA__
\documentclass[a4paper,11pt]{article}
\usepackage{latexsym}
\author{D. Conway}
\title{Parsing \LaTeX{}}
\begin{document}
\maketitle
\tableofcontents
\section{Description}
...is easy \footnote{But not \emph{necessarily} simple}.
\end{document}
