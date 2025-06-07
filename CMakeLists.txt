cmake_minimum_required(VERSION 3.10)
project(mysql_looper)

set(CMAKE_C_STANDARD 11)

# Add executable targets
add_executable(mysql_looper mysql_looper.c)
add_executable(mysql_looperd mysql_looperd.c)

# Try mariadb_config first, then fallback to mysql_config
execute_process(COMMAND mariadb_config --cflags OUTPUT_VARIABLE MYSQL_CFLAGS OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
execute_process(COMMAND mariadb_config --libs OUTPUT_VARIABLE MYSQL_LIBS OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)

# If mariadb_config failed, try mysql_config
if(NOT MYSQL_CFLAGS OR NOT MYSQL_LIBS)
    execute_process(COMMAND mysql_config --cflags OUTPUT_VARIABLE MYSQL_CFLAGS OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
    execute_process(COMMAND mysql_config --libs OUTPUT_VARIABLE MYSQL_LIBS OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
endif()

# Set compilation flags and link libraries for both targets
if(MYSQL_CFLAGS)
    string(REPLACE " " ";" MYSQL_CFLAGS_LIST ${MYSQL_CFLAGS})
    target_compile_options(mysql_looper PRIVATE ${MYSQL_CFLAGS_LIST})
    target_compile_options(mysql_looperd PRIVATE ${MYSQL_CFLAGS_LIST})
endif()

if(MYSQL_LIBS)
    string(REPLACE " " ";" MYSQL_LIBS_LIST ${MYSQL_LIBS})
    target_link_libraries(mysql_looper PRIVATE ${MYSQL_LIBS_LIST})
    target_link_libraries(mysql_looperd PRIVATE ${MYSQL_LIBS_LIST})
endif()

# Set HAVE_MARIADB build flag if using MariaDB
if(MYSQL_CFLAGS MATCHES ".*mariadb.*")
    target_compile_definitions(mysql_looper PRIVATE HAVE_MARIADB)
    target_compile_definitions(mysql_looperd PRIVATE HAVE_MARIADB)
endif()