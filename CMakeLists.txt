cmake_minimum_required(VERSION 3.10)
project(mysql_looper)

set(CMAKE_C_STANDARD 11)

# Add the executable targets
add_executable(mysql_looper mysql_looper.c)
add_executable(mysql_looperd mysql_looperd.c)

# Execute mysql_config to get compilation flags and libraries, prefer mariadb_config if available
find_program(MARIADB_CONFIG mariadb_config)
find_program(MYSQL_CONFIG mysql_config)

if(MARIADB_CONFIG)
    execute_process(COMMAND ${MARIADB_CONFIG} --cflags OUTPUT_VARIABLE MYSQL_CFLAGS OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
    execute_process(COMMAND ${MARIADB_CONFIG} --libs OUTPUT_VARIABLE MYSQL_LIBS OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
    message(STATUS "Using mariadb_config for configuration")
elseif(MYSQL_CONFIG)
    execute_process(COMMAND ${MYSQL_CONFIG} --cflags OUTPUT_VARIABLE MYSQL_CFLAGS OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
    execute_process(COMMAND ${MYSQL_CONFIG} --libs OUTPUT_VARIABLE MYSQL_LIBS OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
    message(STATUS "Using mysql_config for configuration")
else()
    # Fallback to pkg-config or manual setup
    find_package(PkgConfig QUIET)
    if(PkgConfig_FOUND)
        pkg_check_modules(MARIADB mariadb)
        if(MARIADB_FOUND)
            set(MYSQL_CFLAGS "${MARIADB_CFLAGS}")
            set(MYSQL_LIBS "${MARIADB_LDFLAGS}")
            message(STATUS "Using pkg-config mariadb")
        endif()
    endif()
endif()

# Set compilation flags for both targets
if(MYSQL_CFLAGS)
    string(REPLACE " " ";" MYSQL_CFLAGS_LIST ${MYSQL_CFLAGS})
    target_compile_options(mysql_looper PRIVATE ${MYSQL_CFLAGS_LIST})
    target_compile_options(mysql_looperd PRIVATE ${MYSQL_CFLAGS_LIST})
endif()

# Link against the MySQL Connector/C library for both targets
if(MYSQL_LIBS)
    string(REPLACE " " ";" MYSQL_LIBS_LIST ${MYSQL_LIBS})
    target_link_libraries(mysql_looper PRIVATE ${MYSQL_LIBS_LIST})
    target_link_libraries(mysql_looperd PRIVATE ${MYSQL_LIBS_LIST})
endif()

# set HAVE_MARIADB build flag and link their corresponding static libraries
if (MYSQL_CFLAGS MATCHES ".*mariadb.*")
    include_directories(/usr/include/mariadb)
    target_compile_definitions(mysql_looper PRIVATE HAVE_MARIADB)
    target_compile_definitions(mysql_looperd PRIVATE HAVE_MARIADB)
    add_library(mariadb STATIC IMPORTED)
    set_property(TARGET mariadb PROPERTY IMPORTED_LOCATION /usr/lib/x86_64-linux-gnu/libmariadbclient.a)
    target_link_libraries(mysql_looper PRIVATE mariadb)
    target_link_libraries(mysql_looperd PRIVATE mariadb)
endif()