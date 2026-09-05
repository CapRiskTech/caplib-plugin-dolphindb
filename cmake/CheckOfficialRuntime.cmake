# Usage:
# cmake "-DLIBRARY_FILES=/path/libPluginCaplib.so;/path/libdqlibc.so" \
#       -P cmake/CheckOfficialRuntime.cmake
cmake_minimum_required(VERSION 3.22)

if(NOT LIBRARY_FILES)
    message(FATAL_ERROR "LIBRARY_FILES must name at least one ELF library")
endif()
if(NOT READELF)
    find_program(READELF NAMES readelf REQUIRED)
endif()

foreach(_library IN LISTS LIBRARY_FILES)
    if(NOT EXISTS "${_library}")
        message(FATAL_ERROR "Library does not exist: ${_library}")
    endif()
    execute_process(
        COMMAND "${CMAKE_COMMAND}" -E env LC_ALL=C
            "${READELF}" --wide --version-info "${_library}"
        RESULT_VARIABLE _result
        OUTPUT_VARIABLE _versions
        ERROR_VARIABLE _error
    )
    if(NOT _result EQUAL 0)
        message(FATAL_ERROR "Cannot inspect ${_library}: ${_error}")
    endif()
    # Inspect requirements, not version definitions exported by a library.
    if(_versions MATCHES "Version needs section")
        string(REGEX REPLACE ".*Version needs section" "" _needs "${_versions}")
    else()
        set(_needs "")
    endif()
    foreach(_family IN ITEMS GLIBCXX CXXABI)
        if(_family STREQUAL "GLIBCXX")
            set(_limit "3.4.25")
        else()
            set(_limit "1.3.11")
        endif()
        string(REGEX MATCHALL "${_family}_[0-9]+(\\.[0-9]+)+" _requirements "${_needs}")
        list(REMOVE_DUPLICATES _requirements)
        set(_maximum "0")
        foreach(_requirement IN LISTS _requirements)
            string(REPLACE "${_family}_" "" _version "${_requirement}")
            if(_version VERSION_GREATER _limit)
                message(FATAL_ERROR
                    "${_library} requires ${_requirement}; official v3.00.5 supports "
                    "at most ${_family}_${_limit}. Rebuild the full C++ dependency chain "
                    "with GCC 8; do not replace the server's libstdc++.so.6.")
            endif()
            if(_version VERSION_GREATER _maximum)
                set(_maximum "${_version}")
            endif()
        endforeach()
        message(STATUS "${_library}: maximum required ${_family}_${_maximum} (limit ${_limit})")
    endforeach()
endforeach()
