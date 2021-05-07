#!/bin/bash

set -e

if [ -n "$server_branch" ] ; then

  ###################################################################################################################
  # run server test suite
  ###################################################################################################################
  echo "run server test suite"
  git clone -b ${server_branch} https://github.com/mariadb/server ../workdir-server
  cd ../workdir-server
  # don't pull in submodules. We want the latest C/C as libmariadb
  # build latest server with latest C/C as libmariadb
  # skip to build some storage engines to speed up the build
  cmake . -DPLUGIN_MROONGA=NO -DPLUGIN_ROCKSDB=NO -DPLUGIN_SPIDER=NO -DPLUGIN_TOKUDB=NO
  cd libmariadb
  ls -lrt
  echo ${TRAVIS_COMMIT}
  git checkout ${TRAVIS_COMMIT}
  ls -lrt
  cd ..
  git add libmariadb
  make -j9
  cd mysql-test/
  ./mysql-test-run.pl --suite=main ${TEST_OPTION} --parallel=1 --skip-test=session_tracker_last_gtid

else

  ###################################################################################################################
  # run connector test suite
  ###################################################################################################################
  echo "run connector test suite"

  cmake . -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCERT_PATH=${SSLCERT}

  if [ "$TRAVIS_OS_NAME" = "windows" ] ; then
    echo "build from windows"
    set MYSQL_TEST_DB=testc
    set MYSQL_TEST_TLS=%TEST_REQUIRE_TLS%
    set MYSQL_TEST_USER=%TEST_DB_USER%
    set MYSQL_TEST_HOST=%TEST_DB_HOST%
    set MYSQL_TEST_PASSWD=%TEST_DB_PASSWORD%
    set MYSQL_TEST_PORT=%TEST_DB_PORT%
    set MYSQL_TEST_TLS=%TEST_REQUIRE_TLS%
    cmake --build . --config RelWithDebInfo
  else
    echo "build from linux"
    export TEST_DB_DATABASE=testc
    export MYSQL_TEST_USER=$TEST_DB_USER
    export MYSQL_TEST_HOST=$TEST_DB_HOST
    export MYSQL_TEST_PASSWD=$TEST_DB_PASSWORD
    export MYSQL_TEST_PORT=$TEST_DB_PORT
    export MYSQL_TEST_DB=testc
    export MYSQL_TEST_TLS=$TEST_REQUIRE_TLS
    export SSLCERT=$TEST_DB_SERVER_CERT
    export MARIADB_PLUGIN_DIR=$PWD

    echo "MYSQL_TEST_PLUGINDIR=$MYSQL_TEST_PLUGINDIR"
    if [ -n "$MYSQL_TEST_SSL_PORT" ] ; then
      export MYSQL_TEST_SSL_PORT=$MYSQL_TEST_SSL_PORT
    fi
    export MYSQL_TEST_TLS=$TEST_REQUIRE_TLS
    export SSLCERT=$TEST_DB_SERVER_CERT
    if [ -n "$MYSQL_TEST_SSL_PORT" ] ; then
      export MYSQL_TEST_SSL_PORT=$MYSQL_TEST_SSL_PORT
    fi
    make
  fi

  ls -lrt

  openssl ciphers -v
  cd unittest/libmariadb
  ctest -V
fi
