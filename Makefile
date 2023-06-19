DOCTYPE = DMTR
NAMESPACE = DM
PLAN = LVV-P90
DOCNUMBER = 331
DOCNAME = $(DOCTYPE)-$(DOCNUMBER)
JOBNAME = $(DOCNAME)
TEX = $(filter-out $(wildcard *acronyms.tex) , $(wildcard *.tex))

export TEXMFHOME ?= lsst-texmf/texmf

# Version information extracted from git.
GITVERSION := $(shell git log -1 --date=short --pretty=%h)
GITDATE := $(shell git log -1 --date=short --pretty=%ad)
GITSTATUS := $(shell git status --porcelain)
ifneq "$(GITSTATUS)" ""
	GITDIRTY = -dirty
endif


$(JOBNAME).pdf: $(DOCNAME).tex meta.tex acronyms.tex LVV-T2338.pdf
	xelatex -jobname=$(JOBNAME) $(DOCNAME)
	bibtex $(JOBNAME)
	xelatex -jobname=$(JOBNAME) $(DOCNAME)
	xelatex -jobname=$(JOBNAME) $(DOCNAME)
	xelatex -jobname=$(JOBNAME) $(DOCNAME)

LVV-T2338.pdf : LVV-T2338.ipynb
	jupyter nbconvert --to PDF LVV-T2338.ipynb 


install-dep:
	pip install -r requirements.txt

conda:
	conda create --name docsteady-env docsteady -c lsst-dm -c conda-forge


.FORCE:

meta.tex: Makefile .FORCE
	rm -f $@
	touch $@
	printf '%% GENERATED FILE -- edit this in the Makefile\n' >>$@
	printf '\\newcommand{\\lsstDocType}{$(DOCTYPE)}\n' >>$@
	printf '\\newcommand{\\lsstDocNum}{$(DOCNUMBER)}\n' >>$@
	printf '\\newcommand{\\vcsRevision}{$(GITVERSION)$(GITDIRTY)}\n' >>$@
	printf '\\newcommand{\\vcsDate}{$(GITDATE)}\n' >>$@


generate: .FORCE
	docsteady --namespace $(NAMESPACE) generate-tpr $(PLAN) $(DOCNAME).tex


#Traditional acronyms are better in this document
acronyms.tex : ${TEX} myacronyms.txt skipacronyms.txt
	echo ${TEXMFHOME}
	python3 ${TEXMFHOME}/../bin/generateAcronyms.py -t "DM"    $(TEX)

myacronyms.txt :
	touch myacronyms.txt

skipacronyms.txt :
	touch skipacronyms.txt

clean :
	latexmk -c
	rm *.pdf *.nav *.bbl *.xdv *.snm
