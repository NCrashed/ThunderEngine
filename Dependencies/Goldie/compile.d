#!/usr/bin/rdmd
/// Скрипт автоматической компиляции проекта под Linux и Windows
/** 
 * Очень важно установить пути к зависимостям (смотри дальше), 
 */
module compile;

import dmake;

import std.stdio;
import std.process;

string[string] depends;

static this()
{
	depends["semitwist"] = "../SemiTwistDTools";
}

void compileSemiTwist(string libPath)
{
	system("cd "~libPath~" && rdmd compile.d all release");
}

//======================================================================
//							Основная часть
//======================================================================
int main(string[] args)
{
	// Клиент
	addCompTarget("goldie", "./bin", "goldie", BUILD.LIB);
	setDependPaths(depends);
	addSource("src/goldie");
	addSingleFile("src/tools/util.d");

	addLibraryFiles("semitwist", "bin", ["semitwist"], ["src"], &compileSemiTwist);

	checkProgram("dmd", "Cannot find dmd to compile project! You can get it from http://dlang.org/download.html");
	// Компиляция!
	return proceedCmd(args);
}