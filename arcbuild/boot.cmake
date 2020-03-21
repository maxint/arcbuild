# The MIT License (MIT)
# Copyright © 2016 Naiyang Lin <maxint@foxmail.com>

include(${ARCBUILD}/cmd.cmake)


# Main entry
arcbuild_check_script_mode(is_script_mode)
if(is_script_mode)
  unset(is_script_mode)
  arcbuild_parse_cmake_command_argv(parsed_entries ARCBUILD_UNPARSED_ARGS)
  include(${ARCBUILD}/build.cmake)
  arcbuild_build(${parsed_entries})
else()
  unset(is_script_mode)
  include(${ARCBUILD}/core.cmake)
endif()
