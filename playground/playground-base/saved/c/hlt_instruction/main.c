#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[])
{
  asm volatile("hlt;");
  return EXIT_SUCCESS;
}
