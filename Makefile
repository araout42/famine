ASM = nasm
OUTPUT=death
SRC=srcs/death.s
OBJ=$(SRC:.s=.o)
FLAG=-f elf64
LD_FLAG= --discard-all
LINK=ld

all:$(OUTPUT)


$(OUTPUT): $(OBJ)
	$(LINK) $(LD_FLAG) $^ -o $(OUTPUT)

%.o: %.s
	nasm -f elf64 $< -o $@


clean:
	@/bin/rm  -f *.o 2>/dev/null

fclean: clean
	@/bin/rm -f $(OUTPUT) 2>/dev/null

re: fclean all

