#include "stdio.h"
#include "x86.h"

void putc(char c)
{
    x86_Video_TeletypeOutput(c, 0);
}

void puts(const char *s)
{
    while (*s) {    // (*s) is false when '\0' is reached
        putc(*s++);
    }
}