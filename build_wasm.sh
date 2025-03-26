#!/usr/bin/env bash
set -uex

# Check if emcmake is available
command -v emcmake > /dev/null

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
WITH_NODE_RAW_FS=${1:-OFF}

cd $SCRIPT_DIR

cp third_party/onnxruntime/cmake/external/flatbuffers/include/flatbuffers/flatbuffers.h third_party/onnxruntime/cmake/external/flatbuffers/include/flatbuffers/flatbuffers.h.bak

if patch --dry-run third_party/onnxruntime/cmake/external/flatbuffers/include/flatbuffers/flatbuffers.h < flatbuffers.patch > /dev/null 2>&1; then
    echo "Patch validation successful: Applying patch."
    patch third_party/onnxruntime/cmake/external/flatbuffers/include/flatbuffers/flatbuffers.h < flatbuffers.patch
    echo "Patch applied successfully."
else
    echo "Error: Cannot apply patch. Original file remains unchanged."
    exit 1
fi

pushd third_party/onnxruntime/cmake/external/protobuf/cmake
mkdir -p build
cd build
cmake -Dprotobuf_BUILD_TESTS=OFF -Dprotobuf_WITH_ZLIB_DEFAULT=OFF -Dprotobuf_BUILD_SHARED_LIBS=OFF -GNinja ..
ninja protoc
PROTOC=`pwd`/protoc
popd

mkdir -p build-wasm-node-$WITH_NODE_RAW_FS
cd build-wasm-node-$WITH_NODE_RAW_FS
emcmake cmake -DONNX_CUSTOM_PROTOC_EXECUTABLE=$PROTOC -DONNXSIM_WASM_NODE=$WITH_NODE_RAW_FS -GNinja -DCMAKE_BUILD_TYPE=Release ..
ninja onnxsim_bin
