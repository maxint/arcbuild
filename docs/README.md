# Documents of ArcBuild

- [ArcSoft SDK Building](ArcSoftSDKBuilding.md)
- [Arguments for Platforms](PlatformArguments.md)


## Usage:

```
cmake -P arcbuild.cmake [(-D<var>=<value>)...] [<path-to-source>]
```


## Arguments for `cmake -P arcbuild.cmake`

```cmake
PLATFORM        # [REQUIRED] target platform, e.g. android, ios, vs2015, etc.
ARCH            # target architectures, e.g. armv7-a, "armv7;armv7s;arm64", etc.
STL             # select STL used by Android NDK (system, {gabi++,gnustl,c++,stlport}_{static|shared})
TOOLCHAIN       # select toolchain used by Android NDK (clang, gcc)
BUILD_TYPE      # build configure in "Debug|Release|MinSizeRel|RelWithDebInfo", default is "Release".
VERBOSE         # level of output, see [Verbose Level](#verbose-level).

ROOT            # root directory of SDK or empty. e.g. "E:\NDK\android-ndk-r11b", default is empty.
TOOLCHAIN_FILE  # toolchain file for CMake, usually is set automatically.
API_VERSION     # SDK API version, e.g. "9" for android, default is empty.
MAKE_PROGRAM    # path of "make" program, usually is searched automatically. (nmake|msbuild|devenv) is supported by MSVC.

C_FLAGS         # compile flags for C compiler.
CXX_FLAGS       # compile flags for C++ compiler.
LINKER_FLAGS    # linker flags.
LD_FLAGS        # alias of LINKER_FLAGS.
HIDDEN          # hidden all symbols except symbols in SDK include headers (default is OFF).

# Following arguments are unstable.
SDK             # reserved
```

### Verbose Level

The `VERBOSE` argument controls the output level of build system.
There are several levels as the following:

```cmake
0 - quiet, only error
1 - warning
2 - information (default)
3 - debug
4 - verbose makefile
```


### Useful Variables for Your `CMakeLists.txt`

The following variables are set in custom toolchain automatically, and you can use
them in your `CMakeLists.txt`.

```cmake
ARCBUILD            # root directory of arcbuild scripts.
ARCBUILD_VERBOSE    # verbose level set by `-DVERBOSE=`.
ARCBUILD_HIDDEN     # set by `-DHIDDEN=`.

# SDK related variables
SDK_ROOT
SDK_ARCH
SDK_API_VERSION
SDK_STL

ARM=ON        # for target CPU of ARM architectures.
UNIX=ON       # for UNIX-like target platforms.
ANDROID=ON    # for android platform.
APPLE=ON      # for iOS platform.
IOS=ON        # for iOS platform.
TIZEN=ON      # for tizen platform.
QTEE=ON       # for Qualcommn QTEE LLVM ARM compiler.
EMSCRIPTEN=ON # for EMCC compiler.
```
