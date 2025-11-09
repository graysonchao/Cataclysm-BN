# macOS Native Build Script

Native build script for Cataclysm-BN on macOS using CMake and Ninja.

## Prerequisites

Install build dependencies via Homebrew:

```bash
brew install ninja ccache sdl2 sdl2_image sdl2_ttf sdl2_mixer gettext sqlite3
```

## Usage

From the project root directory:

```bash
./build-scripts/mac/build-native.sh <command>
```

### Commands

- **`configure`** - Run CMake configuration
- **`build`** - Build the project (requires configure first)
- **`all`** - Clean, configure, build, and run
- **`run`** - Run the game
- **`clean`** - Remove build directory

### Examples

```bash
# First time build
./build-scripts/mac/build-native.sh all

# Incremental rebuild after code changes
./build-scripts/mac/build-native.sh build

# Just run the game
./build-scripts/mac/build-native.sh run
```

## Build Configuration

The script configures CMake with the following options:

- **Compiler**: Clang (Apple's default)
- **Build Type**: RelWithDebInfo (optimized with debug symbols)
- **Features**: Tiles, Sound, Lua scripting
- **Optimizations**: ccache enabled, parallel builds using all CPU cores
- **Data Directory**: Uses `USE_HOME_DIR=ON` (saves in `~/Library/Application Support/Cataclysm-BN`)

## Output

- **Binary**: `build/src/cataclysm-bn-tiles`
- **Compile commands**: `build/compile_commands.json` (for IDE integration)

## Troubleshooting

### Build fails with missing dependencies

Make sure all Homebrew packages are installed:
```bash
brew install ninja ccache sdl2 sdl2_image sdl2_ttf sdl2_mixer gettext sqlite3
```

### Need to rebuild from scratch

```bash
./build-scripts/mac/build-native.sh clean
./build-scripts/mac/build-native.sh configure
./build-scripts/mac/build-native.sh build
```

Or simply:
```bash
./build-scripts/mac/build-native.sh all
```
