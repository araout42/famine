OUTPUT=pestilence
SRC_DIR=srcs/
INCLUDE_DIR=includes/
SRC=pestilence.s
INCLUDE=header.s
OBJ=pestilence.o

COMP=nasm
FLAG=-f elf64
LD_FLAG= --discard-all
LINK=ld

all:
	$(COMP) $(FLAG) $(SRC_DIR)$(SRC) -o $(OBJ)
	$(LINK) $(OBJ) $(LD_FLAG) -o $(OUTPUT)

clean:
	@/bin/rm  -f $(OBJ) 2>/dev/null

fclean:
	@/bin/rm -f $(OUTPUT) 2>/dev/null
	@/bin/rm -f $(OBJ) 2>/dev/null

re: fclean all

