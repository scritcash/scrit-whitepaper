all: scrit-whitepaper.pdf

scrit-whitepaper.pdf: image/transaction.pdf

%.pdf: %.md %.bib
	pandoc --standalone --table-of-contents --number-sections \
         --variable papersize=a4paper \
         --variable classoption=twocolumn \
         --variable links-as-notes \
         --filter pandoc-citeproc --bibliography=scrit-whitepaper.bib \
         -s $< \
         -o $@

.PHONY: fmt clean
fmt:
	pandoc --standalone -o tmp.md -s scrit-whitepaper.md
	mv tmp.md scrit-whitepaper.md

clean:
	rm -f scrit-whitepaper.pdf
