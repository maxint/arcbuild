
## [BETA] Function `arcbuild_combine_target()`

This function is used to combine multiple targets into new target, it's usually used for building of static SDK library.

**Warnning**: this function is not stable right now. For collecting the build information of multiple modules correctly, please **DO NOT** use backwards compatibility directory based commands (`add_definitions`, `include_directories`, `link_directories`, `link_libraries`, etc.), and use target based commands (`target_compile_definitions()`, `target_include_directories`,  `target_link_libraries`, etc.) instead.

Usage:
```cmake
# Enable arcbuild functions
include(arcbuild.cmake)
arcbuild_combine_target(sample_lib sample_lib_combined)
if(TARGET sample_lib_combined)
  # new combined target is created
endif()
```
