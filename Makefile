.PHONY:
setup:
	crystal build src/musgas.cr
	mv ./musgas ~/.local/bin/
