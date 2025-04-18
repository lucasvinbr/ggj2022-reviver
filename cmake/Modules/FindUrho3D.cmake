#
# Copyright (c) 2008-2022 the Urho3D project.
# Copyright (c) 2022-2024 the U3D project.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

# Find Urho3D include directories and libraries in the Urho3D SDK installation or build tree or in Android library
# This module should be able to find Urho3D automatically when the SDK is installed in a system-wide default location or
# when the Urho3D Android library has been correctly declared as project dependency
# If the SDK installation location is non-default or the Urho3D library is not installed at all (i.e. still in its build tree) then
#   use URHO3D_HOME environment variable or build option to specify the location of the non-default SDK installation or build tree
# When setting URHO3D_HOME variable, it should be set to a parent directory containing both the "include" and "lib" subdirectories
#   e.g. set URHO3D_HOME=/home/john/usr/local, if the SDK is installed using DESTDIR=/home/john and CMAKE_INSTALL_PREFIX=/usr/local

#
#  URHO3D_FOUND
#  URHO3D_INCLUDE_DIRS
#  URHO3D_LIBRARIES
#  URHO3D_VERSION
#  URHO3D_64BIT (may be used as input variable for multilib-capable compilers; must always be specified as input variable for MSVC due to CMake/VS generator limitation)
#  URHO3D_LIB_TYPE (may be used as input variable as well to limit the search of library type)
#  URHO3D_OPENGL
#  URHO3D_SSE
#  URHO3D_DATABASE_ODBC
#  URHO3D_DATABASE_SQLITE
#  URHO3D_LUAJIT
#  URHO3D_TESTING
#
# WIN32 only:
#  URHO3D_LIBRARIES_REL
#  URHO3D_LIBRARIES_DBG
#  URHO3D_DLL
#  URHO3D_DLL_REL
#  URHO3D_DLL_DBG
#  URHO3D_D3D11
#
# MSVC only:
#  URHO3D_STATIC_RUNTIME
#

set (PATH_SUFFIX Urho3D)

if ((CMAKE_PROJECT_NAME STREQUAL Urho3D AND TARGET Urho3D) OR URHO3D_AS_SUBMODULE)
    # A special case where library location is already known to be in the build tree of Urho3D project
    if (URHO3D_BUILD_DIR)
        set (DIR ${URHO3D_BUILD_DIR})
    else ()
        set (DIR ${CMAKE_BINARY_DIR})
        set (URHO3D_HOME ${DIR})
    endif ()
    set (URHO3D_INCLUDE_DIRS ${DIR}/include ${DIR}/include/Urho3D/ThirdParty)
    if (URHO3D_PHYSICS)
        # Bullet library depends on its own include dir to be added in the header search path
        # This is more practical than patching its header files in many places to make them work with relative path
        list (APPEND URHO3D_INCLUDE_DIRS ${DIR}/include/Urho3D/ThirdParty/Bullet)
    endif ()
    if (URHO3D_LUA)
        # ditto for Lua/LuaJIT
        list (APPEND URHO3D_INCLUDE_DIRS ${DIR}/include/Urho3D/ThirdParty/Lua${JIT})
    endif ()
    set (URHO3D_LIBRARIES Urho3D)
    set (FOUND_MESSAGE "Found Urho3D: as CMake target")
    set (URHO3D_COMPILE_RESULT TRUE)
else ()
    # Convert to integer literal to match it with our internal cache representation; it also will be used as foreach loop control variable
    if (URHO3D_64BIT STREQUAL "ON" OR URHO3D_64BIT STREQUAL "1")
        set (URHO3D_LIB_64BIT 1)
    else ()
        set (URHO3D_LIB_64BIT 0)
    endif ()

    if (ANDROID)
        string (TOLOWER ${CMAKE_BUILD_TYPE} config)
        if (BUILD_STAGING_DIR)
            # Another special case where library location is already known to be in the build tree of Urho3D project
            get_filename_component (BUILD_STAGING_DIR ${BUILD_STAGING_DIR}/cmake DIRECTORY)
            set (URHO3D_HOME ${BUILD_STAGING_DIR}/cmake/${config}/${ANDROID_ABI})
        elseif (JNI_DIR)
            # Using Urho3D AAR from Maven repository
            get_filename_component (JNI_DIR ${JNI_DIR}/urho3d DIRECTORY)
            set (URHO3D_HOME ${JNI_DIR}/urho3d/${config}/${ANDROID_ABI})
        else ()
            message (FATAL_ERROR "Neither 'BUILD_STAGING_DIR' nor 'JNI_DIR' is set")
        endif ()
        set (URHO3D_BASE_INCLUDE_DIR ${URHO3D_HOME}/include/Urho3D)
        if (URHO3D_LIB_TYPE STREQUAL SHARED)
            set (URHO3D_LIBRARIES ${URHO3D_HOME}/lib/libUrho3D.so)
        else ()
            set (URHO3D_LIBRARIES ${URHO3D_HOME}/lib/libUrho3D.a)
        endif ()
        set (SKIP_FIND_LIBRARIES TRUE)
        set (URHO3D_COMPILE_RESULT TRUE)
        set (URHO3D_ROOT_DIR ${URHO3D_HOME})
        set (URHO3D_BUILD_DIR ${URHO3D_HOME})    
    else ()
        if (NOT URHO3D_HOME AND DEFINED ENV{URHO3D_HOME})
            # Library location would be searched (based on URHO3D_HOME variable if provided and in system-wide default location)
            file (TO_CMAKE_PATH "$ENV{URHO3D_HOME}" URHO3D_HOME)
        endif ()

        # If either of the URHO3D_64BIT or URHO3D_LIB_TYPE or URHO3D_HOME build options changes then invalidate all the caches
        if (NOT URHO3D_LIB_64BIT EQUAL URHO3D_FOUND_64BIT OR NOT URHO3D_LIB_TYPE STREQUAL "${URHO3D_FOUND_LIB_TYPE}" OR
            NOT URHO3D_BASE_INCLUDE_DIR MATCHES "^${URHO3D_HOME}/include/Urho3D$")
            unset (URHO3D_LIB_TYPE CACHE)
            unset (URHO3D_BASE_INCLUDE_DIR CACHE)
            unset (URHO3D_LIBRARIES CACHE)
            unset (URHO3D_FOUND_64BIT CACHE)
            unset (URHO3D_FOUND_LIB_TYPE CACHE)
            unset (URHO3D_COMPILE_RESULT CACHE)
            if (WIN32)
                unset (URHO3D_LIBRARIES_DBG CACHE)
                unset (URHO3D_DLL_REL CACHE)
                unset (URHO3D_DLL_DBG CACHE)
            endif ()
            # Urho3D prefers static library type by default while CMake prefers shared one, so we need to change CMake preference to agree with Urho3D
            set (CMAKE_FIND_LIBRARY_SUFFIXES_SAVED ${CMAKE_FIND_LIBRARY_SUFFIXES})
            if (NOT CMAKE_FIND_LIBRARY_SUFFIXES MATCHES ^\\.\(a|lib\))
                list (REVERSE CMAKE_FIND_LIBRARY_SUFFIXES)
            endif ()
            # The PATH_SUFFIX does not work for CMake on Windows host system, it actually needs a prefix instead
            if (CMAKE_HOST_WIN32)
                set (CMAKE_SYSTEM_PREFIX_PATH_SAVED ${CMAKE_SYSTEM_PREFIX_PATH})
                string (REPLACE ";" "\\Urho3D;" CMAKE_SYSTEM_PREFIX_PATH "${CMAKE_SYSTEM_PREFIX_PATH_SAVED};")    # Stringify for string replacement
                if (NOT URHO3D_LIB_64BIT)
                    list (REVERSE CMAKE_SYSTEM_PREFIX_PATH)
                endif ()
            endif ()
        endif ()

        # URHO3D_HOME variable should be an absolute path, so use a non-rooted search even when we are cross-compiling
        if (URHO3D_HOME)
            list (APPEND CMAKE_PREFIX_PATH ${URHO3D_HOME})
            set (SEARCH_OPT NO_CMAKE_FIND_ROOT_PATH)
        endif ()

        if (NOT URHO3D_BASE_INCLUDE_DIR)
            find_path (URHO3D_BASE_INCLUDE_DIR Urho3D.h PATH_SUFFIXES ${PATH_SUFFIX} ${SEARCH_OPT} DOC "Urho3D include directory")
        endif ()
    endif ()

    # Set URHO3D_INCLUDE_DIRS
    if (URHO3D_BASE_INCLUDE_DIR)
        get_filename_component (URHO3D_INCLUDE_DIRS ${URHO3D_BASE_INCLUDE_DIR} DIRECTORY)
        if (NOT URHO3D_HOME)
            # URHO3D_HOME is not set when using SDK installed on system-wide default location, so set it now
            get_filename_component (URHO3D_HOME ${URHO3D_INCLUDE_DIRS} DIRECTORY)
        endif ()
        list (APPEND URHO3D_INCLUDE_DIRS ${URHO3D_BASE_INCLUDE_DIR}/ThirdParty)
    endif ()

    # Set URHO3D_LIBRARIES
    if (URHO3D_BASE_INCLUDE_DIR AND NOT URHO3D_LIBRARIES AND NOT SKIP_FIND_LIBRARIES)
        # Some checks on the lib type.
        if (MSVC)
            # The library type is baked into export header only for MSVC as it has no other way to differentiate them, fortunately both types cannot coexist for MSVC anyway unlike other compilers
            # MSVC static lib and import lib have a same extension '.lib', so cannot use it for searches 
            file (STRINGS ${URHO3D_BASE_INCLUDE_DIR}/Urho3D.h MSVC_STATIC_LIB REGEX "^#define URHO3D_STATIC_DEFINE$")
            if (MSVC_STATIC_LIB)
                set (URHO3D_LIB_TYPE STATIC)
            else ()
                set (URHO3D_LIB_TYPE SHARED)
            endif ()
        else ()
            # If library type is specified then only search for the requested library type
            if (URHO3D_LIB_TYPE)
                if (URHO3D_LIB_TYPE STREQUAL STATIC)
                    set (CMAKE_FIND_LIBRARY_SUFFIXES .a)
                elseif (URHO3D_LIB_TYPE STREQUAL SHARED)
                    if (MINGW)
                        set (CMAKE_FIND_LIBRARY_SUFFIXES .dll.a)
                    elseif (APPLE)
                        set (CMAKE_FIND_LIBRARY_SUFFIXES .dylib)
                    else ()
                        set (CMAKE_FIND_LIBRARY_SUFFIXES .so)
                    endif ()
                else ()
                    message (FATAL_ERROR "Library type: '${URHO3D_LIB_TYPE}' is not supported")
                    unset (URHO3D_LIB_TYPE)
                    unset (URHO3D_LIB_TYPE CACHE)    # Not a right type, don't search the lib
                endif ()
            else ()
                set (CMAKE_FIND_LIBRARY_SUFFIXES .a;.dll.a;.dylib;.so)
            endif ()
        endif ()

        # Find the libraries
        if (URHO3D_LIB_64BIT)
            set_property (GLOBAL PROPERTY FIND_LIBRARY_USE_LIB64_PATHS TRUE)
        else ()
            message (DEBUG "Try to find Urho3D's ${URHO3D_LIB_TYPE} 32Bit libraries")
        endif ()

        find_library (URHO3D_LIBRARIES NAMES Urho3D PATH_SUFFIXES ${PATH_SUFFIX} ${SEARCH_OPT} DOC "Urho3D library")

        if (WIN32)
            if (URHO3D_LIBRARIES)
                set (URHO3D_LIBRARIES_REL ${URHO3D_LIBRARIES})
            endif ()

            # For Windows platform, search for a debug version of the library too
            find_library (URHO3D_LIBRARIES_DBG NAMES Urho3D_d PATH_SUFFIXES ${PATH_SUFFIX} ${SEARCH_OPT})
            if (URHO3D_LIBRARIES_DBG-NOTFOUND)
                unset (URHO3D_LIBRARIES_DBG CACHE)
            endif ()                
            if (NOT URHO3D_LIBRARIES AND URHO3D_LIBRARIES_DBG)
                set (URHO3D_LIBRARIES ${URHO3D_LIBRARIES_DBG})
            endif ()
        endif ()

        # For shared library type, also initialize the URHO3D_DLL variable for later use
        if (WIN32 AND "${URHO3D_LIB_TYPE}" STREQUAL "SHARED" AND URHO3D_HOME)
            find_file (URHO3D_DLL_REL Urho3D.dll HINTS ${URHO3D_HOME}/bin NO_DEFAULT_PATH NO_CMAKE_FIND_ROOT_PATH DOC "Urho3D release DLL")
            if (URHO3D_DLL_REL)
                list (APPEND URHO3D_DLL ${URHO3D_DLL_REL})
            endif ()
            find_file (URHO3D_DLL_DBG Urho3D_d.dll HINTS ${URHO3D_HOME}/bin NO_DEFAULT_PATH NO_CMAKE_FIND_ROOT_PATH DOC "Urho3D debug DLL")
            if (URHO3D_DLL_DBG)
                list (APPEND URHO3D_DLL ${URHO3D_DLL_DBG})
            endif ()
        endif ()
        # Check if the librairies have the required architecture.
        if (URHO3D_LIBRARIES)
            foreach (CANDIDATE_URHO3D_LIBRARY ${URHO3D_LIBRARIES})
                set (COMPILE_TEST 1)
                # Apple does not support 32-bit ARM anymore so skip the test and always assume to be arm64
                if (APPLE AND ARM)
                    set (URHO3D_COMPILE_RESULT 1)
                    set (COMPILE_TEST 0)
                endif ()

                if (COMPILE_TEST)
                    # prepare the compile_test
                    if (NOT (MSVC OR ANDROID OR ARM OR WEB OR XCODE) AND NOT URHO3D_LIB_64BIT)
                        set (COMPILER_32BIT_FLAG -m32)
                    endif ()
                    if (NOT URHO3D_LIB_TYPE)
                        get_filename_component (libsuffix ${CANDIDATE_URHO3D_LIBRARY} EXT)
                        if (libsuffix STREQUAL .a)
                            set (COMPILER_STATIC_DEFINE COMPILE_DEFINITIONS -DURHO3D_STATIC_DEFINE)
                        endif ()
                    elseif (URHO3D_LIB_TYPE STREQUAL STATIC)
                        set (COMPILER_STATIC_DEFINE COMPILE_DEFINITIONS -DURHO3D_STATIC_DEFINE)
                    endif ()
                    set (COMPILER_FLAGS "${COMPILER_32BIT_FLAG} ${CMAKE_REQUIRED_FLAGS}")
                    if (WIN32)
                        set (CMAKE_TRY_COMPILE_CONFIGURATION_SAVED ${CMAKE_TRY_COMPILE_CONFIGURATION})
                        if (URHO3D_LIBRARIES_REL)
                            set (CMAKE_TRY_COMPILE_CONFIGURATION Release)
                        else ()
                            set (CMAKE_TRY_COMPILE_CONFIGURATION Debug)
                        endif ()
                    endif ()
                    # launch the compile_test
                    while (NOT URHO3D_COMPILE_RESULT)
                        try_compile (URHO3D_COMPILE_RESULT ${CMAKE_BINARY_DIR} ${CMAKE_CURRENT_LIST_DIR}/CheckUrhoLibrary.cpp
                                    CMAKE_FLAGS -DCOMPILE_DEFINITIONS:STRING=${COMPILER_FLAGS} -DLINK_LIBRARIES:STRING=${CANDIDATE_URHO3D_LIBRARY} -DINCLUDE_DIRECTORIES:STRING=${URHO3D_INCLUDE_DIRS} ${COMPILER_STATIC_DEFINE} ${COMPILER_STATIC_RUNTIME_FLAGS}
                                    OUTPUT_VARIABLE TRY_COMPILE_OUT)
                        if (MSVC AND NOT URHO3D_COMPILE_RESULT AND NOT COMPILER_STATIC_RUNTIME_FLAGS)
                            # Give a second chance for MSVC to use static runtime flag
                            if (URHO3D_LIBRARIES_REL)
                                set (COMPILER_STATIC_RUNTIME_FLAGS COMPILE_DEFINITIONS /MT)
                            else ()
                                set (COMPILER_STATIC_RUNTIME_FLAGS COMPILE_DEFINITIONS /MTd)
                            endif ()
                        else ()
                            break ()    # Other compilers break immediately rendering the while-loop a no-ops
                        endif ()
                    endwhile ()
                endif ()

                set (URHO3D_COMPILE_RESULT ${URHO3D_COMPILE_RESULT} CACHE INTERNAL "FindUrho3D module's compile result")
                if (URHO3D_COMPILE_RESULT)
                    set (URHO3D_LIBRARIES ${CANDIDATE_URHO3D_LIBRARY})
                    if (NOT URHO3D_LIB_TYPE)
                        # get the lib type of the found library from its extension
                        if (libsuffix STREQUAL .a)
                            set (URHO3D_LIB_TYPE STATIC)
                        else ()
                            set (URHO3D_LIB_TYPE SHARED)
                        endif ()
                    endif ()
                    break ()
                endif ()
            endforeach ()

            if (NOT URHO3D_COMPILE_RESULT)
                unset (URHO3D_LIBRARIES CACHE)
            endif ()
        endif ()
    endif ()

    if (URHO3D_LIBRARIES)
        set (URHO3D_64BIT ${URHO3D_LIB_64BIT} CACHE BOOL "Enable 64-bit build, the value is auto-discovered based on the found Urho3D library" FORCE)
        set (URHO3D_LIB_TYPE ${URHO3D_LIB_TYPE} CACHE STRING "Urho3D library type, the value is auto-discovered based on the found Urho3D library" FORCE)

        # Auto-discover build options written in export header Urho3D.h

        file (STRINGS ${URHO3D_BASE_INCLUDE_DIR}/Urho3D.h EXPORT_HEADER)

        if (MSVC AND COMPILER_STATIC_RUNTIME_FLAGS)
            set (EXPORT_HEADER "${EXPORT_HEADER}#define URHO3D_STATIC_RUNTIME\n")
        endif ()

        set (AUTO_DISCOVER_VARS
            URHO3D_STATIC_DEFINE URHO3D_OPENGL URHO3D_D3D11 URHO3D_SSE URHO3D_DATABASE_ODBC 
            URHO3D_DATABASE_SQLITE URHO3D_LUAJIT URHO3D_TESTING CLANG_PRE_STANDARD URHO3D_STATIC_RUNTIME 
            URHO3D_SPINE WAYLAND_CLIENT URHO3D_ANGELSCRIPT URHO3D_LUA URHO3D_LUAJIT URHO3D_IK URHO3D_NAVIGATION URHO3D_NETWORK 
            URHO3D_PHYSICS URHO3D_PHYSICS2D URHO3D_URHO2D URHO3D_WEBP URHO3D_LOGGING URHO3D_PROFILING URHO3D_TRACY_PROFILING
        )

        if (EXPORT_HEADER MATCHES "#define AS_MAX_PORTABILITY")
            set (AUTO_DISCOVERED_URHO3D_FORCE_AS_MAX_PORTABILITY 1)
        else ()
            set (AUTO_DISCOVERED_URHO3D_FORCE_AS_MAX_PORTABILITY 0)
        endif ()
        set (AUTO_DISCOVERED_URHO3D_FORCE_AS_MAX_PORTABILITY ${AUTO_DISCOVERED_URHO3D_FORCE_AS_MAX_PORTABILITY} CACHE INTERNAL "Auto-discovered URHO3D_FORCE_AS_MAX_PORTABILITY build option")

        foreach (VAR ${AUTO_DISCOVER_VARS})
            if (EXPORT_HEADER MATCHES "#define ${VAR}")
                set (AUTO_DISCOVERED_${VAR} 1)
            else ()
                set (AUTO_DISCOVERED_${VAR} 0)
            endif ()
            set (AUTO_DISCOVERED_${VAR} ${AUTO_DISCOVERED_${VAR}} CACHE INTERNAL "Auto-discovered ${VAR} build option")
        endforeach ()

        # Ensure auto-discovered variables always prevail over user settings in all the subsequent cmake rerun (even without redoing try_compile)
        foreach (VAR ${AUTO_DISCOVER_VARS})
            if (DEFINED ${VAR} AND DEFINED AUTO_DISCOVERED_${VAR})
                get_property(VAR_TYPE CACHE ${VAR} PROPERTY TYPE)
                get_property(VAR_DOC CACHE ${VAR} PROPERTY HELPSTRING)
                message (DEBUG "${VAR} value=${AUTO_DISCOVERED_${VAR}} cached_type=${VAR_TYPE} cached_doc=${VAR_DOC}")
                if (VAR_TYPE)
                    set (${VAR} ${AUTO_DISCOVERED_${VAR}} CACHE ${VAR_TYPE} ${VAR_DOC} FORCE)
                endif ()
            endif ()
            set (${VAR} ${AUTO_DISCOVERED_${VAR}})            
        endforeach ()

        # Append Physics And Lua Thirdparty include dirs if their option are enabled
        if (URHO3D_PHYSICS)
            list (APPEND URHO3D_INCLUDE_DIRS ${URHO3D_BASE_INCLUDE_DIR}/ThirdParty/Bullet)
        endif ()
        if (URHO3D_LUA)
            list (APPEND URHO3D_INCLUDE_DIRS ${URHO3D_BASE_INCLUDE_DIR}/ThirdParty/Lua${JIT})
        endif ()

        # If both the non-debug and debug version of the libraries are found on Windows platform then use them both
        if (URHO3D_LIBRARIES_REL AND URHO3D_LIBRARIES_DBG)
            set (URHO3D_LIBRARIES ${URHO3D_LIBRARIES_REL} ${URHO3D_LIBRARIES_DBG})
        endif ()
    endif ()

    # Intentionally do not cache the URHO3D_VERSION as it has potential to change frequently
    file (STRINGS "${URHO3D_BASE_INCLUDE_DIR}/librevision.h" URHO3D_VERSION REGEX "^const char\\* revision=\"[^\"]*\".*$")
    string (REGEX REPLACE "^const char\\* revision=\"([^\"]*)\".*$" \\1 URHO3D_VERSION "${URHO3D_VERSION}")      # Stringify to guard against empty variable

    # Restore CMake global settings
    if (CMAKE_FIND_LIBRARY_SUFFIXES_SAVED)
        set (CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_FIND_LIBRARY_SUFFIXES_SAVED})
    endif ()
    if (CMAKE_SYSTEM_PREFIX_PATH_SAVED)
        set (CMAKE_SYSTEM_PREFIX_PATH ${CMAKE_SYSTEM_PREFIX_PATH_SAVED})
    endif ()
    if (CMAKE_TRY_COMPILE_CONFIGURATION_SAVED)
        set (CMAKE_TRY_COMPILE_CONFIGURATION ${CMAKE_TRY_COMPILE_CONFIGURATION_SAVED})
    endif ()
endif ()

if (URHO3D_INCLUDE_DIRS AND URHO3D_LIBRARIES AND URHO3D_COMPILE_RESULT)
    set (URHO3D_FOUND 1)
    if (NOT FOUND_MESSAGE)
        set (FOUND_MESSAGE "Found Urho3D: ${URHO3D_LIBRARIES}")
        if (URHO3D_VERSION)
            set (FOUND_MESSAGE "${FOUND_MESSAGE} (found version \"${URHO3D_VERSION}\")")
        endif ()
    endif ()
    include (FindPackageMessage)
    find_package_message (Urho3D ${FOUND_MESSAGE} "[${URHO3D_LIBRARIES}][${URHO3D_INCLUDE_DIRS}]")
    set (URHO3D_HOME ${URHO3D_HOME} CACHE PATH "Path to Urho3D build tree or SDK installation location" FORCE)
    set (URHO3D_FOUND_64BIT ${URHO3D_64BIT} CACHE INTERNAL "True when 64-bit ABI was being used when test compiling Urho3D library")
    set (URHO3D_FOUND_LIB_TYPE ${URHO3D_LIB_TYPE} CACHE INTERNAL "Lib type (if specified) when Urho3D library was last found")
elseif (Urho3D_FIND_REQUIRED)
    if (ANDROID)
        set (NOT_FOUND_MESSAGE "For Android platform, double check if you have specified to use the same ANDROID_ABI as the Urho3D Android Library, especially when you are not using universal AAR.")
    endif ()
    if (URHO3D_LIB_TYPE)
        set (NOT_FOUND_MESSAGE "Ensure the specified location contains the Urho3D library of the requested library type. ${NOT_FOUND_MESSAGE}")
    endif ()
    message (FATAL_ERROR
        "Could NOT find compatible Urho3D library in Urho3D SDK installation or build tree or in Android library. "
        "Use URHO3D_HOME environment variable or build option to specify the location of the non-default SDK installation or build tree. ${NOT_FOUND_MESSAGE} ${TRY_COMPILE_OUT}")
endif ()

mark_as_advanced (URHO3D_BASE_INCLUDE_DIR URHO3D_LIBRARIES URHO3D_LIBRARIES_DBG URHO3D_DLL_REL URHO3D_DLL_DBG)
