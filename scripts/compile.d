#!/usr/bin/rdmd
/// Скрипт автоматической компиляции проекта под Linux и Windows
/** 
 * Очень важно установить пути к зависимостям (смотри дальше), 
 */
module compile;

import dmake;

import std.stdio;
import std.process;

// Здесь прописать пути к зависимостям клиента
string[string] clientDepends;

// Зависимости сервера
string[string] serverDepends;

// Список либ от Derelict3
string[] derelictLibs;

version(X86)
	enum MODEL = "32";
version(X86_64)
	enum MODEL = "64";

static this()
{
	clientDepends =
	[
		"Derelict3": "../Dependencies/Derelict3",
		"GLFW3": "../Dependencies/GLFW3",
		"FreeImage": "../Dependencies/FreeImage",
		"Goldie": "../Dependencies/Goldie",
		"SemiTwistDTools": "../Dependencies/SemiTwistDTools",
	];

	derelictLibs =
	[
		"DerelictGL3",
		"DerelictGLFW3",
		"DerelictUtil",
		"DerelictFI",
	];

	
	serverDepends =
	[
		"Goldie": "../Dependencies/Goldie",
		"SemiTwistDTools": "../Dependencies/SemiTwistDTools",
	];
}

void compileFreeImage(string libPath)
{
	writeln("Building FreeImage...");

	version(linux)
	{
		system("cd "~libPath~` && make -f Makefile.fip`);
		system("cp "~libPath~"/libfreeimageplus-3.15.4.so "~getCurrentTarget().outDir~`/libfreeimage.so`);
	}
	version(Windows)
	{
		checkProgram("make", "Cannot find MinGW to build FreeImage! You can build manualy with Visual Studio and copy FreeImage.dll to output folder or get MinGW from http://www.mingw.org/wiki/Getting_Started");
		system("cd "~libPath~` && make -fMakefile.mingw`);
		system("copy "~libPath~"\\FreeImage.dll "~getCurrentTarget().outDir~"\\FreeImage.dll");
	}
}

void compileGLFW3(string libPath)
{
	writeln("Building GLFW3...");
	version(linux)
	{
		checkProgram("cmake", "Cannot find CMake to build GLFW3! You can get it from http://www.cmake.org/cmake/resources/software.html");
		system("cd "~libPath~` && cmake -D BUILD_SHARED_LIBS=ON ./`);
		system("cd "~libPath~` && make`);
		system("cp "~libPath~`/src/libglfw.so `~getCurrentTarget().outDir~`/libglfw.so`);
	}
	version(Windows)
	{
		checkProgram("cmake", "Cannot find CMake to build GLFW3! You can get it from http://www.cmake.org/cmake/resources/software.html");
		checkProgram("make", "Cannot find MinGW to build GLFW3! You can build manualy with GLFW3 and copy glfw.dll to output folder or get MinGW from http://www.mingw.org/wiki/Getting_Started");
		system("cd "~libPath~` & cmake -D BUILD_SHARED_LIBS=ON -G "MinGW Makefiles" .\`);
		system("cd "~libPath~` & make`);
		system("copy "~libPath~`\src\glfw3.dll `~getCurrentTarget().outDir~`\glfw3.dll`);
	}
}

void compileGoldie(string libPath)
{
	writeln("Building Goldie...");
	system("cd "~libPath~" && rdmd compile.d all debug");
}

void compileSemiTwistDTools(string libPath)
{
	writeln("Building SemiTwistDTools...");
	system("cd "~libPath~" && rdmd compile.d all release");
}

string compileMDLGrammar()
{
	version(Windows)
		return "cd ..\\src && echo Building mdl grammar... && ..\\Dependencies\\Goldie\\bin\\goldie-grmc util\\mdl\\mdl.grm && ..\\Dependencies\\Goldie\\bin\\goldie-staticlang mdl.cgt --pack=util.mdl.mdlparser";
	version(linux)
		return "cd ../src && echo Building mdl grammar... && ../Dependencies/Goldie/bin/goldie-grmc util/mdl/mdl.grm && ../Dependencies/Goldie/bin/goldie-staticlang mdl.cgt --pack=util.mdl.mdlparser";		
}

void cleanupMDLParser()
{
	writeln("Removing old mdl parser...");
	version(Windows)
		system("del /q ..\\src\\util\\mdl\\mdlparser");
	version(linux)
		system("rm -rf ../src/util/mdl/mdlparser");
}

//======================================================================
//							Основная часть
//======================================================================
int main(string[] args)
{
	// Cleaning
	cleanupMDLParser();

	// Клиент
	addCompTarget("client", "../bin", "ThunderClient", BUILD.APP);
	setDependPaths(clientDepends);

	addLibraryFiles("Derelict3", "lib", derelictLibs, ["import"], 
		(string libPath)
		{
			writeln("Building Derelict3 lib...");
			version(Windows)
				system("cd "~libPath~`/build && dmd build.d && build.exe`);
			version(linux)
				system("cd "~libPath~`/build && dmd build.d && ./build`);	
		});

	addLibraryFiles("SemiTwistDTools", "bin", ["semitwist"], ["src"], &compileSemiTwistDTools);
	addLibraryFiles("Goldie", "bin", ["goldie"], ["src"], &compileGoldie);
	
	checkSharedLibraries("GLFW3", ["glfw3"], &compileGLFW3);
	checkSharedLibraries("FreeImage", ["freeimage"], &compileFreeImage);

	addCustomCommand(&compileMDLGrammar);
	addGeneratedSources("../src/util/mdl/mdlparser");

	addSource("../src/client");
	addSource("../src/util");

	addCustomFlags("-D -Dd../docs ../docs/candydoc/candy.ddoc ../docs/candydoc/modules.ddoc -version=CL_VERSION_1_1");

	// Сервер
	addCompTarget("server", "../bin", "ThunderServer", BUILD.APP);
	setDependPaths(serverDepends);

	addLibraryFiles("SemiTwistDTools", "bin", ["semitwist"], ["src"], &compileSemiTwistDTools);
	addLibraryFiles("Goldie", "bin", ["goldie"], ["src"], &compileGoldie);

	addCustomCommand(&compileMDLGrammar);
	addGeneratedSources("../src/util/mdl/mdlparser");

	addSource("../src/server");
	addSource("../src/util");

	addCustomFlags("-D -Dd../docs ../docs/candydoc/candy.ddoc ../docs/candydoc/modules.ddoc");

	checkProgram("dmd", "Cannot find dmd to compile project! You can get it from http://dlang.org/download.html");
	// Компиляция!
	return proceedCmd(args);
}