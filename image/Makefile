all: distributed.pdf

# conversion with ASCIIToSVG
# https://github.com/imatix/zguide/tree/master/bin/asciitosvg
%.svg: %.txt
	a2s -i$< -o$@

%.pdf: %.svg
	inkscape --export-pdf=$@ $<

.PHONY: clean
clean:
	rm -f distributed.pdf
