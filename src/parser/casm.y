%{
	#include "casm.tab.h"
	#include <stdio.h>

	#define REG   1
	#define LABEL 2

	#define SR(V) V.type = REG
	#define SL(V) V.type = LABEL

	#define IR(V) V.type == REG
	#define IL(V) V.type == LABEL

	#define TP(A, B) ( A | ( B << 8 ) )

	#define YYERROR_VERBOSE

	int line = 0;

	int yyerror(const char* msg){
		printf("%s on line %d\n", msg, line);
		return 0;
	}
%}

%code requires{
	#include "scanner.h"
}

%union{
	struct{
		const char* sval;
		int         ival;
		int         type;
	}val;
}

%token TK_EOF 0

%token MOV
%token ADD SUB
%token AND OR NOT
%token JMP JGT JGE JLT JLE JNE JEQ

%token TK_LB TK_RB
%token TK_COMMA
%token TK_ASSIGN

%token <val> TK_LABEL
%token <val> TK_REG
%token <val> TK_NUM

%type <val> operand

%%

start:
	| mnemonics
	| start mnemonics
	;

mnemonics:
	  TK_LABEL[L]                     { fw_write("(%s)", $L.sval); }
	| TK_LABEL[L] TK_ASSIGN TK_NUM[N] { st_define($L.sval, $N.ival); }

	| MOV       operand[O]       TK_COMMA       TK_NUM[N]         {
		fw_write("@%d", $N.ival);
		fw_write("D=A");

		switch($O.type){
			case REG: fw_write("@%d", $O.ival); break;
			case LABEL:
				if($O.ival == -1) fw_write("@%s", $O.sval);
				else              fw_write("@%d", $O.ival);
				break;
		}

		fw_write("M=D");
	}
	| MOV TK_LB operand[O] TK_RB TK_COMMA       TK_NUM[N]         {
		fw_write("@%d", $N.ival);
		fw_write("D=A");

		switch($O.type){
			case REG:
				fw_write("@%d", $O.ival);
				fw_write("A=M");
				break;

			case LABEL:
				if($O.ival == -1) fw_write("@%s", $O.sval);
				else              fw_write("@%d", $O.ival);

				fw_write("A=M");
				break;
		}

		fw_write("M=D");
	}

	| MOV       operand[A]       TK_COMMA       operand[B]       {
		switch(TP($A.type, $B.type)){
			case TP(REG  , REG):
				fw_write("@%d", $B.ival);
				fw_write("D=M");
				fw_write("@%d", $A.ival);
				fw_write("M=D");
				break;
			case TP(LABEL, REG):
				fw_write("@%d", $B.ival);
				fw_write("D=M");
				
				if($A.ival == -1) fw_write("@%s", $A.sval);
				else              fw_write("@%d", $A.ival);

				fw_write("M=D");
				break;
			case TP(REG  , LABEL):
				if($B.ival == -1) fw_write("@%s", $B.sval);
				else              fw_write("@%d", $B.ival);

				fw_write("D=M");
				fw_write("@%d", $A.ival);
				fw_write("M=D");
				break;
			case TP(LABEL, LABEL):
				if($B.ival == -1) fw_write("@%s", $B.sval);
				else              fw_write("@%d", $B.ival);

				fw_write("D=M");

				if($A.ival == -1) fw_write("@%s", $A.sval);
				else              fw_write("@%d", $A.ival);

				fw_write("M=D");
				break;
		}
	}
	| MOV       operand[A]       TK_COMMA TK_LB operand[B] TK_RB {
		switch(TP($A.type, $B.type)){
			case TP(REG  , REG):
				fw_write("@%d", $B.ival);
				fw_write("A=M");
				fw_write("D=M");
				fw_write("@%d", $A.ival);
				fw_write("M=D");
				break;
			case TP(LABEL, REG):
				fw_write("@%d", $B.ival);
				fw_write("A=M");
				fw_write("D=M");
				
				if($A.ival == -1) fw_write("@%s", $A.sval);
				else              fw_write("@%d", $A.ival);

				fw_write("M=D");
				break;
			case TP(REG  , LABEL):
				if($B.ival == -1) fw_write("@%s", $B.sval);
				else              fw_write("@%d", $B.ival);

				fw_write("A=M");
				fw_write("D=M");
				fw_write("@%d", $A.ival);
				fw_write("M=D");
				break;
			case TP(LABEL, LABEL):
				if($B.ival == -1) fw_write("@%s", $B.sval);
				else              fw_write("@%d", $B.ival);

				fw_write("D=M");

				if($A.ival == -1) fw_write("@%s", $A.sval);
				else              fw_write("@%d", $A.ival);

				fw_write("M=D");
				break;
		}
	}
	| MOV TK_LB operand[A] TK_RB TK_COMMA       operand[B]       {
		switch(TP($A.type, $B.type)){
			case TP(REG  , REG):
				fw_write("@%d", $B.ival);
				fw_write("D=M");
				fw_write("@%d", $A.ival);
				fw_write("A=M");
				fw_write("M=D");
				break;
			case TP(LABEL, REG):
				fw_write("@%d", $B.ival);
				fw_write("D=M");
				
				if($A.ival == -1) fw_write("@%s", $A.sval);
				else              fw_write("@%d", $A.ival);

				fw_write("A=M");
				fw_write("M=D");
				break;
			case TP(REG  , LABEL):
				if($B.ival == -1) fw_write("@%s", $B.sval);
				else              fw_write("@%d", $B.ival);

				fw_write("D=M");
				fw_write("@%d", $A.ival);
				fw_write("A=M");
				fw_write("M=D");
				break;
			case TP(LABEL, LABEL):
				if($B.ival == -1) fw_write("@%s", $B.sval);
				else              fw_write("@%d", $B.ival);

				fw_write("D=M");

				if($A.ival == -1) fw_write("@%s", $A.sval);
				else              fw_write("@%d", $A.ival);

				fw_write("A=M");
				fw_write("M=D");
				break;
		}
	}
	| MOV TK_LB operand[A] TK_RB TK_COMMA TK_LB operand[B] TK_RB {
		switch(TP($A.type, $B.type)){
			case TP(REG  , REG):
				fw_write("@%d", $B.ival);
				fw_write("A=M");
				fw_write("D=M");
				fw_write("@%d", $A.ival);
				fw_write("A=M");
				fw_write("M=D");
				break;
			case TP(LABEL, REG):
				fw_write("@%d", $B.ival);
				fw_write("A=M");
				fw_write("D=M");
				
				if($A.ival == -1) fw_write("@%s", $A.sval);
				else              fw_write("@%d", $A.ival);

				fw_write("A=M");
				fw_write("M=D");
				break;
			case TP(REG  , LABEL):
				if($B.ival == -1) fw_write("@%s", $B.sval);
				else              fw_write("@%d", $B.ival);

				fw_write("A=M");
				fw_write("D=M");
				fw_write("@%d", $A.ival);
				fw_write("A=M");
				fw_write("M=D");
				break;
			case TP(LABEL, LABEL):
				if($B.ival == -1) fw_write("@%s", $B.sval);
				else              fw_write("@%d", $B.ival);

				fw_write("A=M");
				fw_write("D=M");

				if($A.ival == -1) fw_write("@%s", $A.sval);
				else              fw_write("@%d", $A.ival);

				fw_write("A=M");
				fw_write("M=D");
				break;
		}
	}

	| ADD operand[A] TK_COMMA operand[B] TK_COMMA TK_NUM[N]  {
		switch($B.type){
			case REG: fw_write("@%d", $B.ival); break;
			case LABEL:
				if($B.ival == -1) fw_write("@%s", $B.sval);
				else              fw_write("@%d", $B.ival);
				break;
		}

		fw_write("D=M");
		fw_write("@%d", $N.ival);
		fw_write("D=D+A");
		
		switch($A.type){
			case REG: fw_write("@%d", $A.ival); break;
			case LABEL:
				if($A.ival == -1) fw_write("@%s", $A.sval);
				else              fw_write("@%d", $A.ival);
				break;
		}

		fw_write("M=D");
	}
	| ADD operand[A] TK_COMMA operand[B] TK_COMMA operand[C] {
		switch($B.type){
			case REG: fw_write("@%d", $B.ival); break;
			case LABEL:
				if($B.ival == -1) fw_write("@%s", $B.sval);
				else              fw_write("@%d", $B.ival);
				break;
		}

		fw_write("D=M");

		switch($C.type){
			case REG: fw_write("@%d", $C.ival); break;
			case LABEL:
				if($C.ival == -1) fw_write("@%s", $C.sval);
				else              fw_write("@%d", $C.ival);
				break;
		}

		fw_write("D=D+M");

		switch($A.type){
			case REG: fw_write("@%d", $A.ival); break;
			case LABEL:
				if($A.ival == -1) fw_write("@%s", $A.sval);
				else              fw_write("@%d", $A.ival);
				break;
		}

		fw_write("M=D");
	}

	| SUB operand[A] TK_COMMA operand[B] TK_COMMA TK_NUM[N]  {
		switch($B.type){
			case REG: fw_write("@%d", $B.ival); break;
			case LABEL:
				if($B.ival == -1) fw_write("@%s", $B.sval);
				else              fw_write("@%d", $B.ival);
				break;
		}

		fw_write("D=M");
		fw_write("@%d", $N.ival);
		fw_write("D=D-A");
		
		switch($A.type){
			case REG: fw_write("@%d", $A.ival); break;
			case LABEL:
				if($A.ival == -1) fw_write("@%s", $A.sval);
				else              fw_write("@%d", $A.ival);
				break;
		}

		fw_write("M=D");
	}
	| SUB operand[A] TK_COMMA TK_NUM[N]  TK_COMMA operand[C] {
		switch($C.type){
			case REG: fw_write("@%d", $C.ival); break;
			case LABEL:
				if($C.ival == -1) fw_write("@%s", $C.sval);
				else              fw_write("@%d", $C.ival);
				break;
		}

		fw_write("D=M");
		fw_write("@%d", $N.ival);
		fw_write("D=A-D");
		
		switch($A.type){
			case REG: fw_write("@%d", $A.ival); break;
			case LABEL:
				if($A.ival == -1) fw_write("@%s", $A.sval);
				else              fw_write("@%d", $A.ival);
				break;
		}

		fw_write("M=D");
	}
	| SUB operand[A] TK_COMMA operand[B] TK_COMMA operand[C] {
		switch($B.type){
			case REG: fw_write("@%d", $B.ival); break;
			case LABEL:
				if($B.ival == -1) fw_write("@%s", $B.sval);
				else              fw_write("@%d", $B.ival);
				break;
		}

		fw_write("D=M");

		switch($C.type){
			case REG: fw_write("@%d", $C.ival); break;
			case LABEL:
				if($C.ival == -1) fw_write("@%s", $C.sval);
				else              fw_write("@%d", $C.ival);
				break;
		}

		fw_write("D=D-M");

		switch($A.type){
			case REG: fw_write("@%d", $A.ival); break;
			case LABEL:
				if($A.ival == -1) fw_write("@%s", $A.sval);
				else              fw_write("@%d", $A.ival);
				break;
		}

		fw_write("M=D");
	}

	| AND operand[A] TK_COMMA operand[B] TK_COMMA TK_NUM[N]  {
		switch($B.type){
			case REG: fw_write("@%d", $B.ival); break;
			case LABEL:
				if($B.ival == -1) fw_write("@%s", $B.sval);
				else              fw_write("@%d", $B.ival);
				break;
		}

		fw_write("D=M");
		fw_write("@%d", $N.ival);
		fw_write("D=D&A");
		
		switch($A.type){
			case REG: fw_write("@%d", $A.ival); break;
			case LABEL:
				if($A.ival == -1) fw_write("@%s", $A.sval);
				else              fw_write("@%d", $A.ival);
				break;
		}

		fw_write("M=D");
	}
	| AND operand[A] TK_COMMA operand[B] TK_COMMA operand[C] {
		switch($B.type){
			case REG: fw_write("@%d", $B.ival); break;
			case LABEL:
				if($B.ival == -1) fw_write("@%s", $B.sval);
				else              fw_write("@%d", $B.ival);
				break;
		}

		fw_write("D=M");

		switch($C.type){
			case REG: fw_write("@%d", $C.ival); break;
			case LABEL:
				if($C.ival == -1) fw_write("@%s", $C.sval);
				else              fw_write("@%d", $C.ival);
				break;
		}

		fw_write("D=D&M");

		switch($A.type){
			case REG: fw_write("@%d", $A.ival); break;
			case LABEL:
				if($A.ival == -1) fw_write("@%s", $A.sval);
				else              fw_write("@%d", $A.ival);
				break;
		}

		fw_write("M=D");
	}

	| OR  operand[A] TK_COMMA operand[B] TK_COMMA TK_NUM[N]  {
		switch($B.type){
			case REG: fw_write("@%d", $B.ival); break;
			case LABEL:
				if($B.ival == -1) fw_write("@%s", $B.sval);
				else              fw_write("@%d", $B.ival);
				break;
		}

		fw_write("D=M");
		fw_write("@%d", $N.ival);
		fw_write("D=D|A");
		
		switch($A.type){
			case REG: fw_write("@%d", $A.ival); break;
			case LABEL:
				if($A.ival == -1) fw_write("@%s", $A.sval);
				else              fw_write("@%d", $A.ival);
				break;
		}

		fw_write("M=D");
	}
	| OR  operand[A] TK_COMMA operand[B] TK_COMMA operand[C] {
		switch($B.type){
			case REG: fw_write("@%d", $B.ival); break;
			case LABEL:
				if($B.ival == -1) fw_write("@%s", $B.sval);
				else              fw_write("@%d", $B.ival);
				break;
		}

		fw_write("D=M");

		switch($C.type){
			case REG: fw_write("@%d", $C.ival); break;
			case LABEL:
				if($C.ival == -1) fw_write("@%s", $C.sval);
				else              fw_write("@%d", $C.ival);
				break;
		}

		fw_write("D=D|M");

		switch($A.type){
			case REG: fw_write("@%d", $A.ival); break;
			case LABEL:
				if($A.ival == -1) fw_write("@%s", $A.sval);
				else              fw_write("@%d", $A.ival);
				break;
		}

		fw_write("M=D");
	}

	| NOT operand[A] TK_COMMA TK_NUM[N]  {
		fw_write("@%d", $N.ival);
		fw_write("D=!A");
		
		switch($A.type){
			case REG: fw_write("@%d", $A.ival); break;
			case LABEL:
				if($A.ival == -1) fw_write("@%s", $A.sval);
				else              fw_write("@%d", $A.ival);
				break;
		}

		fw_write("M=D");
	}
	| NOT operand[A] TK_COMMA operand[B] {
		switch($B.type){
			case REG: fw_write("@%d", $B.ival); break;
			case LABEL:
				if($B.ival == -1) fw_write("@%s", $B.sval);
				else              fw_write("@%d", $B.ival);
				break;
		}

		fw_write("D=!M");

		switch($A.type){
			case REG: fw_write("@%d", $A.ival); break;
			case LABEL:
				if($A.ival == -1) fw_write("@%s", $A.sval);
				else              fw_write("@%d", $A.ival);
				break;
		}

		fw_write("M=D");
	}

	| JGT TK_LABEL[L] {
		fw_write("@%s", $L.sval);
		fw_write("D;JGT");
	}
	| JGE TK_LABEL[L] {
		fw_write("@%s", $L.sval);
		fw_write("D;JGE");
	}
	| JLT TK_LABEL[L] {
		fw_write("@%s", $L.sval);
		fw_write("D;JLT");
	}
	| JLE TK_LABEL[L] {
		fw_write("@%s", $L.sval);
		fw_write("D;JLE");
	}
	| JNE TK_LABEL[L] {
		fw_write("@%s", $L.sval);
		fw_write("D;JNE");
	}
	| JEQ TK_LABEL[L] {
		fw_write("@%s", $L.sval);
		fw_write("D;JEQ");
	}
	| JMP TK_LABEL[L] {
		fw_write("@%s", $L.sval);
		fw_write("0;JMP");
	}
	;

operand:
	  TK_REG[R]   { $$ = $R; SR($$); }
	| TK_LABEL[L] {
		$$.ival = st_resolve($L.sval);
		$$.sval = $L.sval;
		SL($$);
	}
	;