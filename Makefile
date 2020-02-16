RUN_ERUBY = perl -I../scripts ../scripts/run_eruby.pl

default:
	@echo "Please see the README file for information on how to produce PDF files."

books_all:
	cd lm && make book && cd ..
	cd sn && make book && cd ..
	cd cp && make book && cd ..
	cd me && make book && cd ..
	cd fac && make book && cd ..
	cd mod && make book && cd ..

setup:
	chmod +x scripts/* eruby_util.rb fruby mv_silent process_geom_file.pl ./*.rb ./*.pl problems/*.rb
	chmod -x scripts/*.pm scripts/*.xml scripts/*.json
	@echo "If the following command doesn't give a compiler error, you have a sufficiently up to date version of ruby (1.9.2 or later)."
	ruby -e 'x=("ab" =~ /(?<!a)b/); require "psych"; require "yaml"'
	@echo "If the following command doesn't give a compiler error, you have a sufficiently up to date version of libjson-perl."
	@echo "If your version of the library is too old, you can uninstall it and then install the latest version by doing 'cpan JSON'."
	perl -e 'use JSON 2.0'

clean_all:
	cd lm && make clean && cd ..
	cd cp && make clean && cd ..
	cd sn && make clean && cd ..
	cd me && make clean && cd ..
	cd fac && make clean && cd ..
	cd mod && make clean && cd ..

very_clean_all:
	cd lm && make very_clean && cd ..
	cd cp && make very_clean && cd ..
	cd sn && make very_clean && cd ..
	cd me && make very_clean && cd ..
	cd fac && make very_clean && cd ..
	cd mod && make very_clean && cd ..
	cd problems/calc && make clean && cd -

prepress_all:
	cd lm && make prepress && cd ..
	cd cp && make prepress && cd ..
	cd sn && make prepress && cd ..
	cd me && make prepress && cd ..

run_eruby_all:
	cd lm && $(RUN_ERUBY) && cd ..
	cd cp && $(RUN_ERUBY) && cd ..
	cd sn && $(RUN_ERUBY) && cd ..
	cd me && $(RUN_ERUBY) && cd ..

web_all:
	cd lm && make web && cd ..
	cd cp && make web && cd ..
	cd sn && make web && cd ..
	cd me && make web && cd ..

post_all:
	# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	# Make sure you've built all the books, first!
	# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	cd lm && make post && cd ..
	cd cp && make post && cd ..
	cd sn && make post && cd ..
	cd me && make post && cd ..

handheld_all:
	cd lm && make handheld && cd ..
	cd cp && make handheld && cd ..
	cd sn && make handheld && cd ..
	cd me && make handheld && cd ..

all_figures:
	make lm_cover
	make me_cover
	make interior_figures

interior_figures:
	# The following requires Inkscape 0.47 or later.
	# To force rendering of all figures, even if they seem up to date, do FORCE=1 make interior_figures
	perl -e 'foreach my $$f(<*/*/figs/*.svg>) {system("scripts/render_one_figure.pl $$f $(FORCE)")}'
	perl -e 'foreach my $$f(<share/misc/arrows/*.svg>) {system("scripts/render_one_figure.pl $$f $(FORCE)")}'
	# For better reliability in RIP, make png versions as well.
	perl -e 'foreach my $$f(<*/*/figs/*.pdf>) {system("scripts/pdf_to_bitmap.pl $$f png $(FORCE)")}'
	perl -e 'foreach my $$f(<share/misc/arrows/*.pdf>) {system("scripts/pdf_to_bitmap.pl $$f png $(FORCE)")}'

preflight_figs:
	@echo "checking all figures in all books for transparency, broken links, embedded fonts, bad structure..."
	scripts/preflight_figs.pl
	@echo "...done"

lm_cover:
	cd lm/front/figs && inkscape --export-text-to-path --export-dpi=300 --export-png=temp.png cover_parts/cover.svg && convert temp.png cover.jpg && rm -f temp.png && cd -

me_cover:
	cd me/front/figs && inkscape --export-text-to-path --export-dpi=300 --export-png=temp.png cover_parts/cover.svg && convert temp.png cover.jpg && rm -f temp.png && cd -
