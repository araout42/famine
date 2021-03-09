# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: araout <marvin@42.fr>                      +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2020/10/01 04:38:21 by araout            #+#    #+#              #
#    Updated: 2021/01/11 17:14:35 by araout           ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

SRC_NAME = main.c elf_64.c\

SRC_ASM = \

OBJ_NAME = $(SRC_NAME:.c=.o)
OBJ_ASM = $(SRC_ASM:.s=.o)

NAME = famine

SRC_PATH = ./srcs/
OBJ_PATH = ./obj/

LIBFT = libft

LIB = $(LIBFT)/libft.a

CC = gcc
CFLAGS = -Wall -Werror -Wextra $(INCLUDES)


INCLUDES = -Iincludes -I$(LIBFT)

CLIBS =

AC = nasm
AFLAGS = -f elf64

SRC = $(addprefix $(SRC_PATH),$(SRC_NAME))
OBJ = $(addprefix $(OBJ_PATH),$(OBJ_NAME))
INC = $(addprefix -I,$(INC_PATH))

SRCA = $(addprefix $(SRC_PATH),$(SRC_ASM))
OBJA = $(addprefix $(OBJ_PATH),$(OBJ_ASM))


$(NAME): $(OBJ)
	$(CC) $(CFLAGS) -o $(NAME) $(OBJ) $(CLIBS)

all: $(NAME)

$(OBJ_PATH)%.o: $(SRC_PATH)%.c
	@mkdir $(OBJ_PATH) 2> /dev/null || echo "" > /dev/null
	$(CC) $(CFLAGS) $(INC) -o $@ -c $<

$(OBJ_PATH)%.o: $(SRC_PATH)%.s
	$(AC) $(AFLAGS) -o $@ $<

clean:
	rm -f $(OBJ)
ifneq ($(OBJ_PATH), ./)
	rm -rf $(OBJ_PATH)
endif

fclean: clean
	rm -f $(NAME)

mrproper: fclean

re: fclean all

.PHONY: all clean fclean mrproper re
