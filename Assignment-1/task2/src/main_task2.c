#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#define MAX_LEN 34 /* maximal input string size */
                   /* enough to get 32-bit string + '\n' + null terminator */
extern int convertor(char *buf);

int main(int argc, char **argv)
{
  char buf[MAX_LEN];

  while (true)
  {
    fgets(buf, MAX_LEN, stdin); /* get user input string */
      if(strcmp(buf,"q\n") == 0) {
      break;
    }

    convertor(buf);
  } /* call your assembly function */

  return 0;
}