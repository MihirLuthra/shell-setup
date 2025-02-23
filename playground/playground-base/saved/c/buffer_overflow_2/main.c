#include <stdio.h>
#include <string.h>

struct data {
    char buffer[64];
    int authorized;
};

void secret_function() {
    printf("You have accessed the secret function!\n");
}

void regular_function() {
    printf("This is the regular function.\n");
}

int main() {
    struct data user;
    user.authorized = 0;

    printf("Enter some text: ");
    gets(user.buffer);  // Vulnerable function

    if (user.authorized) {
        secret_function();
    } else {
        regular_function();
    }

    return 0;
}

