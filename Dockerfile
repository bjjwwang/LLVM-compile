# 使用 Ubuntu 24.04 作为基础镜像
FROM ubuntu:24.04

# 设置 LLVM 版本
ENV MajorLLVMVer=16
ENV LLVMVer=${MajorLLVMVer}.0.4
ENV LLVMHome=/llvm-${MajorLLVMVer}.0.0.obj
ENV SourceLLVM=https://github.com/llvm/llvm-project/archive/refs/tags/llvmorg-${LLVMVer}.zip

# 安装依赖
RUN apt update && apt install -y \
    build-essential \
    libncurses6 libncurses-dev \
    cmake zlib1g-dev \
    ninja-build unzip curl wget python3 git \
    && apt clean

# 处理 ARM 交叉编译
ARG TARGETARCH
RUN if [ "$TARGETARCH" = "arm64" ]; then \
      apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu; \
    fi

# 设置工作目录
WORKDIR /build

# 下载 LLVM 源码
RUN curl -L "$SourceLLVM" -o llvm.zip && \
    unzip -q llvm.zip && \
    mv llvm-project-* llvm-source

# 编译 LLVM
RUN mkdir llvm-build && cd llvm-build && \
    cmake -G Ninja -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_INSTALL_PREFIX="$LLVMHome" \
          -DLLVM_ENABLE_PROJECTS="clang" \
          -DLLVM_ENABLE_RTTI=ON \
          -DBUILD_SHARED_LIBS=ON \
          /build/llvm-source/llvm && \
    cmake --build . --parallel $(nproc) && \
    cmake --install .

# 将编译结果复制到 /output
RUN mkdir -p /output && cp -r $LLVMHome /output/

# 设置默认启动命令
CMD ["/bin/bash"]
