all: scrit-whitepaper.pdf

scrit-whitepaper.pdf: image/transaction.pdf image/transaction-format.pdf image/key-rotation.pdf

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
	pandoc -o tmp.md -s scrit-whitepaper.md
	mv tmp.md scrit-whitepaper.md
	pandoc -o tmp.md -s README.md
	mv tmp.md README.md

clean:
	rm -f scrit-whitepaper.pdf
