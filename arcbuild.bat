@echo off
set PATH=C:\Program Files\CMake\bin;C:\Program Files (x86)\CMake\bin;%PATH%
cmake -P %~dp0arcbuild.cmake %*
