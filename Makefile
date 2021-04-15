OUTPUT:='famine'
SRC_DIR:='srcs/'
INCLUDE_DIR='includes/'
SRC:='loader.s'
INCLUDE:='header.s'
OBJ:='loader.o'

COMP:='nasm'
FLAG:='-f elf64'
LINK:='ld'

all:
	$(COMP) $(FLAG) $(SRC_DIR)$(SRC) -o $(OBJ)
	$(LINK) $(OBJ) -o $(OUTPUT)

clean: 
	rm $(OBJ)

fclean: 
	rm $(OBJ) $(OUPUT)


re: 
	fclean all

