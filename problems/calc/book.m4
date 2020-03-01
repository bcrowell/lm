m4_define([:__calc:],1)m4_dnl
m4_define([:__pe:],U)m4_dnl
m4_define([:__shotwell:],[:m4_ifelse(__problems,1,[::],[: [Problem by B.~Shotwell.]:]):])m4_dnl
% ... he's credited as an author in PIP, so no separate credit is needed there
m4_define([:__widmann:],Problem by P.~Widmann.)m4_dnl
m4_define([:__sn:],1)m4_dnl
% ... some problems are special-cased for __lm_series and __sn (and possibly __cp); make sure
%     something sane happens for this book
m4_define([:__mod:],0)m4_dnl
