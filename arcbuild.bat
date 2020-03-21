@echo off
REM The MIT License (MIT)
REM Copyright © 2016 Naiyang Lin <maxint@foxmail.com>

set PATH=C:\Program Files\CMake\bin;C:\Program Files (x86)\CMake\bin;%PATH%
cmake -P %~dp0arcbuild.cmake %*
