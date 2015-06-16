.PHONY: all clean

OCAMLBUILD := ocamlbuild -classic-display -use-ocamlfind -use-menhir -cflags "-g" -lflags "-g"
MAIN       := main
EXAMPLES   := basic2

all:
	$(OCAMLBUILD) $(MAIN).native

clean:
	$(OCAMLBUILD) -clean

examples: $(EXAMPLES)

$(EXAMPLES):
	$(OCAMLBUILD) examples/$@.native
