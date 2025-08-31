#!/usr/bin/env bash
set -e

# SONiC Lab Preparation Script
# This script processes SONiC images and pushes them to Quay registry
# Note: You must manually download docker-sonic-vs.gz from Azure and place it in the assets directory

echo ">> Preparing SONiC Lab Environment..."
echo "   Branch: ${SONIC_BRANCH:-202505}"
echo "   Registry: ${SONIC_REGISTRY:-quay.io/bjozsa-redhat}"
echo "   Image: ${SONIC_IMAGE_NAME:-docker-sonic-vs}:${SONIC_IMAGE_TAG:-202505}"
echo "   Container Engine: ${SONIC_CONTAINER_ENGINE:-podman}"

# Source variables from parent Makefile if not set
if [ -z "$SONIC_BRANCH" ]; then
    SONIC_BRANCH="202505"
fi
if [ -z "$SONIC_REGISTRY" ]; then
    SONIC_REGISTRY="quay.io/bjozsa-redhat"
fi
if [ -z "$SONIC_IMAGE_NAME" ]; then
    SONIC_IMAGE_NAME="docker-sonic-vs"
fi
if [ -z "$SONIC_IMAGE_TAG" ]; then
    SONIC_IMAGE_TAG="$SONIC_BRANCH"
fi
if [ -z "$SONIC_CONTAINER_ENGINE" ]; then
    SONIC_CONTAINER_ENGINE="podman"
fi
if [ -z "$SONIC_ASSETS_DIR" ]; then
    SONIC_ASSETS_DIR="assets"
fi

# Create assets directory if it doesn't exist
mkdir -p "$SONIC_ASSETS_DIR"

# Define file paths
SONIC_IMAGE_FILE="$SONIC_ASSETS_DIR/docker-sonic-vs.gz"
SONIC_IMAGE_TAR="$SONIC_ASSETS_DIR/docker-sonic-vs.tar"
FINAL_IMAGE="$SONIC_REGISTRY/$SONIC_IMAGE_NAME:$SONIC_IMAGE_TAG"

echo ">> Checking if image already exists in registry..."
if $SONIC_CONTAINER_ENGINE manifest inspect "$FINAL_IMAGE" >/dev/null 2>&1; then
    echo "   ✅ Image $FINAL_IMAGE already exists in registry"
    echo "   Skipping processing and upload..."
    exit 0
fi

echo ">> Checking for SONiC image file..."
# Check for either .gz or .tar file
if [ -f "$SONIC_IMAGE_FILE" ]; then
    echo "   ✅ Found SONiC gzipped image file: $SONIC_IMAGE_FILE"
    NEED_CONVERSION=true
elif [ -f "$SONIC_IMAGE_TAR" ]; then
    echo "   ✅ Found SONiC tar image file: $SONIC_IMAGE_TAR"
    NEED_CONVERSION=false
else
    echo "   ❌ SONiC image file not found"
    echo ""
    echo "   Please manually download the SONiC image:"
    echo "   1. Visit: https://sonic.software/"
    echo "   2. Navigate to Branch: $SONIC_BRANCH"
    echo "   3. Download: docker-sonic-vs.gz or docker-sonic-vs.tar"
    echo "   4. Place it in: $SONIC_ASSETS_DIR/"
    echo ""
    echo "   Then run this script again."
    exit 1
fi

# If we have a .gz file, verify it's valid
if [ "$NEED_CONVERSION" = true ]; then
    if ! file "$SONIC_IMAGE_FILE" | grep -q "gzip"; then
        echo "   ❌ File is not a valid gzip archive"
        echo "   Please ensure you downloaded the correct file from Azure"
        exit 1
    fi
fi

# Convert gzipped image to tar format if needed
if [ "$NEED_CONVERSION" = true ]; then
    echo ">> Converting gzipped image to tar format..."
    if gunzip -c "$SONIC_IMAGE_FILE" > "$SONIC_IMAGE_TAR"; then
        echo "   ✅ Conversion completed"
        # Remove the gzipped file to save space
        rm "$SONIC_IMAGE_FILE"
    else
        echo "   ❌ Conversion failed"
        exit 1
    fi
else
    echo ">> Using existing tar file: $SONIC_IMAGE_TAR"
fi

echo ">> Loading image into local container engine..."
if $SONIC_CONTAINER_ENGINE load -i "$SONIC_IMAGE_TAR"; then
    echo "   ✅ Image loaded successfully"
else
    echo "   ❌ Failed to load image"
    exit 1
fi

echo ">> Tagging image for registry..."
if $SONIC_CONTAINER_ENGINE tag "docker-sonic-vs:latest" "$FINAL_IMAGE"; then
    echo "   ✅ Image tagged as $FINAL_IMAGE"
else
    echo "   ❌ Failed to tag image"
    exit 1
fi

echo ">> Converting image to amd64 platform..."
# Create a new image with amd64 platform
if $SONIC_CONTAINER_ENGINE buildx create --use --name sonic-amd64-builder >/dev/null 2>&1 || true; then
    if $SONIC_CONTAINER_ENGINE buildx build --platform linux/amd64 --tag "$FINAL_IMAGE" --load .; then
        echo "   ✅ Image converted to amd64 platform"
    else
        echo "   ⚠️  Platform conversion failed, using original image"
        echo "   Note: This may cause issues on non-ARM architectures"
    fi
else
    echo "   ⚠️  Buildx not available, using original image"
fi

echo ">> Pushing image to registry..."
if $SONIC_CONTAINER_ENGINE push "$FINAL_IMAGE"; then
    echo "   ✅ Image pushed successfully to $FINAL_IMAGE"
else
    echo "   ❌ Failed to push image to registry"
    echo "   Please check your registry credentials and permissions"
    exit 1
fi

echo ">> Cleaning up temporary files..."
rm -f "$SONIC_IMAGE_TAR"

echo ">> SONiC Lab preparation completed successfully!"
echo "   Image: $FINAL_IMAGE"
echo "   Default login: admin / YourPaSsWoRd"
echo ""
echo "   Next steps:"
echo "   1. make deploy-lab LAB=demo-cl-sonic-01"
echo "   2. make configure-lab LAB=demo-cl-sonic-01"
echo "   3. make test-lab LAB=demo-cl-sonic-01"
