cmake_minimum_required(VERSION 3.15)
project(cariboulite)
set(CMAKE_BUILD_TYPE Release)

# Bring the headers
set(SUPER_DIR ${PROJECT_SOURCE_DIR}/..)
include_directories(/.)
include_directories(${SUPER_DIR})

# Source files
set(SOURCES_LIB caribou_fpga.c)
set(SOURCES ${SOURCES_LIB} test_caribou_fpga.c)
set(EXTERN_LIBS 
	${SUPER_DIR}/io_utils/build/libio_utils.a
	${SUPER_DIR}/caribou_programming/build/libcaribou_prog.a
	${SUPER_DIR}/zf_log/build/libzf_log.a 
	-lpthread)
#add_compile_options(-Wall -Wextra -pedantic -Werror)
add_compile_options(-Wall -Wextra -Wno-unused-parameter -Wno-missing-braces)

#Generate the static library from the sources
add_library(caribou_fpga STATIC ${SOURCES_LIB})
add_executable(test_caribou_fpga ${SOURCES})
target_link_libraries(test_caribou_fpga rt pthread ${EXTERN_LIBS})

# Set the location for library installation -- i.e., /usr/lib in this case
# not really necessary in this example. Use "sudo make install" to apply
install(TARGETS caribou_fpga DESTINATION /usr/lib)