
#include <stdio.h>
int main()
{
int i, j;
char input[100];
printf("Enter a message to be sent using Hellschreiber:
");
scanf("%s", input);
for (i = 0; input[i] != '\0'; i++)
{
for (j = 7; j >= 0; j--)
{
if (input[i] & (1 << j))
{
printf("-.-");
}
else
{
printf(".-.");
}
}
}
return 0;
}
