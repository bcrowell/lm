# See README for information about what this is used for.

# To make and post encrypted solutions, don't use this directly. Do a
# make in the teaching/solns directory. That will indirectly invoke this
# makefile.

CLS_FILES = "problems.cls","../shaddap.sty","../lmmath.sty","timetravel.sty"
# ... a list of files that's assumed to exist in the parent dir, which we
#     copy into the working dir when building the book; "CLS_" is really a misnomer
GET_CLS = perl -e 'foreach $$f($(CLS_FILES)) {$$cmd="cp ../$$f ."; system $$cmd}'
RM_CLS = rm -f problems.cls shaddap.sty lmmath.sty timetravel.sty
SCRIPTS = ..
TEX_INTERPRETER = pdflatex
DO_PDFLATEX_RAW = $(TEX_INTERPRETER) -shell-escape -interaction=nonstopmode $(BOOK) >err
SPOTTER_DIR = /home/bcrowell/Documents/programming/spotter/answers
DATA_DIR = ../../data
BOOK = solns

.SILENT: # suppress messages such as "entering directory"

-include ../password.make # - means don't throw an error if it's not present

default:
	@make init-timetravel
	$(GET_CLS)
	@echo "Running $(SCRIPTS)/generate_problems.rb..."
	$(SCRIPTS)/generate_problems.rb solutions "" 1 $(DATA_DIR) $(SOLUTIONS_DIR) >$(BOOK).m4
	@echo "Running m4..."
	m4 -P ../problems.m4 $(BOOK).m4 >$(BOOK).tex
	@echo "Running pdflatex..."
	@$(SCRIPTS)/timetravel.rb $(BOOK).tex
	@$(DO_PDFLATEX_RAW)
	@echo "Running pdflatex three more times..."
	@$(SCRIPTS)/timetravel.rb $(BOOK).tex
	@$(DO_PDFLATEX_RAW)
	@$(SCRIPTS)/timetravel.rb $(BOOK).tex
	@$(DO_PDFLATEX_RAW)
	# one more time...? --
	@$(DO_PDFLATEX_RAW)
        #
	@$(RM_CLS)

init-timetravel:
	@rm -f *.aux *.ind
	@rm -Rf timetravel

preflight:
	# make sure we always have latest version of timetravel package:
	@-cp ~/Documents/programming/timetravel/timetravel.rb $(SCRIPTS) 
	@-cp ~/Documents/programming/timetravel/timetravel.sty $(SCRIPTS) 
	# make sure scripts are executable:
	@chmod +x $(SCRIPTS)/generate_problems.rb $(SCRIPTS)/photocredits.rb $(SCRIPTS)/timetravel.rb $(SCRIPTS)/harvest_aux.rb

clean:
	rm -f $(BOOK).aux $(BOOK).log $(BOOK).m4 $(BOOK).pdf $(BOOK).toc err *~ temp.*
	$(RM_CLS)
	rm -Rf timetravel
