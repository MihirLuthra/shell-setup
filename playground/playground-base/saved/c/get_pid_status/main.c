#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char *argv[])
{

  printf("%d\n", getpid());
  while(1);
  return EXIT_SUCCESS;
}
