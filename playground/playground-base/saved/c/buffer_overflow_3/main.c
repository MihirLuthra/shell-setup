#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main() {
    size_t size;
    char *input = "Example data that exceeds allocated space.";
    unsigned int userInput = ~((unsigned int)0) - 9;
    printf("%u\n", userInput);
    size = userInput + 11; // Overflow occurs, wraps around to 9
    printf("%zu\n", size);
  //
    char *buffer = malloc(size); // Allocates a smaller buffer than needed
    strcpy(buffer, input); // Potential buffer overflow because buffer is too small
    free(buffer);
    return 0;
}
