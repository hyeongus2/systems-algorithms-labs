/* Insertion-sort debugging exercise, maintained from the 2021 submission.
 * Usage: insertion_sort INTEGER ... (at most 10 values)
 */
#include <errno.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>

enum { CAPACITY = 10 };
static int x[CAPACITY], y[CAPACITY], num_inputs, num_y;

static int get_args(int argc, char **argv)
{
    if (argc - 1 > CAPACITY) {
        fprintf(stderr, "at most %d integers are supported\n", CAPACITY);
        return 0;
    }
    num_inputs = argc - 1;
    for (int i = 0; i < num_inputs; ++i) {
        char *end;
        errno = 0;
        long value = strtol(argv[i + 1], &end, 10);
        if (errno == ERANGE || end == argv[i + 1] || *end != '\0' ||
            value < INT_MIN || value > INT_MAX) {
            fprintf(stderr, "invalid integer: %s\n", argv[i + 1]);
            return 0;
        }
        x[i] = (int)value;
    }
    return 1;
}

static void scoot_over(int position)
{
    for (int k = num_y; k > position; --k)
        y[k] = y[k - 1];
}

static void insert(int value)
{
    for (int j = 0; j < num_y; ++j) {
        if (value < y[j]) {
            scoot_over(j);
            y[j] = value;
            return;
        }
    }
    y[num_y] = value;
}

int main(int argc, char **argv)
{
    if (!get_args(argc, argv)) return EXIT_FAILURE;
    for (num_y = 0; num_y < num_inputs; ++num_y) insert(x[num_y]);
    for (int i = 0; i < num_inputs; ++i) printf("%d\n", y[i]);
    return EXIT_SUCCESS;
}
