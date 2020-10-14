#!/bin/bash

export MACOSX_DEPLOYMENT_TARGET="10.12"

export LIBRARY_LIBRESSL_VERSION="3.1.4";
export LIBRARY_GPG_ERROR_VERSION="1.39"
export LIBRARY_GCRYPT_VERSION="1.8.6"
export LIBRARY_OTR_VERSION="4.1.1"

export LIBRARIES_TO_BUILD="libgpg-error libgcrypt libotr libressl"

export CURRENT_DIRECTORY=$(cd `dirname $0` && pwd)
export ROOT_DIRECTORY="/tmp/static-library-build-results"

export SHARED_RESULT_ROOT_LOCATION="${ROOT_DIRECTORY}/Library-Build-Results/"
export SHARED_RESULT_BINARY_LOCATION="${ROOT_DIRECTORY}/Library-Build-Results/bin"
export SHARED_RESULT_LIBRARY_LOCATION="${ROOT_DIRECTORY}/Library-Build-Results/lib"
export SHARED_RESULT_LIBRARY_STATIC_LOCATION="${ROOT_DIRECTORY}/Library-Build-Results/lib-static"
export SHARED_RESULT_LICENSE_LOCATION="${ROOT_DIRECTORY}/Library-Build-Results/license"
export SHARED_RESULT_INCLUDE_LOCATION="${ROOT_DIRECTORY}/Library-Build-Results/include"

LIBRARIES_THAT_DONT_EXIST=()

for LIBRARY_TO_BUILD in ${LIBRARIES_TO_BUILD[@]}
do
	if [ ! -f "${SHARED_RESULT_LIBRARY_STATIC_LOCATION}/${LIBRARY_TO_BUILD}.a" ]; then
		LIBRARIES_THAT_DONT_EXIST+=("${LIBRARY_TO_BUILD}")
	fi
done

if [ ${#LIBRARIES_THAT_DONT_EXIST[@]} == 0 ]; then
	echo "There is nothing to build..."
	
	exit 0;
fi 

export WORKING_DIRECTORY="${ROOT_DIRECTORY}/Library-Build-Source/"

export PATH="${PATH}:${SHARED_RESULT_BINARY_LOCATION}"

export PLATFORM_BUILD_SDK_ROOT_LOCATION=$(xcrun -sdk macosx --show-sdk-path)

export CC="clang"
export LDFLAGS="-L${SHARED_RESULT_LIBRARY_LOCATION}"
export CFLAGS=" -arch x86_64 -isysroot ${PLATFORM_BUILD_SDK_ROOT_LOCATION} -I${SHARED_RESULT_INCLUDE_LOCATION}"
export CPPFLAGS=" -arch x86_64 -isysroot ${PLATFORM_BUILD_SDK_ROOT_LOCATION} -I${SHARED_RESULT_INCLUDE_LOCATION}"

function deleteOldAndCreateDirectory {
	if [ -d "$1" ]; then
		rm -rf "$1"
	fi

	mkdir -p "$1"
}

function applyPatchesToLibrary {
	PATCH_DIRECTORY="${CURRENT_DIRECTORY}/Library Script Patches/$1"

	find "${PATCH_DIRECTORY}" -name "*.patch" -print0 | while read -d $'\0' file
	do
		patch -p0 --ignore-whitespace < "${file}"
	done
}

export -f applyPatchesToLibrary

deleteOldAndCreateDirectory "${WORKING_DIRECTORY}"
deleteOldAndCreateDirectory "${SHARED_RESULT_ROOT_LOCATION}"
deleteOldAndCreateDirectory "${SHARED_RESULT_LIBRARY_STATIC_LOCATION}"
deleteOldAndCreateDirectory "${SHARED_RESULT_LICENSE_LOCATION}"

open "${ROOT_DIRECTORY}"

for LIBRARY_TO_BUILD in ${LIBRARIES_THAT_DONT_EXIST[@]}
do
	export LIBRARY_WORKING_DIRECTORY_LOCATION="${WORKING_DIRECTORY}${LIBRARY_TO_BUILD}/"

	export COMMAND_MODE=unix2003

	deleteOldAndCreateDirectory "${LIBRARY_WORKING_DIRECTORY_LOCATION}"

	"${CURRENT_DIRECTORY}/Library Scripts/build_${LIBRARY_TO_BUILD}.sh"
done
