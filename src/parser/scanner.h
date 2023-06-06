#ifndef __scanner__h
#define __scanner__h

#if __cplusplus
extern "C" {
#endif


void yy_init(const char* source);
int  yylex();

/////////////////////////
// Symbol Table Module //
/////////////////////////

void st_define(const char* name, int offset);
int st_resolve(const char* name);

////////////////////////
// File Writer Module //
////////////////////////

void fw_init();
void fw_write(const char* fmt, ...);
void fw_close();

#if __cplusplus
}
#endif

#endif