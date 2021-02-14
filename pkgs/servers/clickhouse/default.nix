{ lib
, overrideCC
, boost17x
, capnproto
, cctz
, cmake
, cyrus_sasl
, double-conversion
, fetchFromGitHub
, grpc
, gsasl
, icu
, libkrb5
, libmysqlclient
, libxml2
, llvmPackages_10
, llvmPackages_11
, lz4
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
, zlib
, zstd
}:

let
  buildStdenv = overrideCC stdenv llvmPackages_11.lldClangNoLibcxx;
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
    boost17x
    capnproto
    cctz
    cyrus_sasl
    double-conversion
    grpc
    gsasl
    icu
    libkrb5
    libmysqlclient
    libxml2
    llvmPackages_10.llvm
    lz4
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
      substituteInPlace "$script"  --replace '$(git rev-parse --show-toplevel)' '${src}'
    done
  '';

  cmakeFlags = [
    "-DUNBUNDLED=ON"
    "-DUSE_INTERNAL_FARMHASH_LIBRARY=ON"
    "-DUSE_INTERNAL_HYPERSCAN_LIBRARY=ON"
    "-DENABLE_PARQUET=OFF"
    "-DENABLE_AVRO=OFF"
    "-DENABLE_TESTS=OFF"
    "-DWERROR=OFF"
  ];

  postInstall = ''
    rm -rf $out/share/clickhouse-test

    sed -i -e '\!<log>/var/log/clickhouse-server/clickhouse-server\.log</log>!d' \
      $out/etc/clickhouse-server/config.xml
    substituteInPlace $out/etc/clickhouse-server/config.xml \
      --replace "<errorlog>/var/log/clickhouse-server/clickhouse-server.err.log</errorlog>" "<console>1</console>"
  '';

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
