# Set CMake minimum version
cmake_minimum_required (VERSION 3.10.2)
 
# Set project name
project (Duality)

# If need add URHO3D_HOME here or U3D will be fetch from github repo
#set (URHO3D_HOME ${CMAKE_SOURCE_DIR}/../U3D)

include (${CMAKE_SOURCE_DIR}/cmake/Urho3D.cmake)

if (URHO3D_HOME)
	add_subdirectory(src)
else ()
	message ("!! Duality - wait to add source because URHO3D_HOME is undefined here !")
endif ()
