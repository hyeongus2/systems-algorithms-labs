/* Minimal POSIX command runner, maintained from EE485A Assignment 11.
 * Whitespace-delimited arguments only; no quoting, pipe, or redirection.
 */
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

enum { LINE_CAPACITY = 2000, MAX_ARGS = 64 };

int main(void)
{
    char command[LINE_CAPACITY];
    char *arguments[MAX_ARGS + 1];

    while (fgets(command, sizeof(command), stdin) != NULL) {
        char *newline = strchr(command, '\n');
        if (newline) {
            *newline = '\0';
        } else if (!feof(stdin)) {
            int next = fgetc(stdin);
            if (next != '\n' && next != EOF) {
                while ((next = fgetc(stdin)) != '\n' && next != EOF) {}
                fprintf(stderr, "command line too long\n");
                continue;
            }
        }

        size_t count = 0;
        char *token = strtok(command, " \t\r");
        while (token && count < MAX_ARGS) {
            arguments[count++] = token;
            token = strtok(NULL, " \t\r");
        }
        if (token) {
            fprintf(stderr, "too many arguments (maximum %d)\n", MAX_ARGS);
            continue;
        }
        arguments[count] = NULL;
        if (count == 0) continue;
        if (strcmp(arguments[0], "exit") == 0) return EXIT_SUCCESS;

        pid_t child = fork();
        if (child < 0) {
            perror("fork");
            continue;
        }
        if (child == 0) {
            execvp(arguments[0], arguments);
            perror(arguments[0]);
            _exit(127);
        }
        while (waitpid(child, NULL, 0) < 0) {
            if (errno != EINTR) {
                perror("waitpid");
                break;
            }
        }
    }
    if (ferror(stdin)) {
        perror("stdin");
        return EXIT_FAILURE;
    }
    return EXIT_SUCCESS;
}
