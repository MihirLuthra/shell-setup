#include <stdlib.h>
#include <fcntl.h>

int main() {
  int ret = open(NULL, 0);
  printf("%s", perror("open"));
  return 0;
}
