#include <stdio.h>
#include <stdlib.h>

#include "scanner.h"
#include "casm.tab.h"

int main() {
	fw_init();

	FILE* fp;
	if (fopen_s(&fp, "test/test.casm", "rb") != 0) {
		printf("Failed to allocate memory...\n");
		fw_close();
		return 0;
	}

	fseek(fp, 0L, SEEK_END);
	long len = ftell(fp);
	fseek(fp, 0L, SEEK_SET);

	char* buffer = (char*)calloc(len + 1, sizeof(char));
	if (buffer == NULL) {
		fclose(fp);
		fw_close();
		return 0;
	}

	fread(buffer, sizeof(char), len, fp);
	fclose(fp);

	yy_init(buffer);
	yyparse();

	fw_close();
	return 0;
}