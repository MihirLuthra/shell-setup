#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[])
{
  char buffer3[4];
  char buffer2[12];
  char buffer[4];

  gets(buffer);
  // fgets(buffer2, 5, stdin);

  printf("buffer = %s, buffer2 = %s, buffer3 = %s", buffer, buffer2, buffer3);

  return EXIT_SUCCESS;
}
