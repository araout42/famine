OUTPUT=famine
SRC_DIR=srcs/
INCLUDE_DIR=includes/
SRC=famine.s
INCLUDE=header.s
OBJ=famine.o

COMP=nasm
FLAG=-f elf64
LD_FLAG= --discard-all
LINK=ld

all:
	$(COMP) $(FLAG) $(SRC_DIR)$(SRC) -o $(OBJ)
	$(LINK) $(OBJ) $(LD_FLAG) -o $(OUTPUT)

clean:
	@rm $(OBJ)

fclean: clean
	@rm $(OUTPUT)

re: fclean all

