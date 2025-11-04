#!/bin/bash
# Docker-based build script for Cataclysm-BN on macOS
# Translates the atomic_cmake guide to use Docker instead of toolbox

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"
IMAGE_NAME="cataclysm-bn-fedora-builder"

# Function to build the Docker image
build_image() {
    echo "Building Docker image..."
    docker build -t "$IMAGE_NAME" -f "$SCRIPT_DIR/Dockerfile.fedora" "$SCRIPT_DIR"
}

# Function to run CMake configuration
configure() {
    echo "Running CMake configuration..."
    docker run --rm -it \
        -v "$PROJECT_ROOT:/workspace" \
        -w /workspace \
        "$IMAGE_NAME" \
        cmake \
            -B build \
            -G Ninja \
            -DCATA_CCACHE=ON \
            -DCMAKE_C_COMPILER=clang \
            -DCMAKE_CXX_COMPILER=clang++ \
            -DCMAKE_INSTALL_PREFIX=/workspace/install \
            -DJSON_FORMAT=ON \
            -DCMAKE_BUILD_TYPE=RelWithDebInfo \
            -DCURSES=OFF \
            -DTILES=ON \
            -DSOUND=ON \
            -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
            -DCATA_CLANG_TIDY_PLUGIN=OFF \
            -DLUA=ON \
            -DBACKTRACE=ON \
            -DLINKER=mold \
            -DUSE_XDG_DIR=OFF \
            -DUSE_HOME_DIR=OFF \
            -DUSE_PREFIX_DATA_DIR=ON
}

# Function to build the project
build() {
    echo "Building Cataclysm-BN..."
    docker run --rm -it \
        -v "$PROJECT_ROOT:/workspace" \
        -w /workspace \
        "$IMAGE_NAME" \
        ninja -C build -j $(sysctl -n hw.ncpu) -k 0 cataclysm-bn-tiles
}

# Function to enter the container shell
shell() {
    echo "Entering Docker container shell..."
    docker run --rm -it \
        -v "$PROJECT_ROOT:/workspace" \
        -w /workspace \
        "$IMAGE_NAME" \
        /bin/bash
}

# Function to clean build artifacts
clean() {
    echo "Cleaning build directory..."
    rm -rf "$PROJECT_ROOT/build"
}

# Main script logic
case "${1:-build}" in
    image)
        build_image
        ;;
    configure)
        configure
        ;;
    build)
        build
        ;;
    all)
        build_image
        configure
        build
        ;;
    shell)
        shell
        ;;
    clean)
        clean
        ;;
    *)
        echo "Usage: $0 {image|configure|build|all|shell|clean}"
        echo ""
        echo "Commands:"
        echo "  image      - Build the Docker image"
        echo "  configure  - Run CMake configuration"
        echo "  build      - Build the project"
        echo "  all        - Build image, configure, and build project"
        echo "  shell      - Enter container shell for manual commands"
        echo "  clean      - Remove build directory"
        exit 1
        ;;
esac
