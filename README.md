# ArcBuild

[![build status](/../../workflows/android-arm/badge.svg)](/../../actions?query=workflow%3Aandroid-arm)
[![build status](/../../workflows/ios-iphone/badge.svg)](/../../actions?query=workflow%3Aios-iphone)
[![build status](/../../workflows/windows-vs2019/badge.svg)](/../../actions?query=workflow%3Awindows-vs2019)
[![build status](/../../workflows/linux-x64-gcc/badge.svg)](/../../actions?query=workflow%3Alinux-x64-gcc)

Easy native and cross compiling for CMake projects.

![](docs/overview.jpg)


## Features

- Pure CMake scripts and no other dependencies.
- Support major platforms and system architectres, e.g. `windows`, `linux`, `android`, `ios`, `tizen`, etc.

## Dependencies

- [CMake](http://cmake.org/) >= 3.4 (3.8 or above is recommended)


## Usage

1. Download `arcbuild` and `arcbuild.cmake` to `<root of your project>`.
2. Generate build directory and build.

```shell
cmake -P arcbuild.cmake [(-D<var>=<value>)...] -S . -B build
cmake --build build --config <config> [--target <target>]
```

More `arcbuild.cmake` documents will be found in [docs](docs/README.md),
and see [CMake Build Tool Mode](https://cmake.org/cmake/help/latest/manual/cmake.1.html#build-tool-mode)

## Supported Platforms and Arguments Preview

| OS             | PLATFORM         | ARCH                         | More Arguments              |
|----------------|------------------|------------------------------|-----------------------------|
| Windows        | vs201{2,3,5,7,9} | x86, x64, arm                |                             |
| Linux          | linux            | x86, x64                     |                             |
| Android        | android          | arm{,v7-a,v8-a,64}, x86, x64 | TOOLCHAIN, STL, API_VERSION |
| iOS            | ios              | [armv7;][armv7s;][arm64]     | IOS_BITCODE, API_VERSION    |
| Raspberry Pi   | pi               | arm{,v7-a,v8-a}              |                             |
| [Emscripten]() | emscripten       |                              |                             |
| Custom ARM     | linux            | arm{,v7-a,v8-a}, x86, x64    |                             |
| Qualcomm TEE   | qtee             | arm{v5,v6m,v7,v7m,64}        |                             |


### Building Examples

#### Build for Android (`ARCH=armv7-a` by default)

```shell
cmake -DPLATFORM=android -DROOT="E:\NDK\android-ndk-r11b" -P arcbuild.cmake
cmake -DPLATFORM=android -P arcbuild.cmake # use $ANDROID_NDK_ROOT
```

#### Build for MSVC (`ARCH=x86` by default)

```shell
cmake -P arcbuild.cmake -DPLATFORM=vs2013
cmake -P arcbuild.cmake -DPLATFORM=vs2015
cmake -P arcbuild.cmake -DPLATFORM=vs2017
```

#### Build for Linux (`ARCH=x64` by default)

```shell
cmake -P arcbuild.cmake -DPLATFORM=linux
```

#### Build for iOS (`ARCH="armv7;armv7s;arm64;arm64e"` by default)

```shell
cmake -P arcbuild.cmake -DPLATFORM=ios -DIOS_BITCODE=ON
cmake -P arcbuild.cmake -DPLATFORM=ios -DARCH="i386;x86_64"
```

#### Build for [Emscripten]()

```shell
cmake -P arcbuild.cmake -DPLATFORM=emscripten -DROOT=D:\emscripten\1.38.11 -DMAKE_PROGRAM=D:\gnu-tools\bin\make.exe
```

#### Custom cross compiling for Linux based platform

```shell
cmake -P arcbuild.cmake -DPLATFORM=linux -DARCH=arm -DROOT=~/arm-toolchain
```

For more arguments, please check [Arguments for Platforms](docs/PlatformArguments.md).


## Example Projects

- [hello_world](examples/hello_world): "Hello world" project.


## TODO

- More tests.

[Emscripten]: https://kripken.github.io/emscripten-site/index.html
