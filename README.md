Light and matter
================
This is the LaTeX source code for
a set of several different introductory physics textbooks, at a variety of mathematical levels.
One of the books is called Light and Matter, but several others are also included in this source code archive.
For more information about the books, see their web site at [lightandmatter.com](http://www.lightandmatter.com).

producing pdf output
====================
Compiling the book into pdf format is fairly easy on a Linux
machine. Basically you just need to install some open-source
software. The following are the relevant packages on a Debian-based
system such as Ubuntu:
  texlive-full
  m4
  inkscape
  imagemagick
  libjson-ruby
  libjson-perl (version 2.0 or higher)
  ruby 1.9.2, packaged as ruby1.9 (karmic koala) or simply as ruby (lucid lynx)
  xml-twig-tools
  qpdf
  poppler-utils

Go to the main directory (the one where you found this README).

Make sure you have at least inkscape 0.47 and ruby 1.9. The following
command will make all the necessary scripts executable, and will
also test whether your version of ruby is new enough to use:
  make setup

Convert all the figures from editable svg format to pdf format:
  make lm_cover
  make all_figures
Ignore the warnings that say "WARNING **: No export filename given 
and no filename hint. Nothing exported."

Produce pdf output of all the books:
  make books_all

If you have trouble getting this to work, see the section below titled
"troubleshooting, bugs, and workarounds."

I haven't tried compiling the books on MacOS X or Windows. I suspect
it could be done on MacOS X without any heroic measures, and I suspect
that it would be a real pain on Windows.

producing html, epub, and mobi output
=====================================
To produce html output requires a little more software. First, you
need the following additional Debian packages:
  xpdf imagemagick tex4ht dvipng
(The xpdf dependency is because of pdftoppm, which comes bundled
with it.)

You'll also need footex:
  http://www.lightandmatter.com/footex/footex.html

If you want to produce epub and mobi output, you'll also need
to install calibre.

Once you've done this, you can use this command:
  make web

troubleshooting, bugs, and workarounds
======================================
If you modify a file between compiles, it may cause ruby errors.
  Workaround: recompile from scratch.
  I think this may happen if your edits change which figure groups exist.
Figures are positioned on the wrong side of the page, as if odd and even
are confused. This continues through the end of the chapter.
  This happened to me in May '08 with ch. 10 of SN. Doing a
  make clean && make book to start fresh didn't help. However,
  when I got up the next morning and tried again, it didn't happen!
  This may be a problem where iterations of pdflatex don't converge
  on pagination.
Narrowfigwidecaption doesn't reliably detect even/odd page.
Goofy typesetting of symbols at end of hw in SN.
  Don't use \hwendpart macro at the very end of a problem.
'Make prepress' dies with an error from ghostscript,
  "ExtGState 's6' is unknown".
  This happens with some figures when the figure is saved as
  pdf by inkscape, e.g., gravity-probe-g-geodetic. The workaround
  is to save it as a bitmap. The error can be detected by opening
  the file with xpdf; uses same lib as gs, gives same error.
  https://bugs.launchpad.net/inkscape/+bug/681512
  This is a problem with cairo, can be fixed by upgrading from
  ubuntu maverick to natty.
Figure positioning doesn't work, no feedback loop.
  This can happen because there is no end_chapter in the rbtex file.

Miscellaneous
=============

More technical details about the software setup are in INTERNALS.
