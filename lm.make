# This file is meant to be included from the
# makefiles in the individual books' directories.

NICE = nice ionice -n7
GS = $(NICE) gs
DIST_DIR = $(BOOK)
DIST_ARCHIVE = $(BOOK).tar.gz
MODE = nonstopmode
TERMINAL_OUTPUT = err
MYSELF = Makefile
CLS_FILES = "lmseries.cls","lmcommon.sty","lmfigs.sty","lmlayout.sty","lmmath.sty","lm.make","mytocloft.sty","lmlanguage.sty","lmenvironments.sty","fullembed.map","learn-cmd-syntax.sty","custom_html.yaml","shaddap.sty"
# ... a list of files that's assumed to exist in the parent dir, which we
#     copy into the working dir when building the book; "CLS_" is really a misnomer
GET_CLS = perl -e 'foreach $$f($(CLS_FILES)) {$$cmd="cp $(FILE_PREFIX)../$$f ."; system $$cmd}'
RM_CLS = perl -e 'foreach $$f($(CLS_FILES)) {system "rm -f $$f"}'
RM_TEMP = rm -f *.pos */*temp.* */*.bak eruby_complaints
RUN_ERUBY = $(NICE) perl -I../scripts ../scripts/run_eruby.pl
HARVEST_AUX_FILES = ../scripts/harvest_aux_files.rb
SPLIT_BOOK = ../scripts/split_book.pl
HANDHELD_TEMP = handheld_temp
GENERIC_OPTIONS_FOR_CALIBRE =  --authors "Benjamin Crowell" --language en --toc-filter="[0-9]\.[0-9]"
PROBLEMS_CSV = ../data/problems.csv
SPOTTER_ANSWERS = /home/bcrowell/Documents/programming/spotter/answers
SPOTTER_M4_FILE = $(SPOTTER_ANSWERS)/$(BOOK).m4

MAKEINDEX = makeindex $(BOOK).idx >/dev/null

TEX_INTERPRETER = pdflatex
#TEX_INTERPRETER = lualatex
# ... lualatex sometimes segfaults on Mechanics, but not always reproducible
DO_PDFLATEX_RAW = $(NICE) $(TEX_INTERPRETER) -shell-escape -interaction=$(MODE) $(BOOK) >$(TERMINAL_OUTPUT)
# -shell-escape is so that write18 will be allowed
# environment variable  openout_any=a is so that we can write to ../share/end
SHOW_ERRORS = \
        system("../scripts/filter_latex_messages.rb <$(TERMINAL_OUTPUT) >a.a && mv a.a $(TERMINAL_OUTPUT)"); \
        print "========error========\n"; \
        open(F,"$(TERMINAL_OUTPUT)"); \
        while ($$line = <F>) { \
          if ($$line=~m/^\! / || $$line=~m/^l.\d+ /) { \
            print $$line \
          } \
        } \
        close F; \
        exit(1)
DO_PDFLATEX = echo "$(DO_PDFLATEX_RAW)" ; perl -e 'if (system("$(DO_PDFLATEX_RAW)")) {$(SHOW_ERRORS)};'
DO_MAKEFILEPREAMBLE = perl -e 'open(F,">makefilepreamble.tex"); if ("$(POPT)"=~/only(\d+)/) {print F "\\includeonly{ch$$1/ch$$1temp}"} close F'

# Since book1 comes first, it's the default target --- you can just do ``make'' to make it.

export GIT_DIR = "~/Git_LM/$(BOOK_LABEL)"
# export makes it set the actual environment variable (not just the makefile macro) for all processes run by the makefile

book1:
	@make preflight
	@../scripts/before_each.rb
	@../scripts/translate_to_html.rb --write_config_and_exit
	$(RUN_ERUBY) - $(FIRST_CHAPTER) $(DIRECTORIES)
	@../scripts/harvest_code_listings.pl
	@$(GET_CLS)
	@$(DO_MAKEFILEPREAMBLE)
	@$(DO_PDFLATEX)
	@../scripts/translate_to_html.rb --util="learn_commands:$(BOOK).cmd"
	@$(HARVEST_AUX_FILES)
	@rm -f $(TERMINAL_OUTPUT) # If pdflatex has a nonzero exit code, we don't get here, so the output file is available for inspection.
	@../process_geom_file.pl <geom.pos >temp.pos
	@mv temp.pos geom.pos
	@$(RM_CLS)
	@perl -e 'if (-e "eruby_complaints") {system "cat eruby_complaints"}'

index:
	$(MAKEINDEX)

book:
	@make preflight
	@../scripts/before_each.rb
	@make clean
	@../scripts/translate_to_html.rb --write_config_and_exit
	@rm -f geom.pos
	@rm -f marg.pos
	@$(RUN_ERUBY) - $(FIRST_CHAPTER) $(DIRECTORIES)
	@../scripts/harvest_code_listings.pl
	@$(GET_CLS)
	@$(DO_MAKEFILEPREAMBLE)
	@$(DO_PDFLATEX)
	@../scripts/translate_to_html.rb --util="learn_commands:$(BOOK).cmd"
	@$(HARVEST_AUX_FILES)
	@../process_geom_file.pl <geom.pos >temp.pos
	@mv temp.pos geom.pos
	@$(RUN_ERUBY) - $(FIRST_CHAPTER) $(DIRECTORIES)
	@$(DO_MAKEFILEPREAMBLE)
	@../scripts/before_each.rb
	@$(DO_PDFLATEX)
	@$(HARVEST_AUX_FILES)
	@../process_geom_file.pl <geom.pos >temp.pos
	@mv temp.pos geom.pos
	@$(RUN_ERUBY) - $(FIRST_CHAPTER) $(DIRECTORIES)
	$(MAKEINDEX)
	@$(DO_MAKEFILEPREAMBLE)
	@../scripts/before_each.rb
	@$(DO_PDFLATEX)
	@$(HARVEST_AUX_FILES)
	@perl -e 'open(F,"<$(TERMINAL_OUTPUT)"); while ($$l=<F>) {if ($$l=~/LaTeX Warning: Reference/) {print "****** $$l"}}; close F'
	@../process_geom_file.pl <geom.pos >temp.pos
	@mv temp.pos geom.pos
	@../check_for_colliding_figures.rb
	@../scripts/before_each.rb
	@$(DO_PDFLATEX) # a fourth time, because otherwise some references don't work, e.g., ref. in EM 1-2 to back of book
	@$(HARVEST_AUX_FILES)
	@rm -f $(TERMINAL_OUTPUT) # If pdflatex has a nonzero exit code, we don't get here, so the output file is available for inspection.
	@$(RM_CLS)
	@perl -e 'if (-e "eruby_complaints") {system "cat eruby_complaints"}'
	make update_problems
	make update_spotter

update_problems:
	../scripts/merge_problems_data.rb $(BOOK) ../data

update_spotter:
	../scripts/generate_spotter_file.rb $(PROBLEMS_CSV) $(SPOTTER_ANSWERS) >temp_spotter.m4
	@if ! [ -e $(SPOTTER_M4_FILE) ] ; then \
	  cp temp_spotter.m4 $(SPOTTER_M4_FILE) ; \
	fi
	@if !(cmp -s temp_spotter.m4 $(SPOTTER_M4_FILE)) ; then \
	    echo "Files temp_spotter.m4 and $(SPOTTER_M4_FILE) differ, consider overwriting"  ; \
	fi

web:
	# To make html versions for blind people, don't do this; do 'make blind.'
	@[ `which footex` ] || echo "******** footex is not installed, so html cannot be generated; get footex from http://www.lightandmatter.com/footex/footex.html"
	@[ `which footex` ] || exit 1
	@make preflight
	@cp ../custom_html.yaml .
	@../scripts/translate_to_html.rb --write_config_and_exit
	@rm -f macros_not_handled
	# In the following, --test suppresses ads and make css file local.
	WOPT='$(WOPT) --test --html5' $(RUN_ERUBY)  w $(FIRST_CHAPTER) $(DIRECTORIES)  #... html 5 with mathml
	WOPT='$(WOPT) --test --mathjax' $(RUN_ERUBY) w $(FIRST_CHAPTER) $(DIRECTORIES) #... html 4 with mathjax
	# To set options, do, e.g., "WOPT='--no_write' make web". Options are documented in translate_to_html.rb.

blind:
	# Html output with no figures, for use by blind people.
	@[ `which footex` ] || echo "******** footex is not installed, so html cannot be generated; get footex from http://www.lightandmatter.com/footex/footex.html"
	@[ `which footex` ] || exit 1
	@make preflight
	@cp ../custom_html.yaml .
	@../scripts/translate_to_html.rb --write_config_and_exit
	@rm -f macros_not_handled
	# In the following, --test suppresses ads and make css file local.
	WOPT='$(WOPT) --blind --test --html5' $(RUN_ERUBY)  w $(FIRST_CHAPTER) $(DIRECTORIES)  #... html 5 with mathml
	# When done generating all books, make a Windows-compatible zip archive like this:
	#   cd ~/Generated
	#   zip -9 -y -r -q light_and_matter.zip html_books/
	#   windows compatibility: https://superuser.com/questions/5155/how-to-create-a-zip-file-compatible-with-windows-under-linux

wiki:
	WOPT='$(WOPT) --wiki' $(RUN_ERUBY) w

prepress:
	cd .. ; make preflight_figs ; cd -
	PREPRESS=1 make book
	# Filtering through gs used to be necessary to convince Lulu not to complain about missing fonts.
	# Now that should no longer be necessary, because recent versions of pdftex embed all fonts, and fullembed.map prevents subsetting.
	# See meki:computer:apps:ghostscript, scripts/create_fullembed_file, and http://tex.stackexchange.com/questions/24002/turning-off-font-subsetting-in-pdftex
	../scripts/preflight_pdf.pl $(BOOK).pdf
	perl -e 'if ("$(BOOK)" eq 'cp' || "$(BOOK)" eq 'me' || "$(BOOK)" eq 'fac') {system("make prepress_single_vol")} else {system("make prepress_splits")}'
	
prepress_single_vol:
	# Don't use this directly; just do a 'make prepress'.
	pdftk $(BOOK).pdf cat 3-end output lulu_$(BOOK).pdf
	@rm -f temp.pdf

prepress_splits:
	# Don't use this directly; just do a 'make prepress'.
	$(NICE) ../scripts/splits.pl $(BOOK).pdf 1 lulu_$(BOOK)_v1.pdf
	$(NICE) ../scripts/splits.pl $(BOOK).pdf 2 lulu_$(BOOK)_v2.pdf
	@rm -f temp.pdf

test:
	perl -e 'if (system("pdflatex -interaction=$(MODE) $(BOOK) >$(TERMINAL_OUTPUT)")) {print "error\n"} else {print "no error\n"}'

very_clean: clean
	rm -f $(BOOK).pdf lulu*.pdf *.epub *.mobi *.postm4 *.temp ch*.csv ch*temp.tex brief-toc.tex brief-toc-new.tex
	rm -Rf $(HANDHELD_TEMP)
	rm -f learned_commands.json custom_html.yaml declaregraphicsextensions.tex

clean:
	# Cleaning...
	@$(RM_TEMP)
	@$(RM_CLS)
	@rm -f temp.tex temp_spotter.m4
	@rm -f bk*lulu.pdf simple1.pdf simple2.pdf # lulu files
	@rm -f */*.pos geom.pos report.pos marg.pos makefilepreamble 
	@rm -f figfeedback*
	@rm -f */*temp_new */*.postm4 */*.wiki */*temp.tex
	@rm -f code_listing_* code_listings/* code_listings.zip
	@rm -Rf code_listings
	@rm -f temp.* temp_mathml.*
	@# Sometimes we get into a state where LaTeX is unhappy, and erasing these cures it:
	@rm -f *aux *idx *ilg *ind *log *toc
	@rm -f */*aux
	@# Shouldn't exist in subdirectories:
	@rm -f */*.log
	@# Emacs backup files:
	@rm -f *~
	@rm -f */*~
	@rm -f */*/*~
	@rm -f */*.temp
	@# Misc:
	@rm -Rf */figs/.xvpics
	@rm -f a.a
	@rm -f */a.a
	@rm -f */*/a.a
	@rm -f junk
	@rm -f err
	@# ... done.


post:
	cp $(BOOK).pdf save.pdf # save unwatermarked version, so, e.g., if we do a make prepress, we won't inadvertently use the watermarked version
	# pdftk $(BOOK).pdf background ../watermark/watermark.pdf output temp.pdf
	# mv temp.pdf $(BOOK).pdf
	$(SPLIT_BOOK) $(BOOK).pdf
	# move, e.g., bk1.pdf, bk1a.pdf, ..., but don't move simple1.pdf or simple2.pdf if they exist:
	perl -e 'foreach $$f(<$(BOOK)?.pdf>) {if ($$f=~/$(BOOK)[a-z].pdf/) {$$c="mv -v $$f $(HOME)/Lightandmatter"; system $$c}}'
	mv save.pdf $(BOOK).pdf
	cp  $(BOOK).pdf $(HOME)/Lightandmatter
	perl -e 'if (-e "code_listings.zip") {system("cp code_listings.zip $(HOME)/Lightandmatter/$(BOOK)_code_listings.zip")}'

preflight:
	@perl -e 'foreach $$g("scripts/check_ruby_version.rb","scripts/run_eruby.pl","fruby","mv_silent","scripts/translate_to_html.rb","process_geom_file.pl","scripts/harvest_aux_files.rb","scripts/latex_table_to_html.pl","scripts/equation_to_image.pl","check_for_colliding_figures.rb","scripts/harvest_code_listings.pl") {$$f="../$$g"; die "file $$g is not executable; fix this with chmod +x $$g" unless -e $$f && -x $$f}'
	@../scripts/check_ruby_version.rb
	@perl -e 'if (-e "../scripts/custom/enable") {system("chmod +x ../scripts/custom/*"); foreach $$f(<../scripts/custom/*.pl>) {$$c="$$f $(BOOK) $(PROBLEMS_CSV)"; system($$c)}}'
	@#[ `which footex` ] || echo "******** warning: footex is not installed, so html cannot be generated; get footex from http://www.lightandmatter.com/footex/footex.html"

handheld:
	# see meki/zzz_misc/publishing for notes on how far I've progressed with this
	make preflight
	@cp ../custom_html.yaml .
	../scripts/translate_to_html.rb --write_config_and_exit --modern --override_config_with="../config/handheld.config"
	rm -f $(HANDHELD_TEMP)/ch*/*html $(HANDHELD_TEMP)/index.*html
	mkdir -p $(HANDHELD_TEMP)
	WOPT='$(WOPT) --modern --override_config_with="../config/handheld.config"' $(RUN_ERUBY) w $(FIRST_CHAPTER) $(DIRECTORIES) #... xhtml
	cp ../standalone.css $(HANDHELD_TEMP)
	make epub
	make mobi
	@echo "To post the books, do 'make post_handheld'."

post_handheld:
	cp $(BOOK).epub $(HOME)/Lightandmatter
	cp $(BOOK).mobi $(HOME)/Lightandmatter

epub:
	# Before doing this, do a "make handheld".
	ebook-convert $(HANDHELD_TEMP)/index.html $(BOOK).epub $(GENERIC_OPTIONS_FOR_CALIBRE) --no-default-epub-cover

mobi:
	# Before doing this, do a "make handheld".
	ebook-convert $(HANDHELD_TEMP)/index.html $(BOOK).mobi $(GENERIC_OPTIONS_FOR_CALIBRE) --rescale-images

epubcheck:
	java -jar /usr/bin/epubcheck/epubcheck.jar $(BOOK).epub 2>err
