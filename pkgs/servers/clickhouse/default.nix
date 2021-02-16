{ lib
, overrideCC
, arrow-cpp
, boost17x
, brotli
, bzip2
, capnproto
, cctz
, cmake
, cyrus_sasl
, double-conversion
, fetchFromGitHub
, grpc
, gsasl
, hyperscan
, icu
, libmysqlclient
, libxml2
, llvmPackages_11
, lzma
, msgpack
, ncurses
, ninja
, openldap
, openssl
, perl
, pkg-config
, protobuf
, python3
, rapidjson
, rdkafka
, re2
, snappy
, stdenv
, thrift
, unixODBC
, utf8proc
, zlib
, zstd
}:

let
  buildStdenv = llvmPackages_11.stdenv;
  # buildStdenv = stdenv;
in
buildStdenv.mkDerivation rec {
  pname = "clickhouse";
  version = "21.2.2.8";

  src = fetchFromGitHub {
    owner = "ClickHouse";
    repo = "ClickHouse";
    rev = "v${version}-stable";
    fetchSubmodules = true;
    sha256 = "0c87k0xqwj9sc3xy2f3ngfszgjiz4rzd787bdg6fxp94w1adjhny";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    ninja
    python3
    perl
  ];
  buildInputs = [
    (llvmPackages_11.llvm.override { enableSharedLibraries = true; })
    arrow-cpp
    boost17x
    brotli
    bzip2
    capnproto
    cctz
    cyrus_sasl
    double-conversion
    grpc
    gsasl
    hyperscan
    icu
    libmysqlclient
    libxml2
    lzma
    msgpack
    ncurses
    openldap
    openssl
    protobuf
    rapidjson
    rdkafka
    re2
    snappy
    thrift
    unixODBC
    utf8proc
    zlib
    zstd
  ];

  postPatch = ''
    patchShebangs src/ utils/ programs/

    substituteInPlace contrib/openssl-cmake/CMakeLists.txt \
      --replace '/usr/bin/env perl' ${perl}

    for script in  \
      src/Storages/System/StorageSystemLicenses.sh \
      utils/check-style/check-duplicate-includes.sh \
      utils/check-style/check-style \
      utils/check-style/check-typos \
      utils/check-style/check-ungrouped-includes.sh \
      utils/generate-ya-make/generate-ya-make.sh \
      utils/list-licenses/list-licenses.sh
    do
      substituteInPlace "$script"  --replace '$(git rev-parse --show-toplevel)' "$NIX_BUILD_TOP/$sourceRoot"
    done

    substituteInPlace cmake/find/llvm.cmake --replace 'llvm_v 10 9 8' 'llvm_v 11'
    echo 'set (REQUIRED_LLVM_LIBRARIES "LLVM-''${LLVM_VERSION_MAJOR}")' >>cmake/find/llvm.cmake

    echo 'dbms_target_link_libraries(PRIVATE ''${ARROW_LIBRARY})' >> src/CMakeLists.txt
  '';

  # ClickHouse includes compiler and linker paths into the generated file, this
  # makes the package unnecessarily depend on clang.
  postConfigure = ''
    sed -ie 's|/nix/store/[^/]*/bin/||' src/Storages/System/StorageSystemBuildOptions.generated.cpp
  '';

  cmakeFlags = [
    # Use system libraries instead of the bundled ones.
    "-DUNBUNDLED=ON"

    # ClickHouse is having troubles finding hs.h ni the hs/ subdirectory.
    "-DCMAKE_INCLUDE_PATH=${hyperscan.dev}/include/hs"

    # For some reason, using external lz4 disables implies USE_XXHASH=OFF.
    "-DUSE_INTERNAL_LZ4_LIBRARY=ON"

    # Not in nixpkgs yet.
    "-DUSE_INTERNAL_FARMHASH_LIBRARY=ON"

    # Use shared system libraries.
    "-DUSE_STATIC_LIBRARIES=OFF"

    # Link internal ClickHouse libraries statically. Dynamic linking seems
    # untested and broken.
    "-DMAKE_STATIC_LIBRARIES=ON"

    # Bundled Avro fails to compile:
    # error: unknown type name 'size_t'; did you mean 'std::size_t'?
    # Using external Avro is not supported yet.
    "-DENABLE_AVRO=OFF"

    "-DENABLE_TESTS=OFF"
  ];

  preBuild = ''
    export TERM=dumb
  '';
  postInstall = ''
    rm -rf $out/share/clickhouse-test

    sed -i -e '\!<log>/var/log/clickhouse-server/clickhouse-server\.log</log>!d' \
      $out/etc/clickhouse-server/config.xml
    substituteInPlace $out/etc/clickhouse-server/config.xml \
      --replace "<errorlog>/var/log/clickhouse-server/clickhouse-server.err.log</errorlog>" "<console>1</console>"
  '';

  disallowedReferences = [ buildStdenv.cc ];

  hardeningDisable = [ "format" ];

  requiredSystemFeatures = [ "big-parallel" ];

  meta = with lib; {
    homepage = "https://clickhouse.tech/";
    description = "Column-oriented database management system";
    license = licenses.asl20;
    maintainers = with maintainers; [ orivej ];
    platforms = platforms.linux;
  };
}
