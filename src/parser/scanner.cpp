#include "scanner.h"

#include <string>
#include <map>

extern "C" {
#include "casm.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
extern int line;
}

static const char* src;
static const char* cur;
static const char* begin;

static std::map<std::string, int> keywords = {
	{"mov", MOV},
	{"add", ADD},
	{"sub", SUB},
	{"and", AND},
	{"or" , OR },
	{"not", NOT},
	{"jmp", JMP},
	{"jgt", JGT},
	{"jge", JGE},
	{"jlt", JLT},
	{"jle", JLE},
	{"jne", JNE},
	{"jeq", JEQ}
};

static void adv() { cur++; }
static char peek() { return cur[1]; }
static bool match(char c) { return *cur == c; }
static bool end() { return *cur == 0; }

static bool is_digit(char c) { return c >= '0' && c <= '9'; }
static bool is_alpha(char c) { return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_'; }

static bool is_number(std::string s) {
	if(s.length() == 0) return false;
	
	for (char c : s) {
		if(is_digit(c) == 0) return false;
	}

	return true;
}

static bool is_id(std::string s) {
	if(s.length() == 0) return false;
	if(is_alpha(s[0])) return true;
	return false;
}

static bool is_reg(std::string s) {
	if(s.length() <= 1) return false;

	std::string n = s.substr(1, s.length());
	if(is_number(n)) return true;
	return false;
}

static std::string get_lex() {
	std::string tmp = std::string(begin, cur - begin);
	tmp[tmp.length()] = 0;
	return tmp;
}

extern "C" void yy_init(const char* source) {
	src = source;
	cur = source;
	begin = source;
	line = 1;
}

extern "C" int yylex() {
	if(end()) return TK_EOF;

	while (end() == 0) {
		switch (*cur) {
			case '[': { adv(); return TK_LB; }
			case ']': { adv(); return TK_RB; }
			case '=': { adv(); return TK_ASSIGN; }
			case ',': { adv(); return TK_COMMA; }
			case ';': {
				while (match('\n') == 0) {
					if(end()) break;
					adv();
				}
				break;
			}
			case ' ':
			case '\t':
			case '\r': adv(); break;
			case '\n': line++; adv(); break;
			default: {
				begin = cur;
				while (is_alpha(*cur) || is_digit(*cur)) {
					if(end()) break;
					adv();
				}

				std::string lex = get_lex();

				if (is_number(lex)) {
					yylval.val.ival = std::atoi(lex.c_str());
					return TK_NUM;
				}

				if (is_reg(lex)) {
					yylval.val.ival = std::atoi((lex.substr(1, lex.length())).c_str());
					return TK_REG;
				}

				if(keywords.find(lex) != keywords.end()) return keywords[lex];

				if (is_id(lex)) {
					char* buffer = (char*)calloc(lex.length() + 1, sizeof(char));
					if (buffer == NULL) {
						printf("Failed to allocate memory...\n");
						return TK_EOF;
					}

					memcpy(buffer, lex.c_str(), lex.length());
					yylval.val.sval = buffer;
					return TK_LABEL;
				}

				return TK_EOF;
			}
		}
	}

	return TK_EOF;
}

/////////////////////////
// Symbol Table Module //
/////////////////////////

static std::map<std::string, int> decl_labels;

extern "C" void st_define(const char* name, int offset) {
	std::string tmp = std::string(name);
	decl_labels[tmp] = offset;
}

extern "C" int st_resolve(const char* name) {
	std::string tmp = std::string(name);
	if(decl_labels.find(tmp) == decl_labels.end()) return -1;

	return decl_labels[tmp];
}

////////////////////////
// File Writer Module //
////////////////////////

static FILE* fp;

extern "C" void fw_init() {
	if (fopen_s(&fp, "test/test.hack", "wb") != 0) {
		fp = nullptr;
		return;
	}
}


extern "C" void fw_write(const char* fmt, ...) {
	if(fp == nullptr) return;
	va_list arg;

	va_start(arg, fmt);
	long len = vsnprintf(NULL, 0, fmt, arg);
	char* buffer = new char[len + 1];
	if (buffer == nullptr) {
		va_end(arg);
		return;
	}

	vsprintf(buffer, fmt, arg);
	va_end(arg);

	std::string tmp = std::string(buffer);
	tmp += "\n";

	delete[] buffer;
	fwrite(tmp.c_str(), sizeof(char), tmp.length(), fp);
}

extern "C" void fw_close() {
	if(fp == nullptr) return;
	fclose(fp);
}