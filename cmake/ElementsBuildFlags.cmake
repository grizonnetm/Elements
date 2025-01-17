
include_guard(GLOBAL)

include(CheckCXXCompilerFlag)
include(CheckCCompilerFlag)

include(SGSPlatform)

macro(check_and_use_cxx_option opt var)
    set(CMAKE_REQUIRED_QUIET ON)
    if($ENV{VERBOSE})
      set(CMAKE_REQUIRED_QUIET OFF)
    endif()
    check_cxx_compiler_flag(${opt} ${var})
    if(${var})
      debug_message(STATUS "   C++ uses \"${opt}\"")
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${opt}"
          CACHE STRING "Flags used by the compiler during all build types."
          FORCE)
    endif()
endmacro()


macro(check_and_use_c_option opt var)
    check_c_compiler_flag(${opt} ${var})
    if(${var})
      debug_message(STATUS "   C uses \"${opt}\"")
      set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${opt}"
          CACHE STRING "Flags used by the compiler during all build types."
          FORCE)
    endif()
endmacro()


if (ELEMENTS_BUILD_PREFIX_CMD)
  set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE "${ELEMENTS_BUILD_PREFIX_CMD}")
  message(STATUS "Prefix build commands with '${ELEMENTS_BUILD_PREFIX_CMD}'")
else()

  find_package(CCache QUIET)

  if(CCACHE_FOUND)
    option(CMAKE_USE_CCACHE "Use ccache to speed up compilation." OFF)
    if(CMAKE_USE_CCACHE)
      set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ${CCACHE_EXECUTABLE})
      message(STATUS "Using ccache for building")
    endif()
    option(CPACK_USE_CCACHE "Use ccache to speed up compilation when creating the distribution package." OFF)
  endif()

  find_package(DistCC QUIET)

  if(DISTCC_FOUND)
    option(CMAKE_USE_DISTCC "Use distcc to speed up compilation." OFF)
    if(CMAKE_USE_DISTCC)
      if(CMAKE_USE_CCACHE AND CCACHE_FOUND)
        set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE "CCACHE_PREFIX=${DISTCC_EXECUTABLE} ${CCACHE_EXECUTABLE}")
        message(STATUS "Enabling distcc builds in ccache")
      else()
        set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ${DISTCC_EXECUTABLE})
        message(STATUS "Using distcc for building")
      endif()
    endif()
    option(CPACK_USE_DISTCC "Use distcc to speed up compilation when creating the distribution package." OFF)
  endif()

endif()

# This option make sense only if we have 'objcopy'
if(CMAKE_OBJCOPY)
  option(ELEMENTS_DETACHED_DEBINFO
         "When CMAKE_BUILD_TYPE is RelWithDebInfo, save the debug information on a different file."
         ON)
else()
  set(ELEMENTS_DETACHED_DEBINFO OFF)
endif()

option(USE_ODB "Use the ODB libraries" OFF)
option(ELEMENTS_USE_STRICT_BINARY_DEP "Flag to force the strict binary dependencies" OFF)
option(ELEMENTS_USE_CASE_SENSITIVE_PROJECTS "No uppercase projects allowed" ON)

#--- Project Options and Global settings----------------------------------------------------------
option(BUILD_SHARED_LIBS "Set to OFF to build static libraries." ON)
option(ELEMENTS_BUILD_TESTS "Set to OFF to disable the build of the tests (libraries and executables)." ON)
option(ELEMENTS_HIDE_WARNINGS "Turn on or off options that are used to hide warning messages." ON)
option(ELEMENTS_USE_EXE_SUFFIX "Add the .exe suffix to executables on Unix systems (like CMT does)." OFF)
#-------------------------------------------------------------------------------------------------




if(("${SGS_COMP}" STREQUAL "clang") OR ("${SGS_COMP}" STREQUAL "llvm"))
  find_package(Clang)
  SET (CMAKE_C_COMPILER    "${CLANG_C_COMPILER}")
  SET (CMAKE_CXX_COMPILER  "${CLANG_CXX_COMPILER}")
  SET (CMAKE_AR            "${LLVM_AR}")
  SET (CMAKE_LINKER        "${LLVM_LINKER}")
  SET (CMAKE_NM            "${LLVM_NM}")
  SET (CMAKE_OBJDUMP       "${LLVM_OBJDUMP}")
  SET (CMAKE_RANLIB        "${LLVM_RANLIB}")
endif()


if(NOT BUILD_PREFIX_NAME)
  set(BUILD_PREFIX_NAME "build" CACHE STRING "Prefix name for the build directory" FORCE)
endif()
message(STATUS "The build prefix is set to ${BUILD_PREFIX_NAME}")

if(NOT PYTHON_EXPLICIT_VERSION)
  set(PYTHON_EXPLICIT_VERSION "" CACHE STRING "Set the explicit python version to be used" FORCE)
endif()

if(NOT "${PYTHON_EXPLICIT_VERSION}" STREQUAL "")
  set_property(GLOBAL APPEND PROPERTY CMAKE_EXTRA_FLAGS "-DPYTHON_EXPLICIT_VERSION=${PYTHON_EXPLICIT_VERSION}")
endif()

if(NOT BUILD_SUBDIR)
  file(RELATIVE_PATH build_subdir_name ${CMAKE_SOURCE_DIR} ${CMAKE_BINARY_DIR})
  set(BUILD_SUBDIR ${build_subdir_name} CACHE STRING "Relative location for the build" FORCE)
endif()

message(STATUS "The path to the sources is set to ${CMAKE_SOURCE_DIR}")
message(STATUS "The path to the build is set to ${CMAKE_BINARY_DIR}")
message(STATUS "The relative location for the build is set to ${BUILD_SUBDIR}")

set(CYTHON_ANNOTATE OFF
  CACHE BOOL "Create an annotated .html file when compiling *.pyx.")
set(CYTHON_NO_DOCSTRINGS OFF
  CACHE BOOL "Strip docstrings from the compiled module.")
set(CYTHON_FLAGS "" CACHE STRING
  "Extra flags to the cython compiler.")

# Special defaults

debug_print_var(SGS_COMP)
debug_print_var(SGS_COMP_VERSION)

if ( ("${SGS_COMP}" STREQUAL gcc) OR ("${SGS_COMP}" STREQUAL clang) OR ("${SGS_COMP}" STREQUAL llvm))
  # C++11 is enable by default on gcc47 and gcc48
  set(ELEMENTS_CPP11_DEFAULT ON)
elseif("${SGS_COMP}" STREQUAL icc)
  set(ELEMENTS_CPP11_DEFAULT ON)
else()
  set(ELEMENTS_CPP11_DEFAULT OFF)
endif()


if ( ("${SGS_COMP}" STREQUAL gcc AND ( (NOT SGS_COMP_VERSION VERSION_LESS "5.0") OR (SGS_COMPVERS MATCHES "max") ))
    OR ("${SGS_COMP}" STREQUAL clang AND (NOT SGS_COMP_VERSION VERSION_LESS "3.5") )
    OR ("${SGS_COMP}" STREQUAL llvm))
  set(ELEMENTS_CPP14_DEFAULT ON)
  set(ELEMENTS_CPP11_DEFAULT OFF)
  
elseif("${SGS_COMP}" STREQUAL icc AND (NOT SGS_COMPVERS VERSION_LESS "17"))
  set(ELEMENTS_CPP14_DEFAULT ON)
  set(ELEMENTS_CPP11_DEFAULT OFF)
else()
  set(ELEMENTS_CPP14_DEFAULT OFF)
endif()

debug_print("The default C++11 standard is set to ${ELEMENTS_CPP11_DEFAULT}")
debug_print("The default C++14 standard is set to ${ELEMENTS_CPP14_DEFAULT}")


set(ELEMENTS_PARALLEL_DEFAULT OFF)

set(ELEMENTS_FORTIFY_DEFAULT ON)


#--- Elements Build Options -------------------------------------------------------
# Build options that map to compile time features
#

option(ELEMENTS_HIDE_SYMBOLS
       "Enable explicit symbol visibility on gcc-4"
       OFF)

option(PROJECT_HIDE_SYMBOLS
       "Enable explicit symbol visibility with a local project header"
       OFF)


option(ELEMENTS_CPP11
       "enable C++11 compilation"
       ${ELEMENTS_CPP11_DEFAULT})

option(ELEMENTS_CPP14
       "Enable C++14 compilation"
       ${ELEMENTS_CPP14_DEFAULT})

option(ELEMENTS_CPP17
       "Enable C++17 compilation"
       OFF)

option(ELEMENTS_CPP20
       "Enable C++20 compilation"
       OFF)

option(ELEMENTS_PARALLEL
       "Enable C++11 parallel support with OpenMP"
       ${ELEMENTS_PARALLEL_DEFAULT})

option(ELEMENTS_FORTIFY
       "Enable g++ fortify option"
       ${ELEMENTS_FORTIFY_DEFAULT})

option(USE_LOCAL_INSTALLAREA
       "Use local InstallArea for the Developers"
       OFF)

option(OPT_DEBUG
       "Enable optimisation for the Debug version"
       ON)

set(DEBUG_FORMAT "" CACHE STRING "Set the -g debug format")

set(DEBUG_LEVEL "" CACHE STRING "Set the -g debug level")

option(ELEMENTS_LINKOPT
       "Enable Link Time Optimisation"
       OFF)

option(USE_PYTHON_NOSE
       "Use nose as python test runner"
       OFF)

option(USE_SPHINX
       "Use sphinx documentation generation"
       ON)

option(USE_DOXYGEN
       "Use doxygen documentation generation"
       ON)

option(USE_PYTHON_DOXYGEN
       "Use doxygen documentation generation"
       ON)

option(USE_SPHINX_APIDOC
       "Use sphinx API documentation generation"
       ON)

option(USE_SPHINX_BREATHE
       "Use sphinx C++ API Breathe plugin to bind to doxygen"
       OFF)

option(USE_SPHINX_NUMPYDOC
       "Use sphinx numpydoc extension"
       ON)

option(ELEMENTS_USE_RPATH
       "Use full RPATH for both build and installation"
       ON)

option(HIDE_SYSINC_WARNINGS
       "Hide System includes warnings by using -isystem instead of -I"
       ON)

option(HIDE_OTHERINC_WARNINGS
       "Hide includes warnings issued by other projects by using -isystem instead of -I"
       OFF)


option(CXX_SUGGEST_OVERRIDE
       "Enable the -Wsuggest-override warning"
       OFF)

option(FLOAT_EQUAL_WARNING
       "Enable the -Wfloat-equal warning"
       OFF)

option(CONVERSION_WARNING
       "Enable the -Wconversion warning"
       OFF)

option(SQUEEZED_INSTALL
       "Enable the squeezing of the installation into a prefix directory"
       ON)

option(SANITIZE_OPTIONS
       "Activate the Sanitizing options"
       OFF)
       
if(NOT SANITIZE_STYLE)
  set(SANITIZE_STYLE "undefined" CACHE STRING "Style used for the -fsanitize= option" FORCE)
endif()

option(CPACK_REMOVE_SYSTEM_DEPS
       "When active this option remove the dependencies onto the system (external) packages"
       OFF)

option(INSTALL_DOC
       "Build and Install the API documentation by default"
       OFF)

option(CONCEPT_CHECKS
       "Enable the concept template checking by adding -D_GLIBCXX_CONCEPT_CHECKS"
       OFF)

option(TEST_HTML_REPORT
       "Enable the conversion of the CTest XML reports into HTML"
       ON)

option(TEST_XML_REPORT
       "Enable the redirection of the Boost tests output to XML files instead of the regular output"
       OFF)

option(TEST_JUNIT_REPORT
       "Enable the conversion of the CTest XML reports into JUnit XML reports"
       ON)

option(WITH_DATASYNC_TEST
       "Enable the test which require a specific DataSync connection"
       OFF)

option(USE_ENV_FLAGS
       "Use the environment CFLAGS, CXXFLAGS and LDFLAGS"
       OFF)

option(USE_RPM_CMAKE_MACRO
       "Use the system RPM macro for the rpm command"
       OFF)

if(NOT ELEMENTS_DEFAULT_LOGLEVEL)
  if(USE_LOCAL_INSTALLAREA)
    set(ELEMENTS_DEFAULT_LOGLEVEL "INFO" CACHE STRING "Set the default loglevel for the framework messages" FORCE)
  else()
    set(ELEMENTS_DEFAULT_LOGLEVEL "DEBUG" CACHE STRING "Set the default loglevel for the framework messages" FORCE)
  endif()
endif()


option(INSTALL_TESTS
       "Enable the installation of the binary tests"
       OFF)

option(USE_VERSIONED_LIBRARIES
       "Generate versioned shared libraries"
       ON)

option(USE_TIMESTAMP_RPM_VERSION
       "Use timestamp for the RPM version in non-squeezed mode"
       OFF)

option(Boost_NO_BOOST_CMAKE
       "Don't use the BoostConfig.cmake file introduced in Boost 1.70"
       ON)

option(GCOVR_EXCLUDE_UNREACHABLE
       "Option to remove unreachable branches from the gcovr analysis"
       ON)

option(GCOVR_EXCLUDE_THROW
       "Option to remove throuw branches from the gcovr analysis"
       ON)

set(GCOVR_EXTRA_OPTIONS "" CACHE STRING "Extra option to be appended to the gcovr command")

set(PYTEST_EXTRA_OPTIONS "" CACHE STRING "Extra option to be appended to the pytest command")

set(NOSE_EXTRA_OPTIONS "" CACHE STRING "Extra option to be appended to the nosetests command")


#--- Compilation Flags ---------------------------------------------------------
if(NOT ELEMENTS_FLAGS_SET)
  message(STATUS "Setting cached build flags")


  if(USE_RPM_CMAKE_MACRO)
    set_property(GLOBAL APPEND PROPERTY CMAKE_EXTRA_FLAGS "-DUSE_ENV_FLAGS:BOOL=ON")
  else()
    set_property(GLOBAL APPEND PROPERTY CMAKE_EXTRA_FLAGS "-DUSE_ENV_FLAGS:BOOL=${USE_ENV_FLAGS}")
  endif()


    # Common compilation flags
  if(USE_ENV_FLAGS)
    set(CMAKE_CXX_FLAGS $ENV{CXXFLAGS})
  else()
    set(CMAKE_CXX_FLAGS)
  endif()

  set(CMAKE_CXX_FLAGS
      "${CMAKE_CXX_FLAGS} -fmessage-length=0 -pipe -pthread -pedantic -fPIC"
      CACHE STRING "Flags used by the compiler during all build types."
      FORCE)

  check_and_use_cxx_option(-Wall CXX_HAS_ALL)
  check_and_use_cxx_option(-Wextra CXX_HAS_EXTRA)
  check_and_use_cxx_option(-Wwrite-strings CXX_HAS_WRITE_STRINGS)
  check_and_use_cxx_option(-Wpointer-arith CXX_HAS_POINTER_ARITH)
  check_and_use_cxx_option(-Wno-long-long CXX_HAS_NO_LONG_LONG)
  check_and_use_cxx_option(-Wno-unknown-pragmas CXX_HAS_NO_UNKNOWN_PRAGMAS)
  check_and_use_cxx_option(-Wformat-security CXX_HAS_FORMAT_SECURITY)
  check_and_use_cxx_option(-Wshadow CXX_HAS_SHADOW)
  check_and_use_cxx_option(-Wlogical-not-parentheses CXX_HAS_LOGICAL_NOT_PARENTHESES)
  check_and_use_cxx_option(-Wnull-dereference CXX_HAS_NULL_DEREFERENCE)

  check_and_use_cxx_option(-Woverloaded-virtual CXX_HAS_OVERLOADED_VIRTUAL)

  check_and_use_cxx_option(-Werror=return-type CXX_HAS_ERROR_RETURN_TYPE)

  if(USE_ENV_FLAGS)
    set(CMAKE_C_FLAGS $ENV{CFLAGS})
  else()
    set(CMAKE_C_FLAGS)
  endif()

  set(CMAKE_C_FLAGS
      "${CMAKE_C_FLAGS} -fmessage-length=0 -pipe -pthread -pedantic -fPIC"
      CACHE STRING "Flags used by the compiler during all build types."
      FORCE)

  check_and_use_c_option(-Wall C_HAS_ALL)
  check_and_use_c_option(-Wextra C_HAS_EXTRA)
  check_and_use_c_option(-Wwrite-strings C_HAS_WRITE_STRINGS)
  check_and_use_c_option(-Wpointer-arith C_HAS_POINTER_ARITH)
  check_and_use_c_option(-Wno-long-long C_HAS_NO_LONG_LONG)
  check_and_use_c_option(-Wno-unknown-pragmas C_HAS_NO_UNKNOWN_PRAGMAS)
  check_and_use_c_option(-Wformat-security C_HAS_FORMAT_SECURITY)
  check_and_use_c_option(-Wshadow C_HAS_SHADOW)
  check_and_use_c_option(-Wlogical-not-parentheses C_HAS_LOGICAL_NOT_PARENTHESES)
  check_and_use_c_option(-Wnull-dereference C_HAS_NULL_DEREFERENCE)

  check_and_use_c_option(-Wno-unused-parameter C_HAS_NO_UNUSED_PARAMETER)

  check_and_use_c_option(-Werror=return-type C_HAS_ERROR_RETURN_TYPE)

  if(NOT "${SGS_COMP}" STREQUAL clang)
    check_and_use_cxx_option(-Wduplicated-cond CXX_HAS_DUPLICATED_COND)
    check_and_use_c_option(-Wduplicated-cond C_HAS_DUPLICATED_COND)
    check_and_use_c_option(-Wjump-misses-init C_HAS_JUMP_MISSES_INIT)
  endif()


  if((NOT "${SGS_COMP}" STREQUAL clang) OR (SGS_COMP_VERSION VERSION_GREATER "4.0") )
    check_and_use_cxx_option(-ansi CXX_HAS_ANSI)
    check_and_use_c_option(-ansi C_HAS_ANSI)
  endif()

  if(SANITIZE_OPTIONS AND ("${SGS_COMP}" STREQUAL gcc))
    check_and_use_cxx_option(-fsanitize=${SANITIZE_STYLE} CXX_HAS_SANITIZE)
    check_and_use_c_option(-fsanitize=${SANITIZE_STYLE} C_HAS_SANITIZE)
  endif()

  if(FLOAT_EQUAL_WARNING)
    check_and_use_cxx_option(-Wfloat-equal CXX_HAS_FLOAT_EQUAL)
    check_and_use_c_option(-Wfloat-equal C_HAS_FLOAT_EQUAL)
  endif()
  
  if(CONVERSION_WARNING)
    check_and_use_cxx_option(-Wconversion CXX_HAS_CONVERSION)
    check_and_use_c_option(-Wconversion C_HAS_CONVERSION)
  endif()

  if(CXX_SUGGEST_OVERRIDE AND ("${SGS_COMP}" STREQUAL gcc))
    check_and_use_cxx_option(-Wsuggest-override CXX_HAS_SUGGEST_OVERRIDE)
  endif()

  if("${SGS_COMP}" STREQUAL gcc)
    check_and_use_cxx_option(-Wcast-function-type CXX_HAS_CAST_FUNCTION_TYPE)
    check_and_use_cxx_option(-Wpedantic CXX_HAS_PEDANTIC_WARN)
    check_and_use_c_option(-Wpedantic C_HAS_PEDANTIC_WARN)
  endif()

  check_cxx_compiler_flag(-Wmissing-field-initializers CXX_HAS_MISSING_FIELD_INITIALIZERS)

  if("${SGS_COMP}" STREQUAL clang)
    check_cxx_compiler_flag(-Wunused-function CXX_HAS_UNUSED_FUNCTION)
  endif()

  if("${SGS_COMP}" STREQUAL clang)
    check_cxx_compiler_flag(-Wno-unneeded-internal-declaration CXX_HAS_NO_UNNEEDED_INTERNAL_DECLARATION)
  endif()

  if("${SGS_COMP}" STREQUAL clang)
    check_cxx_compiler_flag(-Wno-c++17-extensions CXX_HAS_NO_CXX17_EXTENSIONS)
  endif()

  if("${SGS_COMP}" STREQUAL clang)
    check_cxx_compiler_flag(-Wno-parentheses-equality CXX_HAS_NO_PARENTHESES_EQUALITY)
  endif()

  if("${SGS_COMP}" STREQUAL clang)
    check_cxx_compiler_flag(-Wno-self-assign CXX_HAS_NO_SELF_ASSIGN)
  endif()

  if("${SGS_COMP}" STREQUAL clang)
    check_cxx_compiler_flag(-Wno-constant-logical-operand CXX_HAS_NO_CONSTANT_LOGICAL_OPERAND)
  endif()


  # Build type compilation flags (if different from default or unknown to CMake)
  set(CMAKE_CXX_FLAGS_RELEASE "-O2"
      CACHE STRING "Flags used by the compiler during release builds."
      FORCE)
  set(CMAKE_C_FLAGS_RELEASE "-O2"
      CACHE STRING "Flags used by the compiler during release builds."
      FORCE)

  if (ELEMENTS_LINKOPT)
    check_cxx_compiler_flag(-flto CXX_HAS_LTO)
  endif()
  
  if(CXX_HAS_LTO)
    set(CMAKE_CXX_FLAGS_RELEASE "-flto ${CMAKE_CXX_FLAGS_RELEASE}"
        CACHE STRING "Flags used by the compiler during release builds."
        FORCE)
    set(CMAKE_C_FLAGS_RELEASE "-flto ${CMAKE_C_FLAGS_RELEASE}"
        CACHE STRING "Flags used by the compiler during release builds."
        FORCE)
  endif()


  set(CMAKE_CXX_FLAGS_DEBUG "-g${DEBUG_FORMAT}${DEBUG_LEVEL}"
      CACHE STRING "Flags used by the compiler during Debug builds."
      FORCE)
  set(CMAKE_C_FLAGS_DEBUG "-g${DEBUG_FORMAT}${DEBUG_LEVEL}"
      CACHE STRING "Flags used by the compiler during Debug builds."
      FORCE)
  if(OPT_DEBUG)
    check_cxx_compiler_flag(-Og CXX_HAS_MINUS_OG)
    if(CXX_HAS_MINUS_OG)
      set(CMAKE_CXX_FLAGS_DEBUG "-Og ${CMAKE_CXX_FLAGS_DEBUG}"
          CACHE STRING "Flags used by the compiler during Debug builds."
          FORCE)
    endif()
    check_c_compiler_flag(-Og C_HAS_MINUS_OG)
    if(C_HAS_MINUS_OG)
      set(CMAKE_C_FLAGS_DEBUG "-Og ${CMAKE_C_FLAGS_DEBUG}"
          CACHE STRING "Flags used by the compiler during Debug builds."
          FORCE)
    endif()
  endif()


  set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-O2 -g${DEBUG_FORMAT}${DEBUG_LEVEL}"
      CACHE STRING "Flags used by the compiler during Release with Debug Info builds."
      FORCE)
  set(CMAKE_C_FLAGS_RELWITHDEBINFO "-O2 -g${DEBUG_FORMAT}${DEBUG_LEVEL}"
      CACHE STRING "Flags used by the compiler during Release with Debug Info builds."
      FORCE)

  if(CXX_HAS_LTO)
    set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-flto ${CMAKE_CXX_FLAGS_RELWITHDEBINFO}"
        CACHE STRING "Flags used by the compiler during release builds."
        FORCE)
    set(CMAKE_C_FLAGS_RELWITHDEBINFO "-flto ${CMAKE_C_FLAGS_RELWITHDEBINFO}"
        CACHE STRING "Flags used by the compiler during release builds."
        FORCE)
  endif()

  set(CMAKE_CXX_FLAGS_COVERAGE "--coverage"
      CACHE STRING "Flags used by the compiler during coverage builds."
      FORCE)
  set(CMAKE_C_FLAGS_COVERAGE "--coverage"
      CACHE STRING "Flags used by the compiler during coverage builds."
      FORCE)

  # @todo Check why the -D_GLIBCXX_PROFILE cannot be used with Boost.
  set(CMAKE_CXX_FLAGS_PROFILE "-pg"
      CACHE STRING "Flags used by the compiler during profile builds."
      FORCE)
  set(CMAKE_C_FLAGS_PROFILE "-pg"
      CACHE STRING "Flags used by the compiler during profile builds."
      FORCE)

  # The others are already marked as 'advanced' by CMake, these are custom.
  mark_as_advanced(CMAKE_C_FLAGS_COVERAGE CMAKE_CXX_FLAGS_COVERAGE
                   CMAKE_C_FLAGS_PROFILE CMAKE_CXX_FLAGS_PROFILE)


  #--- Link shared flags -------------------------------------------------------

  if(USE_ENV_FLAGS)
    set(CMAKE_SHARED_LINKER_FLAGS $ENV{LDFLAGS})
    set(CMAKE_MODULE_LINKER_FLAGS $ENV{LDFLAGS})
    set(CMAKE_EXE_LINKER_FLAGS $ENV{LDFLAGS})
  else()
    set(CMAKE_SHARED_LINKER_FLAGS $ENV{LDFLAGS})
    set(CMAKE_MODULE_LINKER_FLAGS $ENV{LDFLAGS})
    set(CMAKE_EXE_LINKER_FLAGS $ENV{LDFLAGS})
  endif()

  if (CMAKE_SYSTEM_NAME MATCHES Linux)
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--enable-new-dtags -Wl,--as-needed -Wl,--no-undefined"
        CACHE STRING "Flags used by the linker during the creation of dll's."
        FORCE)
    set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} -Wl,--enable-new-dtags -Wl,--as-needed -Wl,--no-undefined"
        CACHE STRING "Flags used by the linker during the creation of modules."
        FORCE)
    if("${CMAKE_BUILD_TYPE}" STREQUAL "Profile" AND SGS_COMP_VERSION VERSION_LESS "5.0")
      set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--enable-new-dtags -Wl,--as-needed"
          CACHE STRING "Flags used by the linker during the creation of exe's."
          FORCE)
    else()
      set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--enable-new-dtags -Wl,--as-needed -pie"
          CACHE STRING "Flags used by the linker during the creation of exe's."
          FORCE)
    endif()
  endif()

  if(APPLE)
    # special link options for MacOSX
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -flat_namespace -undefined dynamic_lookup"
        CACHE STRING "Flags used by the linker during the creation of dll's."
        FORCE)
    set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} -flat_namespace -undefined dynamic_lookup"
        CACHE STRING "Flags used by the linker during the creation of modules."
        FORCE)
  endif()

  if("${CMAKE_BUILD_TYPE}" STREQUAL "Coverage" AND "${SGS_COMP}" STREQUAL "gcc")
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} --coverage"
          CACHE STRING "Flags used by the linker during the creation of exe's."
          FORCE)
  endif()

  # prevent resetting of the flags
  set(ELEMENTS_FLAGS_SET ON
      CACHE INTERNAL "flag to check if the compilation flags have already been set")
endif()

add_definitions(-DELEMENTS_DEFAULT_LOGLEVEL=${ELEMENTS_DEFAULT_LOGLEVEL})

if ("${CMAKE_BUILD_TYPE}" STREQUAL "RelWithDebInfo" OR "${CMAKE_BUILD_TYPE}" STREQUAL "Release")
    add_definitions(-DNDEBUG)
endif()

if(UNIX)
  add_definitions(-D_GNU_SOURCE -Df2cFortran)
endif()

if(APPLE)
  # by default, CMake uses the option -bundle for modules, but we need -dynamiclib for them too
  string(REPLACE "-bundle" "-dynamiclib" CMAKE_SHARED_MODULE_CREATE_C_FLAGS "${CMAKE_SHARED_MODULE_CREATE_C_FLAGS}")
  string(REPLACE "-bundle" "-dynamiclib" CMAKE_SHARED_MODULE_CREATE_CXX_FLAGS "${CMAKE_SHARED_MODULE_CREATE_CXX_FLAGS}")
  elements_include_directories(BEFORE /opt/local/include/${SGS_COMP}${SGS_COMPVERS}/c++)
endif()

#--- Special build flags -------------------------------------------------------
if ((ELEMENTS_HIDE_SYMBOLS) AND ("${SGS_COMP}" STREQUAL "gcc"))
  set(CMAKE_CXX_VISIBILITY_PRESET hidden)
  set(CMAKE_VISIBILITY_INLINES_HIDDEN 1)
  add_definitions(-DELEMENTS_HIDE_SYMBOLS)
endif()

if ((CONCEPT_CHECKS) AND ("${SGS_COMP}" STREQUAL "gcc"))
  add_definitions(-D_GLIBCXX_CONCEPT_CHECKS)
endif()


if(USE_ODB)
  set(ODB_CXX_EXTRA_FLAGS ""
      CACHE STRING "flag passed to the ODB compiler"
      FORCE)
endif()


if ( ELEMENTS_CPP11 AND ELEMENTS_CPP14)
  message(WARNING "Both -std=c++11 and -std=c++14 are active. Please remove one by setting/unsetting the right option")
endif()

if ( ELEMENTS_CPP14 AND ELEMENTS_CPP17)
  message(WARNING "Both -std=c++14 and -std=c++17 are active. Please remove one by setting/unsetting the right option")
endif()



if ( ELEMENTS_CPP11 )

  check_cxx_compiler_flag("-std=c++11" HAS_CPP11_FLAG)
  if(HAS_CPP11_FLAG)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
    if ( APPLE AND (("${SGS_COMP}" STREQUAL "clang") OR ("${SGS_COMP}" STREQUAL "llvm") ) )
      check_and_use_cxx_option(-stdlib=libc++ CXX_HAS_MINUS_STDLIB)
    endif()
    if(USE_ODB)
      set(ODB_CXX_EXTRA_FLAGS --std c++11)
    endif()
  else()
    message(WARNING "The -std=c++11 option is not available")  
  endif()

  check_c_compiler_flag("-std=c11" HAS_C11_FLAG)
  if(HAS_C11_FLAG)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=c11")
  else()
    message(WARNING "The -std=c11 option is not available")  
  endif()

endif()

if ( ELEMENTS_CPP14 )

  check_cxx_compiler_flag("-std=c++14" HAS_CPP14_FLAG)
  if(HAS_CPP14_FLAG)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")
    if ( APPLE AND (("${SGS_COMP}" STREQUAL "clang") OR ("${SGS_COMP}" STREQUAL "llvm") ) )
      check_and_use_cxx_option(-stdlib=libc++ CXX_HAS_MINUS_STDLIB)
    endif()
  else()
    message(WARNING "The -std=c++14 option is not available")  
  endif()

  check_c_compiler_flag("-std=c11" HAS_C11_FLAG)
  if(HAS_C11_FLAG)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=c11") # this is the latest C standard available
  else()
    message(WARNING "The -std=c11 option is not available")
  endif()

endif()


if ( ELEMENTS_CPP17 )

  check_cxx_compiler_flag("-std=c++17" HAS_CPP17_FLAG)
  if(HAS_CPP17_FLAG)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17")
    if ( APPLE AND (("${SGS_COMP}" STREQUAL "clang") OR ("${SGS_COMP}" STREQUAL "llvm") ) )
      check_and_use_cxx_option(-stdlib=libc++ CXX_HAS_MINUS_STDLIB)
    endif()
  else()
    message(WARNING "The -std=c++17 option is not available")  
  endif()

  check_c_compiler_flag("-std=c17" HAS_C17_FLAG)
  if(HAS_C17_FLAG)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=c17") # this is the latest C standard available
  else()
    message(WARNING "The -std=c17 option is not available")
  endif()

endif()

if ( ELEMENTS_CPP20 )

  check_cxx_compiler_flag("-std=c++20" HAS_CPP20_FLAG)
  if(HAS_CPP20_FLAG)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++20")
    if ( APPLE AND (("${SGS_COMP}" STREQUAL "clang") OR ("${SGS_COMP}" STREQUAL "llvm") ) )
      check_and_use_cxx_option(-stdlib=libc++ CXX_HAS_MINUS_STDLIB)
    endif()
  else()
    message(WARNING "The -std=c++20 option is not available")  
  endif()

  check_c_compiler_flag("-std=c2x" HAS_C2X_FLAG)
  if(HAS_C2X_FLAG)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=c2x") # this is the latest C standard available
  else()
    message(WARNING "The -std=c2x option is not available")
  endif()

endif()



if ( APPLE AND ( ("${SGS_COMP}" STREQUAL "clang") OR ("${SGS_COMP}" STREQUAL "llvm")))
  if(DEFINED ENV{MACPORT_LOCATION})
    set(macport_inc "$ENV{MACPORT_LOCATION}/include")
  else()
    set(macport_inc "/opt/local/include")
  endif()
  if(EXISTS ${macport_inc})
    include_directories(SYSTEM ${macport_inc})
    if("${SGS_COMP}" STREQUAL "clang")
      if (SGS_COMP_VERSION VERSION_GREATER "3.4")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -isystem ${macport_inc}")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -isystem ${macport_inc}")
      else()
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Xclang -isystem-prefix -Xclang ${macport_inc}")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Xclang -isystem-prefix -Xclang  ${macport_inc}")
      endif()
    endif()
    if("${SGS_COMP}" STREQUAL "llvm")
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -isystem ${macport_inc}")
      set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -isystem ${macport_inc}")
    endif()
  endif()
endif()

if ( ELEMENTS_PARALLEL AND ("${SGS_COMP}" STREQUAL "gcc") )
  
  find_package(OpenMP)
  if(OPENMP_FOUND)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
    find_package(GLibCxxParallel)
    if(GLIBCXXPARALLEL_FOUND)
      add_definitions(${GLIBCXXPARALLEL_DEFINITIONS})
    endif()
  endif()
  
  
endif()

if ( ELEMENTS_FORTIFY AND ("${SGS_COMP}" STREQUAL "gcc") )
  if ("${CMAKE_BUILD_TYPE}" STREQUAL "Debug" AND OPT_DEBUG)
    add_definitions(-D_FORTIFY_SOURCE=2)
  endif()
  if ( ("${CMAKE_BUILD_TYPE}" STREQUAL "Release") OR ("${CMAKE_BUILD_TYPE}" STREQUAL "RelWithDebInfo") OR ("${CMAKE_BUILD_TYPE}" STREQUAL "MinSizeRel"))
    add_definitions(-D_FORTIFY_SOURCE=2)
  endif()
endif()


# special case
if(ELEMENTS_HIDE_SYMBOLS AND (comp MATCHES gcc4))
  add_definitions(-DELEMENTS_HIDE_SYMBOLS)
endif()
#

if (SGS_HOST_ARCH AND SGS_ARCH)
  if ("${SGS_HOST_ARCH}" STREQUAL x86_64 AND "${SGS_ARCH}" STREQUAL i686)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -m32")
    set(CMAKE_C_FLAGS "${CMAKE_CXX_FLAGS} -m32")
    set(GCCXML_CXX_FLAGS "${GCCXML_CXX_FLAGS} -m32")
  endif()
endif()

#--- Tuning of warnings --------------------------------------------------------
if(ELEMENTS_HIDE_WARNINGS)
  if( (SGS_COMP MATCHES clang) OR (SGS_COMP MATCHES llvm) )
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-deprecated -Wno-overloaded-virtual -Wno-char-subscripts -Wno-unused-parameter")
  elseif("${SGS_COMP}" STREQUAL "gcc")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-deprecated -Wno-empty-body")
  endif()
endif()

if( ("${SGS_COMP}" STREQUAL "clang") OR ("${SGS_COMP}" STREQUAL "llvm") )
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Qunused-arguments")
endif()

#--- Special flags -------------------------------------------------------------
add_definitions(-DBOOST_FILESYSTEM_VERSION=3)

if(("${SGS_COMP}" STREQUAL "gcc") OR ELEMENTS_CPP11)
  set(GCCXML_CXX_FLAGS "${GCCXML_CXX_FLAGS} -D__STRICT_ANSI__")
endif()

include(LocalBuildFlags OPTIONAL)
