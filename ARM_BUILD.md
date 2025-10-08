Building for ARM64

This project targets AARCH64 (ARM64) and builds box86/box64 by default. To build the image for ARM64 from an x86 host, use Docker Buildx (emulated build):

- Example (build locally and load image):

  docker buildx build --platform linux/arm64 --load --build-arg BUILD_BOX86=true --build-arg BUILD_BOX64=true -t valheim_box64:local .

- If you're building on a native ARM64 host, you can simply run:

  docker build --build-arg BUILD_BOX86=true --build-arg BUILD_BOX64=true -t valheim_box64:local .

If you want to skip building the emulators (fast builds), set the build args to false.
