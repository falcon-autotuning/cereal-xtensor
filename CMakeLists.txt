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
install(
    DIRECTORY include/
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)
install(
    TARGETS cereal-xtensor
    EXPORT cereal-xtensor-targets
)
install(
    EXPORT cereal-xtensor-targets
    FILE cereal-xtensor-targets.cmake
    NAMESPACE cereal_xtensor::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/cereal-xtensor
)
include(CMakePackageConfigHelpers)
configure_package_config_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/cereal-xtensor-config.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/cereal-xtensor-config.cmake
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/cereal-xtensor
)
install(
    FILES
        ${CMAKE_CURRENT_BINARY_DIR}/cereal-xtensor-config.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/cereal-xtensor
)
