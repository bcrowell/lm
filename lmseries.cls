% lmseries.cls
%    This is meant to contain all code used by Light and Matter that
%    isn't shared with Discover Physics and Simple Nature.
%
\pdfminorversion=4 % force pdf 1.4 output; http://tex.stackexchange.com/questions/95973/is-pdftex-1-40-13-outputting-malformed-pdfs

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{lmseries}

\LoadClass[11pt]{book}
% Note that 11 pt does work with pdflatex, even though 11 pt is not one of the sizes
% of CM. I don't know whether it scales up 10 pt or scales down 12 pt, but anyway, it
% works.
%====================== counters =====================================================
\newcounter{dqctr}[subsection]
\newcounter{egctr}[chapter]
\newcounter{scctr}[chapter]
\newcounter{hwctr}[chapter]

\RequirePackage{learn-cmd-syntax,url}
\StartSaveCommands % for learn-cmd-syntax
% \RequirePackage[hidelinks]{hyperref} % doesn't work correctly, see meki, latex notes
\RequirePackage{lmlayout,lmcommon,lmfigs,lmenvironments}

%=====================================================================================
% In DP, we use italics for figref, but in LM that would look too much like an algebra
% symbol, so no italics.
\newcommand{\formatfigref}[1]{#1}

%========================= title page, and the next few pages =========================
\newenvironment{titlepages}[1][1]{%
  \normalsize\normalfont\pagebreak\thispagestyle{empty}%
  \ifthenelse{\equal{#1}{2}}{\cleardoublepage\thispagestyle{empty}}{}%
}{%
  \normalsize\normalfont%
}
%
\newcommand{\titlepagestuff}[9]{%
\zerosizebox{#1}{#2}{#3}%
\zerosizebox{#4}{#5}{#6}%
\zerosizebox{#7}{#8}{#9}%
}
\newcommand{\brieftitle}[1][60mm]{\zerosizebox{#1}{60mm}{\includegraphics{\figprefix\chapdir/figs/title-pretty-big}}}
%... 30 pt Helvetica, or 40 pt bitstream vera sans roman
\newcommand{\fulltitle}[3]{%
\sffamily
\zerosizebox{-13mm}{197mm}{\includegraphics{\figprefix\chapdir/figs/title-page-logo-strip}}\par
\zerosizebox{-1mm}{#1}{\includegraphics{\figprefix\chapdir/figs/title-pretty-big}}\par% 30 pt Helvetica
\zerosizebox{0mm}{#2}{\huge{Benjamin Crowell}}\par
\zerosizebox{0mm}{#3}{\huge{www.lightandmatter.com}}\vfill
}
\newcommand{\copyrightpage}[1]{%
  \zerosizebox{-10mm}{110mm}{
    \noindent\includegraphics[width=28.3mm]{\figprefix\chapdir/figs/logo}\\
    Fullerton, California\\
    www.lightandmatter.com\vspace{10mm}
  }

  \zerosizebox{-10mm}{140mm}{
    \noindent{}copyright #1 Benjamin Crowell\vspace{10mm}
  }

  \zerosizebox{-10mm}{159mm}{
    rev. \today\vspace{10mm}
  }

  \zerosizebox{-10mm}{213mm}{
    \noindent{}\begin{minipage}{100mm}
    \noindent{}\begin{tabular}{p{9mm}p{95mm}}
    \zerosizebox{0mm}{14mm}{\anonymousinlinefig{cc-by-sa}} &
    This book is licensed under the Creative Commons
    Attribution-ShareAlike license, version 3.0, 
    http://creativecommons.org/licenses/by-sa/3.0/,
    except for those photographs and
    drawings of which I am not the author, as listed in the photo credits.
    If you agree to the license, it grants you certain privileges that
    you would not otherwise have, such as the right to copy the book,
    or download the digital version free of charge from
    www.lightandmatter.com.
    \end{tabular}
    \end{minipage}
}

  \vfill
}
% titlesec stuff:
\titleformat{\part}[display]
    {\normalfont\Huge\bfseries\sffamily\raggedright}{}{0mm}
    {\Huge}
\titleformat{\chapter}[display]
    {\normalfont\huge\bfseries\sffamily\raggedright}{Chapter \thechapter}{0mm}
    {\Huge}
\newcommand{\normalsectiontitleformat}{
  \titleformat{\section}
    {\normalfont\Large\bfseries\sffamily\raggedright}{\showsecnum{\thesection}}{0.6em}{}
}
\newcommand{\labsectiontitleformat}{
  \titleformat{\section}
    {\normalfont\Huge\bfseries\sffamily\raggedright}{\showsecnum{\thesection}}{0.6em}{}
}
\normalsectiontitleformat
\titleformat{\subsection}
  {\normalfont\normalsize\bfseries\sffamily\raggedright\protect\sansmath}{\lmserifmath}{0em}{}
%   ... don't show subsection numbers (different from SN); overridden for FAC in fac.tex
\titleformat{\subsubsection}
  {\normalfont\normalsize\slshape\raggedright}{\thesubsubsection}{1em}{}
%-------------------- sections and subsections -------------------------
% (chapter stuff is in lmfigs.cls, since it contains a lot of stuff for figures)
  \newcommand{\mysection}[2][4]{\pagebreak[#1]%
	\section{#2}\myeqnspacing%
        \setcounter{dqctr}{0}% gets done automatically for subsections, but I need to do it explicitly for sections that have no subsections
  }
  \newcommand{\mycalcsection}[2][4]{\pagebreak[#1]%
	\section{$\int$ #2}\myeqnspacing}
  \newcommand{\myoptionalsection}[2][4]{\pagebreak[#1]%
	\section{$\star$ #2}\myeqnspacing}
  \newcommand{\myoptionalcalcsection}[2][4]{\pagebreak[#1]%
	\section{$\int\star$ #2}\myeqnspacing}
  \newcommand{\mysubsection}[2][3]{\pagebreak[#1]\subsection{#2}}
  \newcommand{\myoptionalsubsection}[2][3]{\pagebreak[#1]\subsection{$\star$ #2}}
  \newcommand{\mysubsectionnotoc}[2][3]{\pagebreak[#1]\subsection*{#2}}
  \newcommand{\myssssection}[2][3]{\pagebreak[#1]\noindent\ensuremath{\triangleright}\ #2}
%-------------------- data table -------------------------
\newcommand{\formatdatatabletitle}[1]{\huge{\bfseries{\sffamily{#1}}}\normalsize\normalfont}
\newcommand{\formatdatatableheader}[1]{\LARGE{\bfseries{\sffamily{#1}}}\normalsize\normalfont}
\newcommand{\twoblankpages}{\hbox{}\newpage\hbox{}\newpage}% assumes one-column layout
\newenvironment{datatablepage}{%
  \onecolumn\clearpage\lmserifmath
  % header
  \twocolumn[\begin{center}\formatdatatabletitle{Useful Data}\end{center}]\vspace{8mm}\footnotesize
}{%
  \normalsize
}
\newcommand{\datatableheader}[1]{%
  \begin{shaded}\begin{center}\formatdatatableheader{#1}\end{center}\end{shaded}%
}
\newenvironment{datatable}[1]{%
  \datatableheader{#1}
}{}
\newcommand{\datatablenote}[1]{{\scriptsize #1}}
\newcommand{\datatablecolhdr}[1]{\textbf{#1}}
%------------------------------------------------------------------------------------------

\StopSaveCommands % for learn-cmd-syntax
\WriteSaveCommands  % for learn-cmd-syntax
