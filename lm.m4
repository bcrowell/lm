m4_changecom(`//%')m4_dnl
m4_changequote(`[:',`:]')m4_dnl
m4_define([:__incl:],[:m4_include(__share/$1.tex):])m4_dnl
m4_define([:__sincl:],[:m4_sinclude(__share/$1.tex):])m4_dnl
m4_define([:__shotwell:],[:m4_ifelse(__problems,1,[::],[: {[Problem by B.~Shotwell.]}:]):])m4_dnl
% ... he's credited as an author in PIP, so no separate credit is needed there
m4_define([:__widmann:],Problem by P.~Widmann.)m4_dnl                                        
