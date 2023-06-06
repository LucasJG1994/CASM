cmake_minimum_required(VERSION 2.8.11)
project(casm)

include_directories(
	src
	src/parser
)

add_executable(casm
	src/main.c
	
	src/parser/scanner.cpp
	src/parser/casm.tab.c

	src/parser/scanner.h
	src/parser/casm.tab.h
	
	src/parser/casm.y
)