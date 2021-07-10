OUTPUT=war
SRC_DIR=srcs/
INCLUDE_DIR=includes/
SRC=war.s
INCLUDE=header.s
OBJ=war.o

COMP=nasm
FLAG=-f elf64
LD_FLAG= --discard-all
LINK=ld

all: $(OBJ) $(OUTPUT)


war: $(OBJ)
	$(LINK) $(OBJ) $(LD_FLAG) -o $(OUTPUT)

$(OBJ):
	$(COMP) $(FLAG) $(SRC_DIR)$(SRC) -o $(OBJ)


clean:
	@/bin/rm  -f $(OBJ) 2>/dev/null

fclean:
	@/bin/rm -f $(OUTPUT) 2>/dev/null
	@/bin/rm -f $(OBJ) 2>/dev/null

re: fclean all

