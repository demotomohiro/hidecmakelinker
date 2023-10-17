# hidecmakelinker
hidecmakelinker is a tool to use C/C++ libraries using CMake from Nim programming language.
It was created to use Raspberry Pi Pico SDK from Nim but hidecmakelinker is written so that it can be used for other C/C++ projects using CMake and it doesn't contains any Raspberry Pi Pico specific code.
But it doesn't mean I recommend you to use it for any CMake projects. If you can use C/C++ libraries from Nim just by setting header files and libraries, you don't need to use hidecmakelinker. Use it only when using C/C++ libraries without writing CMake file is hard like Raspberry Pi Pico SDK.


## Requirements
- Nim 2.0.0
  - Nimble is not required!
- pathX
- CMake 3.13 or newer


## How to install
Make sure that hidecmakelinker and void is in one of the directory in PATH environment variable and you can call them from console.


## How to use
Create `config.nims` in the same directory as your `*.nim` files and write following content:
```nim
switch("gcc.linkerexe", "hidecmakelinker")
switch("gcc.cpp.linkerexe", "hidecmakelinker")
switch("gcc.exe", "void")
switch("gcc.cpp.exe", "void")
nimcacheDir().mkDir()
```

If you use backend compiler other than gcc, you need to change 'gcc' with the compiler name you use.
And Nim's backend compiler must be same to C/C++ compiler called by CMake.

In the main module (when you compile Nim code with `nim c foo.nim`, `foo.nim` is a main module), add following code:
```nim
import hidecmakelinkerpkg/libconf

# Call this template after importing all modules.
writeHideCMakeToFile()
```

Then, you can build `*.nim` file with `nim c foo.nim` or `nim cpp foo.nim`.


## How to wrap C/C++ libraries for hidecmakelinker
In the Nim module that wrap C/C++ libraries, import `hidecmakelinkerpkg/libconf` module, create `LibParams` object by calling `initLibParams` and pass it to `config` template.
`LibParams` object contains information to generate `CMakeLists.txt` so that C/C++ libraries are linked to Nim code.

All parameters of `initLibParams` are optional.
List of parameters of `initLibParams`:
- `backendLang: BackendLang = blC`
  - Set `blCpp` when wrapping C++ libraries so that Nim code is compiled with C++ backend
- `cmakeProgLangs: set[CMakeProgLang] = {cmplC, cmplCXX}`
  - Selects which programming languages (excepts Nim) are needed to build the project
  - Some Raspberry Pi Pico related libraries requires `cmplASM`
  - They are added to `project` command as LANGUAGES option in generated CMakeLists.txt. See: https://cmake.org/cmake/help/latest/command/project.html
- `linkLibraries: openArray[string] = []`
  - Library names used in CMakeLists.txt
  - They are linked to Nim generated C/C++ code with `target_link_libraries` CMake command
- `cmakeStmts: openArray[(string, CMakeStmt)] = []`
  - Adds CMake commands to generated CMakeLists.txt
  - `CMakeStmt` have `name, depend: string`
    - `name` can be any string but doesn't start with "std." as it is reserved by hidecmakelinker
    - `depend` must be one of `cmakeStmts`'s `name` or names predefined by hidecmakelinker
      - If `depend` is `foo`, it is inserted to `CMakeLists.txt` after `CMakeStmt` that has `name` match to `foo` was inserted
      - `depend` can refer to any name in other imported module
    - If `name` is empty string, `cmakesStmts`'s `depend` cannot refer to it
    - If `depend` is empty string, it is inserted to `CMakeLists.txt` as soon as possible.
    - When the CMake command must be placed after `project` CMake command, set `std.project` to `depend`
  - Following procedures creates a CMake command
    - `initCMakeInclude*(path: string; name = "", depend = ""): (string, CMakeStmt)`
      - Generates `include` command
      - https://cmake.org/cmake/help/latest/command/include.html
    - `initCMakeCmd*(cmd: string; name = "", depend = ""): (string, CMakeStmt) =`
      - Generates any CMake command specified by `cmd`
    - `initCMakeCmdWithTarget*(cmd: string; name = "", depend = ""): (string, CMakeStmt) =`
      - Generates any CMake command specified by `cmd` that refer to CMake target corresponding to Nim main module
      - For example, if `cmd` is `pico_add_extra_outputs(#target)` and target name was `mynimcode`, it inserts `pico_add_extra_outputs(mynimcode)` in `CMakeLists.txt` after that target was defined


## How it works
At compile time, imported Nim modules wrapping C/C++ libraries tells information that is used to generated `CMakeLists.txt`.
It is done by putting that information (library target names, CMake commands, whether it requires C++ compiler or etc) to `LibParams` object and pass it to `config` template in libconf module.
They are gathered and saved to the file in nimcache directory when `writeHideCMakeToFile` template is called in main module.

After Nim executes compile time code and generates C/C++ code, Nim compiler trys to call backend C or C++ compiler to compile them.
But backend compiler executable name is replaced to `void` in `config.nims` so that backend compiler is not called and nothing happens. Nim generated C/C++ code are compiled by CMake later.
(So `void` can be any programs)

Then Nim compiler calls backend linker, but it is also replaced to hidecmakelinker in `config.nims`.
hidecmakelinker gets same arguments as backend linker called by Nim.
So hidecmakelinker can get a list of all C/C++ files that is needed to generating `CMakeLists.txt`.
It also read the file created by `writeHideCMakeToFile`.
Then, hidecmakelinker generates `CMakeLists.txt` in Nim cache directory and call CMake to build the project.
All temporary files are in Nim cache directory.
`CMakeLists.txt` is generated everytime you run `nim c foo.nim`, but build time can be shorter next time because CMake reuses compiled object files.
