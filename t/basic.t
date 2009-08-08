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

    # why don't only two backslashes work here?
    rule command {
        \\\  <name=literal>  <options>?  <args>?
    }

    rule options {
        \[  <[option]> ** (,)  \]
    }

    rule args {
        \{  <[element]>*  \}
    }

    rule option {
        [^][\$&%#_{}~^\s,]+
    }

    rule literal {
        [^][\$&%#_{}~^\s]+
    }
}

my $input = do { local $/; <DATA> };
my $ast = $input ~~ LaTeX;
ok($ast, 'matched');

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
