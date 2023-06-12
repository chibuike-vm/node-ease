#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct UFWDATA 
{
	char firstData[50];	
	char secondData[50];
};

int main(void)
{
	struct UFWDATA ufwData;
	int ssRet;
	char counter = 1, buffer[100];

	FILE *file = fopen("logfile.txt", "w+");
	
	system("sudo ufw status > logfile.txt");

	while (fgets(buffer, 100, file) != NULL)
	{
		ssRet = sscanf(buffer, "%s %s", ufwData.firstData, ufwData.secondData);

		if (ssRet == 0)
		{
			exit(1);
		}
	}
	
	if (strcmp(ufwData.secondData, "inactive") == 0)
	{
		system("sudo ufw enable");
		system("sudo ufw allow 22");
		system("sudo ufw allow 1789");
		system("sudo ufw allow 1790");
		system("sudo ufw allow 8000");
		system("sudo ufw allow 80");
		system("sudo ufw allow 443/tcp");
	}

	return(0);
}
