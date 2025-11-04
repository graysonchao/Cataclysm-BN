#!/bin/bash
# Native macOS build script using CMake
# For macOS ARM (Apple Silicon) systems

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

cd "$PROJECT_ROOT"

# Function to configure the build
configure() {
    echo "Configuring native macOS ARM build..."
    cmake \
        -B build \
        -G Ninja \
        -DCATA_CCACHE=ON \
        -DCMAKE_C_COMPILER=clang \
        -DCMAKE_CXX_COMPILER=clang++ \
        -DCMAKE_INSTALL_PREFIX="$HOME/.local/share" \
        -DJSON_FORMAT=ON \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DCURSES=OFF \
        -DTILES=ON \
        -DSOUND=ON \
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
        -DCATA_CLANG_TIDY_PLUGIN=OFF \
        -DLUA=ON \
        -DBACKTRACE=ON \
        -DUSE_XDG_DIR=OFF \
        -DUSE_HOME_DIR=ON \
        -DUSE_PREFIX_DATA_DIR=OFF
}

# Function to build
build() {
    echo "Building Cataclysm-BN natively..."
    ninja -C build -j $(sysctl -n hw.ncpu) -k 0 cataclysm-bn-tiles
}

# Function to run the game
run() {
    echo "Running Cataclysm-BN..."
    ./build/src/cataclysm-bn-tiles
}

# Function to clean
clean() {
    echo "Cleaning build directory..."
    rm -rf build
}

# Main script logic
case "${1:-build}" in
    configure)
        configure
        ;;
    build)
        build
        ;;
    all)
        clean
        configure
        build
        run
        ;;
    run)
        run
        ;;
    clean)
        clean
        ;;
    *)
        echo "Usage: $0 {configure|build|all|run|clean}"
        echo ""
        echo "Commands:"
        echo "  configure  - Run CMake configuration"
        echo "  build      - Build the project"
        echo "  all        - Configure and build"
        echo "  run        - Run the game"
        echo "  clean      - Remove build directory"
        exit 1
        ;;
esac
