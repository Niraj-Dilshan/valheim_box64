### Multi-stage Dockerfile with optional emulator builds
# Builder stage: compile box86 / box64 and download steamcmd (ARM64-first)
# This Dockerfile assumes you're building for linux/arm64. Use docker buildx to build on other hosts.
# Example (on x86 host, using buildx emulation):
# docker buildx build --platform linux/arm64 --load --build-arg BUILD_BOX86=true --build-arg BUILD_BOX64=true -t valheim_box64:local .
FROM debian:12.4-slim AS builder

# Build-time flags: default to build box64 (x86_64 emulator). box86 (x86->arm32) is disabled by default
# because it often requires additional cross toolchains and causes dynarec-arm build issues on some ARM64 systems.
ARG BUILD_BOX86=false
ARG BUILD_BOX64=true
ARG DEBIAN_FRONTEND=noninteractive
WORKDIR /root

# Install build deps only in builder to keep runtime slim
RUN set -eux; \
	# enable armhf multiarch - required if we need to cross-build or provide armhf libs
	dpkg --add-architecture armhf || true; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		build-essential cmake git curl ca-certificates python3 pkg-config wget \
		gcc g++ libglib2.0-dev libffi-dev libssl-dev; \
	# install crossbuild essentials for armhf so box86's dynarec (ARM32) can be built if requested
	apt-get install -y --no-install-recommends crossbuild-essential-armhf gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf libc6:armhf libc6-dev:armhf || true; \
	rm -rf /var/lib/apt/lists/*;

# Build box86 (32-bit x86 emulator) - optional
RUN set -eux; \
		if [ "${BUILD_BOX86}" = "true" ]; then \
			git clone --depth 1 https://github.com/ptitSeb/box86.git /root/box86; \
			mkdir -p /root/box86/build; cd /root/box86/build; \
			cmake .. -DARM64=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo; \
			make -j"$(nproc)"; make install; \
			rm -rf /root/box86; \
		else \
			echo "Skipping box86 build (BUILD_BOX86=${BUILD_BOX86}). Set --build-arg BUILD_BOX86=true on ARM hosts to enable."; \
		fi

# Download steamcmd
RUN set -eux; \
		mkdir -p /root/steamcmd; cd /root/steamcmd; \
		curl -sSL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar -xz --strip-components=0 -C /root/steamcmd;

# Build box64 (x86_64 emulator) - optional
RUN set -eux; \
			if [ "${BUILD_BOX64}" = "true" ]; then \
				git clone --depth 1 https://github.com/ptitSeb/box64.git /root/box64; \
				mkdir -p /root/box64/build; cd /root/box64/build; \
				# Explicitly target ARMv8 to ensure assembler understands system register instructions
				export CFLAGS="-march=armv8-a -mcpu=native"; \
				export CXXFLAGS="-march=armv8-a -mcpu=native"; \
				cmake .. -DARM_DYNAREC=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_C_FLAGS="$CFLAGS" -DCMAKE_CXX_FLAGS="$CXXFLAGS"; \
				make -j"$(nproc)"; make install; \
				rm -rf /root/box64; \
			else \
			echo "Skipping box64 build (BUILD_BOX64=${BUILD_BOX64}). Set --build-arg BUILD_BOX64=true on ARM hosts to enable."; \
		fi


### Runtime stage: copy only runtime artifacts
FROM debian:12.4-slim

ARG DEBIAN_FRONTEND=noninteractive
WORKDIR /root

# Minimal runtime deps
RUN set -eux; \
		apt-get update; \
		apt-get install -y --no-install-recommends ca-certificates libstdc++6 libgcc-s1 wget curl; \
		rm -rf /var/lib/apt/lists/*;

# Copy box86/box64 and steamcmd from builder (if built)
COPY --from=builder /usr/local /usr/local
COPY --from=builder /root/steamcmd /root/steamcmd

# Add scripts
COPY scripts /root/scripts
RUN set -eux; \
		chmod +x /root/scripts/*.sh; \
		ln -s /root/scripts/run.sh /run.sh || true

EXPOSE 2456-2458/udp

WORKDIR /root

ENV PATH="/usr/local/bin:${PATH}"

CMD ["/bin/sh", "/run.sh"]
