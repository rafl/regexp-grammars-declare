use strict;
use warnings;
use Test::More;

use Regexp::Grammars::Declare;

grammar LaTeX {
    rule TOP {
        <file>
    }

    sub foo { }

    rule file {
        <[element]>*
    }

    sub foo { }

    rule element {
        <command> | <literal>
    }

    sub foo { }

    # why don't only two backslashes work here?
    rule command {
        \\\  <name=literal>  <options>?  <args>?
    }

    sub foo { }

    rule options {
        \[  <[option]> ** (,)  \]
    }

    sub foo { }

    rule args {
        \{  <[element]>*  \}
    }

    sub foo { }

    rule option {
        [^][\$&%#_{}~^\s,]+
    }

    sub foo { }

    rule literal {
        [^][\$&%#_{}~^\s]+
    }

    sub foo { }
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
