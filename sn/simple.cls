% notes on wrapfig:
%   wrapfig: for 2 figs in a row, both need to be in same wrapfig
%   wrapfig doesn't work in a theorem environment, so can't implement dqs and egs as thms
%	do wrapfig just before first line of a para
%	I thought it was messing up (positioning too far down) if I used it near a sectioning
%		command, but that doesn't seem to be the case. Sometimes works if you put it right
%		above the sectioning command. Other times when I thought it was a problem with the
%		sectioning command, changing the sectioning command to a styling command didn't help.
%
% example of how to do explanatory text in square brackets to the right of an equation:
%    \begin{multline*}
%	    v_t	=  \omega r   \qquad . \hfill
%	    \shoveright{\text{[tangential velocity of a point at a}}\\
%	     \text{distance $r$ from the axis of rotation]}
%    \end{multline*}
%
% Summary of my sectioning:
%   \mychapter{}, all words with initial caps in title
%   \mysection{}, all words with initial caps  in title; first section in a chapter needs \mysection[0]{}
%   \mysubsection[x]{}, only first word in title capitalized
%   \subsubsection{}, only first in title word capitalized
%
% Notes about design:
%	Subsubsections are not numbered.
%	Only capitalize first word of example titles, subsections.
%	Panels within figures are numbered 1, 2, etc, in 9-point sans.
%	Figures are numbered within sections. (This could result in high letters,
%		but doing subsections leads to incongruous starting over from "a.")
%	All figures have to have captions, since otherwise "c/" looks bare.
%		Where L&M had a series of panels (a), (b), ..., SN has
%		a single letter, but a series of panels 1, 2, etc.
%		Refer to panels as a/1, etc. Panels without captions have (1), ... inside the figure.
%	Text within figures is 10-point Helvetica, except labels 1, 2, etc. All text within figures
%		is upright, even math variables.
%	Punctuation after displayed equations: \qquad in between.
%	Subscripts are italic, since this is what LaTeX makes it easy for me to do.
%	Equation numbers, when used, go on the left, to allow room for notes on the
%		right. Equation numbers are in square brackets,
%		numbered within sections.
%	Problem with equation numbers in examples: not indented, and not in sans.
%	page breaks:
%		mysection makes a pagebreak by default, but can give it an optional parameter
%			to make it less likely to happen.
%		subsection environment makes a pagebreak[3] by default, which usually doesn't result
%			in a pagebreak, but can use optional argument 4 to force it
%		Introducing page breaks always seems to make equations get spaced out a whole
%			bunch, which looks stupid. This seems to happen even if I sprinkle
%			\myeqnspacing all over the place. The solution is to precede the page
%			break with a \vfill.
%	Differentials and vectors are upright. Can do bold vectors with \boldmath outside of math mode,
%	or \mathbf or \boldsymbol in math mode.
%   In example title, first letter of first word is capitalized.
%	When an example has more than one part, number them (1), (2),... 
%
% Figures mostly in Adobe Illustrator 6 EPS. In some cases, I've saved them as
% Illustrator 1 EPS to save space; however, it isn't possible to do this with
% figures that have text in them, because, at least on my MacOS 9/X system,
% Illustrator gets confused about the fonts. (Also, named colors are lost
% in Illustrator 1 EPS.)
%
% I've activated pdflatex's margin kerning feature. For the fonts used in this
% book, I decided that the margins appeared straightest when I modified 
% protcode.tex to use half the amount of margin kerning that was supplied by
% default. (One expects this to be completely dependent on the font and size.)

\pdfminorversion=4 % force pdf 1.4 output; http://tex.stackexchange.com/questions/95973/is-pdftex-1-40-13-outputting-malformed-pdfs

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{simple}

\LoadClass[11pt]{book}
% Note that 11 pt does work with pdflatex, even though 11 pt is not one of the sizes
% of CM. I don't know whether it scales up 10 pt or scales down 12 pt, but anyway, it
% works.

%\usepackage[french,english]{babel}
% ... if using this, need to install ubuntu package texlive-lang-french , see https://tex.stackexchange.com/a/139707/6853
%     This is also in lmcommon.sty.

\RequirePackage{makeidx,wrapfig,fancyhdr,calc,titlesec,titletoc,amssymb,moreverb,ifthen,framed,alphalph,
                cancel,learn-cmd-syntax,url,xstring,comment,navigator,dutchcal,multirow,mathrsfs}
% dutchcal is for lowercase mathcal, used in SN 4 for \fmat
%   https://tex.stackexchange.com/questions/231322/how-to-get-the-lowercase-calligraphic-symbols
\RequirePackage{color}%see pdftex mailing list, 2004 May 22-23
%====================== counters =====================================================
\newcounter{dqctr}[subsection]
\newcounter{egctr}[chapter]
\newcounter{scctr}[chapter]
\newcounter{hwctr}[chapter]

\StartSaveCommands % for learn-cmd-syntax

\RequirePackage{lmlanguage,lmlayout,lmfigs,lmenvironments,lmmath}


\renewcommand{\sfdefault}{phv}
     % ... helvetica for sans serif; this has to come before sansmath.sty
\RequirePackage[EULERGREEK]{sansmath}
     % ... sansmath.sty by Donald Arseneau, to be released ca. 3/2002.
     % The EULERGREEK option is necessary with Helvetica, because otherwise
     % there is no uppercase Greek. He actually doesn't recommend using sansmath.sty
     % with Helvetica, since some of the symbols match the letters poorly, but
     % I had hundreds of preexisting figures with Helvetica in them.
\RequirePackage[leqno]{amsmath}
\RequirePackage[absolute]{textpos}% ---- http://nxg.me.uk/dist/textpos/
% The following line is for margin kerning. There is more stuff
% relating to margin kerning after the begin{document}, and that's
% where to go if I want to turn it off.
\newboolean{wantmarginkerning}
\setboolean{wantmarginkerning}{true}
\newcommand{\inputprotcode}{\ifthenelse{\boolean{wantmarginkerning}}{\input protcode.tex}{}}

\definecolor{shadecolor}{gray}{.85} % for framed.sty

%=====================================================================================
% In DP, we use italics for figref, but in LM that would look too much like an algebra
% symbol, so no italics.
\newcommand{\formatfigref}[1]{#1}


%========================= sans serif math stuff =========================
% sansmath.sty takes care of it. The following is just to get back to normal
% math mode:
\newcommand{\lmserifmath}{\mathversion{normal}\everymath{}\everydisplay{}}
%========================= design =========================
\definecolor{subsecnumgray}{gray}{.55}
\newcommand{\showsubsecnum}[1]{\color{subsecnumgray}#1} % <----------- caused mysterious errors in Acrobat, starting April 2004 -- why????
%
% titlesec stuff:
\titleformat{\part}[display]
  {\normalfont\huge\bfseries\sffamily}{Part \thepart}{0mm}{\Huge}
\titleformat{\chapter}[display]
  {\normalfont\huge\bfseries\sffamily}{Chapter \thechapter}{0mm}{\Huge}
\titleformat{\section}
  {\normalfont\Large\bfseries\sffamily}{\showsubsecnum{\thesection}}{0.6em}{}
\titleformat{\subsection}
  {\normalfont\normalsize\bfseries\sffamily}{\showsubsecnum{\thesubsection}}{0.6em}{}
%   ... show subsection numbers (different from LM)
\titleformat{\subsubsection}
  {\normalfont\normalsize\slshape}{\thesubsubsection}{1em}{}

\titlespacing*{\chapter}{0mm}{4mm}{6mm}
\titlespacing*{\chapter}{0mm}{4mm}{6mm}
\titlespacing*{\section}{0mm}{4mm}{0mm}
\titlespacing{\subsection}{0mm}{1mm}{-0.5mm}
\titlespacing{\subsubsection}{0mm}{1mm}{-0.5mm}

\newcommand{\formatlikechapter}[1]{\huge{\bfseries{\sffamily{#1}}}\normalsize\normalfont}
\newcommand{\formatlikesection}[1]{\Large{\bfseries{\sffamily{#1}}}\normalsize\normalfont}
\newcommand{\formatlikesubsection}[1]{\bfseries{\sffamily{#1}}\normalsize\normalfont}
\newcommand{\formatlikesubsubsection}[1]{\textsl{#1}\normalsize\normalfont}

%Summary appendix:
\newcommand{\summarych}[2]{\noindent\formatlikesection{Chapter \ref{#1}, #2, page \pageref{#1}}\label{summary#1}\\}
\newcommand{\sumem}[1]{\emph{#1}}

\newcommand{\hwanssection}[1]{\vspace{4mm}\noindent\formatlikesection{#1}}

\newcommand{\kludgyblankfooter}{\thispagestyle{plain}}
\newcommand{\hwsolnhdr}[1]{\kludgyblankfooter\noindent\textbf{Page \pageref{hw:#1}, problem \ref{hw:#1}:}\label{soln:#1}\ }
\newcommand{\hwanshdr}[1]{\kludgyblankfooter\noindent\textbf{Page \pageref{hw:#1}, problem \ref{hw:#1}:}\ \label{hwans:#1}}
\newcommand{\scanshdr}[1]{\kludgyblankfooter\noindent\textbf{Page \pageref{sc:#1}:}\ \label{scans:#1}}
\newcommand{\hinthdr}[1]{\kludgyblankfooter\noindent\textbf{Page \pageref{hw:#1}, problem \ref{hw:#1}:}\ \label{hwhint:#1}}

%-------------------- fancyhdr -------------------
\newcommand{\yesiwantarabic}{\renewcommand{\thepage}{\arabic{page}}}
\renewcommand{\headrulewidth}{0mm}
\renewcommand{\footrulewidth}{0mm}
%\setlength{\headrulewidth}{0mm}
\newcommand{\printthesection}{Section\ \thesection} % for titlesec, hw environment
% LaTeX companion, p. 96
% Force headings outward, so they're not confined to text column:
  \setlength{\headwidth}{\textwidth}
  \addtolength{\headwidth}{\marginfigoverhang}
\newlength{\myfooterspace}
\setlength{\myfooterspace}{5mm}
\newlength{\myfooterspacep}
\setlength{\myfooterspacep}{19mm}
\pagestyle{fancy}
\renewcommand{\chaptermark}[1]%
  {\markboth{\textsf{Chapter\ \thechapter\hspace{\myfooterspace}#1}}{}}
\renewcommand{\sectionmark}[1]%
  {\markright{\textsf{\printthesection\hspace{\myfooterspace}#1}}{}}
%\newcommand{\myheadertext}{\textsf{PRELIMINARY VERSION}}
\newcommand{\myheadertext}{}
\lhead[\myheadertext]{}
\chead[]{}
\rhead[]{\myheadertext}
\lfoot[\textbf{\textsf{\thepage}} \hspace{\myfooterspacep} \nouppercase{\textsf{\leftmark}}]{}
\cfoot[]{}
\rfoot[]{\nouppercase{\textsf{\rightmark}} \hspace{\myfooterspacep} \textbf{\textsf{\thepage}}}
\fancypagestyle{plain}{%
  \fancyfoot{} %
  %\fancyfoot[R]{\textbf{\textsf{\thepage}}}%
}
%-------------------- epigraph commands -------------------
\newcommand{\epigraphlong}[2]{
  \noindent{}#1\par
  \noindent{}\myindented{10mm}{\textit{#2}}
}

\newcommand{\epigraph}[2]{
  #1 \hspace*{\fill}\nolinebreak[1]\hspace*{\fill}\textit{#2}
}
%...based on an example on p. 443 of LaTeX Companion
\newcommand{\mysection}[2][4]{\pagebreak[#1]\zapcounters\section{#2}\myeqnspacing\normalcaptions}
\newcommand{\myoptionalsection}[2][4]{\pagebreak[#1]\section{$\star$ #2}\myeqnspacing}
\newcommand{\mysubsection}[2][4]{\pagebreak[#1]\subsection{#2}}
\newcommand{\myoptionalsubsection}[2][3]{\pagebreak[#1]\subsection{$\star$ #2}}
\newcommand{\myssssection}[2][3]{\pagebreak[#1]\noindent\ensuremath{\triangleright}\ #2}
%-------------------- homework remark -------------------
\newcommand{\hwremark}[1]{\par\noindent\footnotesize{\textit{Remark:\/} #1}}
%-------------------- photo credit command -------------------
\newcommand{\photocredit}[1]{\footnotesize{(\textit{#1})}}
%-------------------- theorem header -------------------
\newcommand{\mythmhdr}[1]{\noindent\textbf{#1:}}

%-------------------- counters -------------------
\newcounter{figctr}[section] % for my roll-your-own captions
\newcounter{appendixctr}
\renewcommand{\thefigctr}{\alphalph{\value{figctr}}}
%-------------------- equation numbering -------------------
\numberwithin{equation}{section}
% Equation numbers have square brackets:
%   Original code from amsmath.sty:
%		\def\tagform@#1{\maketag@@@{(\ignorespaces#1\unskip\@@italiccorr)}}
%   Change it as follows:
		\renewcommand{\tagform@}[1]{\maketag@@@{[\ignorespaces#1\unskip\@@italiccorr]}}
%	Use \eqref to refer to an equation.
%\renewcommand{\theequation}{\ensuremath{\fnsymbol{equation}}} % used to use symbols...
\renewcommand{\theequation}{\ensuremath{\arabic{equation}}} % ... now using numbers
%-------------------- end-of-chapter boilerplate -------------------
\newcommand{\backofchapterboilerplate}[1]{%
	\par\noindent\emph{This chapter is summarized on page \pageref{summarych:#1}. Notation and
	terminology are tabulated on pages \pageref{notationcompared}-\pageref{notationtable}.}\par
}
%---------------- dqs
\newcommand{\dqheaderformat}[1]{\pagebreak[1]\noindent\formatlikesubsection{#1}\nopagebreak\par}
\newcommand{\startdq}{\dqheaderformat{Discussion Question}}
\newcommand{\startdqs}{\dqheaderformat{Discussion Questions}}
\newcommand{\startdqswithintro}[1]%
  {\pagebreak[1]\noindent\formatlikesubsection{Discussion Questions}\nopagebreak\noindent{\small\sffamily\nopagebreak\\*\noindent #1}}
\newenvironment{dq}{%
  \refstepcounter{dqctr}\noindent\small\sffamily\textbf{\thedqctr}\myeqnspacing\protect\sansmath%
  \setlength{\parindent}{0mm}%undone by normalparafmt
}%
{%
  \normalparafmt
  \lmserifmath\par\myeqnspacing
}
\renewcommand{\thedqctr}{\Alph{dqctr}}
%-------------------- hw section & hw problem environments-------------------
\newcommand{\hwdifficulty}{0}
% ... This needs to be a global variable because I only display the symbol in  \end{hw},
%     which doesn't have access to #1.
\newsavebox{\hwtrailingstuff}
% There is also a boolean register, hwhavetrailing, defined under AtBeginDocument.
%
\newenvironment{hwsection}[1][Problems]{\newpage
    \setcounter{secnumdepth}{0}%
    \renewcommand{\printthesection}{}%
    \setcounter{figure}{0}%
    \begingroup%
    \renewcommand{\addcontentsline}[3]{}% temporarily disable \addcontentsline
    \mysection{#1}%
    \endgroup
    \hwcaptions
    The symbols \hwcheckmark, \displayhwdifficulty{1}, etc.
    are explained on page \pageref{hwsymbols\chapdir}.}
  {\noindent \vfill\noindent\emph{Key to symbols:}\label{hwsymbols\chapdir} \\
  	\displayhwdifficulty{0} easy \quad
  	\displayhwdifficulty{1} typical  \quad
  	\displayhwdifficulty{2} challenging  \quad
  	\displayhwdifficulty{3} difficult  \quad
  	\displayhwdifficulty{4} very difficult \\
	\hwcheckmark \quad An answer check is available at www.lightandmatter.com.
	 	\normalcaptions%
    \setcounter{secnumdepth}{2}%
}
% ... The \setcounter{secnumdepth} stuff is the way the author of titlesec suggests doing
%	this. Using section* messes up footers & toc. 
%
\newcommand{\currenthwlabel}{}
\newcommand{\calccrud}{}
\newenvironment{homework}[3]
	{\refstepcounter{hwctr}\label{hw:#1}\noindent\textbf{\thehwctr}%
	\renewcommand{\hwdifficulty}{#2}%
	\hwcleartrailingstuff
        \renewcommand{\currenthwlabel}{#1}
	\quad%
        \renewcommand{\calccrud}{}
        \ifthenelse{\equal{#3}{1}}{\renewcommand{\calccrud}{\hwaddtrailingstuff{$\int$}}}{}
        }
	{%
             \calccrud
             \hwaddtrailingstuff{%
                                \displayhwdifficulty{\hwdifficulty}
                            }%
             \hwflushtrailingstuff\par%
        }
\newenvironment{homeworkforcelabel}[4]
       {\renewcommand{\@currentlabel}{#4}\label{hw:#1}\noindent\textbf{#4}%
        \renewcommand{\hwdifficulty}{#2}%
        \hwcleartrailingstuff
         \renewcommand{\currenthwlabel}{#1}
	\quad%
        \renewcommand{\calccrud}{}
        \ifthenelse{\equal{#3}{1}}{\renewcommand{\calccrud}{\hwaddtrailingstuff{$\int$}}}{}
        }
	{%
             \calccrud
             \hwaddtrailingstuff{%
                                \displayhwdifficulty{\hwdifficulty}
                            }%
             \hwflushtrailingstuff\par%
        }
%
\newcommand{\hwendpart}[1][3]{\hwflushtrailingstuff[#1]\\}
%	The optional argument ends up being passed to \nolinebreak. It defaults to 3, but
%	you can make it 2 or 4 if it seems to be making the wrong decision.
%   If there is only one part to the problem, or if you're fiddling with the very last
%   part of a multipart problem, I think you can add a gratuitous \hwendpart, but
%   except in this situation, don't do \hwendpart after the last part, because sometimes
%   it causes extra blank lines to appear.
%
\newcommand{\hwhint}[1]{\hwaddtrailingstuff{\hwtriangle\ Hint, p. \pageref{#1}}}
\newcommand{\hwans}[1]{\hwaddtrailingstuff{\hwtriangle\ Answer, p. \pageref{#1}}}
\newcommand{\hwsoln}{\hwaddtrailingstuff{\hwtriangle\ Solution, p. \pageref{soln:\currenthwlabel}}}
\newcommand{\answercheck}{\hwaddtrailingstuff{\hwcheckmark}}
\newcommand{\displayhwdifficulty}[1]{\includegraphics{resources/difficulty#1}}
%
\newcommand{\hwtriangle}{$\triangleright$}
\newcommand{\hwcheckmark}{\scriptsize\raisebox{1mm}{$\surd$}\normalsize}
%
\newcommand{\hwflushtrailingstuff}[1][3]{\ifthenelse{\boolean{hwhavetrailing}}{\hwfill{#1}\usebox{\hwtrailingstuff}\hwcleartrailingstuff}{}}
%
\newcommand{\hwcleartrailingstuff}{\sbox{\hwtrailingstuff}{}\setboolean{hwhavetrailing}{false}}
%
\newcommand{\hwaddtrailingstuff}[1]{\sbox{\hwtrailingstuff}{\usebox{\hwtrailingstuff}\quad{}#1}%
                                             \setboolean{hwhavetrailing}{true}}
%
\newcommand{\hwfill}[1]{\hspace*{\fill}\nolinebreak[#1]\nopagebreak[1]\hspace*{\fill}}
% ... cf LaTeX Companion, p. 443
%
%
\newcommand{\scans}[1]{$\triangleright$\ Answer, p. \pageref{scans:#1}}
%=========================
%     exsection
% used for exercises in SN, based on hw section
% There is something similar called handson in LM.
%
\newenvironment{exsection}{
    \setcounter{secnumdepth}{0}          % Don't number this section.
    \renewcommand{\printthesection}{}    % Footers should read ``Exercises,'' not ``Section X.Y Exercises''
    \hwcaptions                          % figures in ex section don't have a, b, c, labels
    \setcounter{figure}{0}               %
    \nomarginlayout                      %
    \onecolumn                           % I don't understand why this is necessary, but it is. If I don't do it, no change in format occurs.
    \setlength{\parindent}{0mm}          % undone by normalparafmt
    \mysection{Exercises}                % Has the side-effect of generating a page break.
    \setcounter{secnumdepth}{2}          % Start numbering sections again.
                                         % The \setcounter{secnumdepth} stuff is the way the author of titlesec suggests doing
                                         % this. Using section* messes up footers & toc. 
}%
{%
  \vfill\normallayout\normalparafmt      %
  \onecolumn                             % See above.
}
\newcommand{\extitle}[2]{%
  \noindent\formatlikesubsection{Exercise \thechapter{}#1: #2}
}
%
%=========================
\newcommand{\eqquad}{}
% I used to have flying punctuation after displayed math, e.g.,
%      x=7 \qquad .
% I decided that looked bad, so I replaced the qquads with this do-nothing macro.
\newcommand{\mynormaltype}{\normalsize\normalfont\myeqnspacing}
\newcommand{\myeqnspacing}{
	\setlength{\abovedisplayskip}{4mm plus 1mm minus 3mm}
	\setlength{\belowdisplayskip}{4mm plus 1mm minus 3mm}
	\setlength{\abovedisplayshortskip}{0mm plus 1mm}
	\setlength{\belowdisplayshortskip}{2mm plus 1mm minus 1mm}
}
%==============================toc==================================
\newcommand{\link}[2]{\protect\jumplink{anchor-#1}{\textcolor{blue}{#2}}} % navigator package
\newcommand{\brieftocentry}[3][\quad]% #1=\hfill (LM and Me.) or \quad (other books), #2=label, #3=title, 
            {\ref{#2} & #3 #1 \pageref{#2}}
\newcommand{\brieftocentrywithlink}[3][\quad]% #1=\hfill (LM and Me.) or \quad (other books), #2=label, #3=title, 
            {\link{#2}{\ref{#2}} & \link{#2}{#3} #1 \link{#2}{\pageref{#2}}}
\newcommand{\toclinewithlink}[4]% #1=subsection, etc., #2=label, #3=title, #4=\thesubsection, etc.
  {%
    \addcontentsline{toc}{#1}{\protect\numberline{#4}\link{#2}{#3}}%
  }
\newcommand{\toclinewithoutlink}[4]% #1=subsection, etc., #2=label, #3=title, #4=\thesubsection, etc.
  {%
    \addcontentsline{toc}{#1}{\protect\numberline{#4}#3}%
  }
\newcommand{\formatchtoc}[3]{%
  \titlecontents{chapter}[0mm]{\addvspace{#3}\sffamily}%
	{\contentsmargin{0mm}#1\thecontentslabel\enspace#1}%
	{\contentsmargin{0mm}#1}{#2}[]%
}
\contentsmargin{6mm}
\titlecontents{part}[0mm]{\addvspace{5mm}\sffamily\bfseries}
	{\contentsmargin{0mm}\bfseries\Large{}\thecontentslabel\enspace\Large}
	{\contentsmargin{0mm}\Large}{}[\addvspace{2mm}]
\titlecontents{section}[0mm]{\sffamily}
	{\contentsmargin{0mm}\thecontentslabel\enspace}
	{}{\titlerule*[4mm]{.}\contentspage}
% In the following, titlecontents* is titletoc's way of saying I want subsections listed in a single paragraph.
\titlecontents*{subsection}[1.5em]{\small}{}%
		{}{, \thecontentspage}[.---][.]
\titlecontents{subsubsection}[]{}{}{}{}[]
%========================= graphicx package=========================
\usepackage{graphicx}
%========================= AtBeginDocument stuff=========================
\AtBeginDocument{
  \newboolean{hwhavetrailing}
  \DeclareGraphicsExtensions{.pdf,.jpg,.png}
  \newcommand{\chapdir}{glub}
  \myeqnspacing
  	% This gets reset any time I do normalsize, so have to do it after preamble,
  	% and have to use \mynormaltype rather than \normalsize
}

\StopSaveCommands % for learn-cmd-syntax
\WriteSaveCommands  % for learn-cmd-syntax
