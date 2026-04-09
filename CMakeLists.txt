cmake_minimum_required(VERSION 3.14)
project(
  cereal-xtensor
  VERSION 1.3.2
  LANGUAGES CXX)
include(GNUInstallDirs)
add_library(cereal-xtensor INTERFACE)
target_include_directories(cereal-xtensor INTERFACE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)
target_link_libraries(cereal-xtensor
  INTERFACE
    cereal
    xtensor)
install(TARGETS cereal-xtensor
  EXPORT cereal-xtensor-targets
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

install(DIRECTORY include/cereal-xtensor
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
  FILES_MATCHING
    PATTERN "*.hpp"
    PATTERN "*.h"
)

write_basic_package_version_file(
  "${CMAKE_CURRENT_BINARY_DIR}/cereal-xtensor-config-version.cmake"
  VERSION ${PROJECT_VERSION}
  COMPATIBILITY AnyNewerVersion
)

install(EXPORT cereal-xtensor-targets
  FILE      cereal-xtensor-targets.cmake
  NAMESPACE cereal-xtensor::
  DESTINATION ${CMAKE_INSTALL_DATADIR}/cereal-xtensor
)
configure_package_config_file(
  cmake/cereal-xtensor-config.cmake.in
  "${CMAKE_CURRENT_BINARY_DIR}/cereal-xtensor-config.cmake"
  INSTALL_DESTINATION ${CMAKE_INSTALL_DATADIR}/cereal-xtensor
)
install(FILES
  "${CMAKE_CURRENT_BINARY_DIR}/cereal-xtensor-config.cmake"
  "${CMAKE_CURRENT_BINARY_DIR}/cereal-xtensor-config-version.cmake"
  DESTINATION ${CMAKE_INSTALL_DATADIR}/cereal-xtensor
)
