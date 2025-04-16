# Set CMake minimum version
cmake_minimum_required (VERSION 3.10.2)
 
# Set project name
project (Duality)

include (${CMAKE_SOURCE_DIR}/cmake/Urho3D.cmake)

if (URHO3D_HOME)
	add_subdirectory(src)
else ()
	message ("!! Duality - wait to add source because URHO3D_HOME is undefined here !")
endif ()
