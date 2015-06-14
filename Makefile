.PHONY: all clean

OCAMLBUILD := ocamlbuild -classic-display -use-ocamlfind -use-menhir -cflags "-g" -lflags "-g"
MAIN       := main

all:
	$(OCAMLBUILD) $(MAIN).native

clean:
	$(OCAMLBUILD) -clean
