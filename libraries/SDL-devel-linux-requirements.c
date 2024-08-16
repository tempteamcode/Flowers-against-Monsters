
#include <stdlib.h>
#include <string.h>

char *__strdup(const char *str) {
	size_t size = strlen(str) + 1;
	char *dup = malloc(size);
	if (dup != NULL) memcpy(dup, str, size);
	return dup;
}
