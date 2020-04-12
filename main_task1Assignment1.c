#include <stdio.h>


extern void assFunc(int x, int y);
char c_checkValidity(int x, int y)
{
    if (x >= y){return 1;}
    return 0;
}

int main(int argc, char *argv[])
{
    char buffer[1024];
    int num1,num2 = 0;
    fgets(buffer,1024,stdin);
    sscanf(buffer, "%d",&num1);
    fgets(buffer,1024,stdin);
    sscanf(buffer,"%d", &num2);
    assFunc(num1,num2);
 
}