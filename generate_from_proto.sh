#!/bin/bash

# Script to download proto files from a GitHub repo and generate Go code

# Configuration
REPO_URL="https://github.com/triton-inference-server/common.git"
PROTO_PATH="protobuf"
TARGET_DIR="client/grpc/grpc_generated_v2"
TEMP_DIR="temp-repo"
GO_PACKAGE_PREFIX="github.com/Trendyol/go-triton-client/client/grpc/grpc_generated_v2"

# Check for required tools
command -v git >/dev/null 2>&1 || { echo "Error: git is required but not installed"; exit 1; }
command -v protoc >/dev/null 2>&1 || { echo "Error: protoc is required but not installed"; exit 1; }
command -v protoc-gen-go >/dev/null 2>&1 || { echo "Error: protoc-gen-go is required but not installed. Install with: go install google.golang.org/protobuf/cmd/protoc-gen-go@latest"; exit 1; }
command -v protoc-gen-go-grpc >/dev/null 2>&1 || { echo "Error: protoc-gen-go-grpc is required but not installed. Install with: go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest"; exit 1; }

# Create directories
mkdir -p "$TARGET_DIR"
mkdir -p "$TEMP_DIR"

echo "Cloning repository..."
git clone "$REPO_URL" "$TEMP_DIR" --depth 1

if [ ! -d "$TEMP_DIR/$PROTO_PATH" ]; then
    echo "Error: Proto directory not found in the repository"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# No need to include health.proto.
rm $TEMP_DIR/$PROTO_PATH/health.proto

echo "Found proto files in $TEMP_DIR/$PROTO_PATH:"
find "$TEMP_DIR/$PROTO_PATH" -name "*.proto" | xargs -n1 basename

# Generate Go code from proto files
echo "Generating Go code..."

# Get a list of all proto files
PROTO_FILES=$(find "$TEMP_DIR/$PROTO_PATH" -name "*.proto")

# Build the M parameters for each proto file
M_PARAMS=""
for proto_file in $PROTO_FILES; do
    filename=$(basename "$proto_file")
    M_PARAMS="$M_PARAMS --go_opt=M$filename=${GO_PACKAGE_PREFIX} --go-grpc_opt=M$filename=${GO_PACKAGE_PREFIX}"
done

echo "Using import mappings: $M_PARAMS"

# Since all proto files are in the same directory, we can process them all at once
# with a single protoc command, which simplifies dependency resolution
protoc \
    -I="$TEMP_DIR/$PROTO_PATH" \
    --go_out="$TARGET_DIR" \
    --go_opt=paths=source_relative \
    --go-grpc_out="$TARGET_DIR" \
    --go-grpc_opt=paths=source_relative \
    $M_PARAMS \
    "$TEMP_DIR/$PROTO_PATH"/*.proto

if [ $? -ne 0 ]; then
    echo "Error generating code from proto files"
    exit 1
else
    echo "Successfully generated Go code from proto files"
fi

# Clean up
echo "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

echo "Go code generation complete. Generated files are in $TARGET_DIR"