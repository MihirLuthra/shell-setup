#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[])
{
  FILE *file;
  char buffer[1000];
  file = fopen("/proc/self/status", "r");

  if (file == NULL) {
    perror("Error opening file");
    return EXIT_FAILURE;
  }

  while (fgets(buffer, sizeof(buffer), file) != NULL) {
    printf("%s", buffer);
  }

  fclose(file);
  return EXIT_SUCCESS;
}
