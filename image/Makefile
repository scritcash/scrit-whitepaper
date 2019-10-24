all: transaction.pdf bitcoin.png

bitcoin.png:
	qrencode -s 8 -o $@ 36hMdVaZWUHbsnXfPsJtXe7ZRcU6jciAFt

# conversion with ASCIIToSVG
# https://github.com/imatix/zguide/tree/master/bin/asciitosvg
%.svg: %.txt
	a2s -i$< -o$@

%.pdf: %.svg
	inkscape --export-pdf=$@ $<

.PHONY: clean
clean:
	rm -f distributed.pdf
