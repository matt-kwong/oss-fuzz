#!/bin/bash -eu
# Copyright 2016 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################################

FUZZER_TARGETS="\
test/core/json:json_fuzzer \
test/core/client_channel:uri_fuzzer_test \
test/core/http:request_fuzzer \
test/core/http:response_fuzzer \
test/core/nanopb:fuzzer_response \
test/core/nanopb:fuzzer_serverlist \
test/core/slice:percent_decode_fuzzer \
test/core/slice:percent_encode_fuzzer \
test/core/transport/chttp2:hpack_parser_fuzzer \
test/core/end2end/fuzzers:api_fuzzer \
test/core/end2end/fuzzers:client_fuzzer \
test/core/end2end/fuzzers:server_fuzzer \
test/core/security:ssl_server_fuzzer \
"

FUZZER_DICTIONARIES="\
test/core/end2end/fuzzers/api_fuzzer.dictionary \
test/core/end2end/fuzzers/hpack.dictionary \
"

# build grpc
# Temporary hack, see https://github.com/google/oss-fuzz/issues/383
NO_VPTR="--copt=-fno-sanitize=vptr --linkopt=-fno-sanitize=vptr"
EXTERA_BAZEL_FLAGS="--strip=never  $(for f in $CXXFLAGS; do if [ $f != "-stdlib=libc++" ] ; then echo --copt=$f --linkopt=$f; fi; done)"
bazel build --dynamic_mode=off --spawn_strategy=standalone --genrule_strategy=standalone \
  $EXTERA_BAZEL_FLAGS $NO_VPTR --linkopt="-lFuzzingEngine" \
  $FUZZER_TARGETS

for target in $FUZZER_TARGETS; do
  TARGET_PATH="${target/:/\/}"
  TARGET_BASE="${target##*:}"
  cp bazel-bin/"${TARGET_PATH}" "${OUT}"/"${TARGET_BASE}"
done

# Copy dictionaries and options files to $OUT/
for dict in $FUZZER_DICTIONARIES; do
  cp $dict $OUT/
done

cp $SRC/grpc/tools/fuzzer/options/*.options $OUT/

# We don't have a consistent naming convention between fuzzer files and corpus
# directories so we resort to hard coding zipping corpuses
zip $OUT/fuzzer_seed_corpus.zip test/core/json/corpus/*
zip $OUT/uri_fuzzer_test_seed_corpus.zip test/core/client_channel/uri_corpus/*
zip $OUT/request_fuzzer_seed_corpus.zip test/core/http/request_corpus/*
zip $OUT/response_fuzzer_seed_corpus.zip test/core/http/response_corpus/*
zip $OUT/fuzzer_response_seed_corpus.zip test/core/nanopb/corpus_response/*
zip $OUT/fuzzer_serverlist_seed_corpus.zip test/core/nanopb/corpus_serverlist/*
zip $OUT/percent_decode_fuzzer_seed_corpus.zip test/core/slice/percent_decode_corpus/*
zip $OUT/percent_encode_fuzzer_seed_corpus.zip test/core/slice/percent_encode_corpus/*
zip $OUT/hpack_parser_fuzzer_test_seed_corpus.zip test/core/transport/chttp2/hpack_parser_corpus/*
zip $OUT/api_fuzzer_seed_corpus.zip test/core/end2end/fuzzers/api_fuzzer_corpus/*
zip $OUT/client_fuzzer_seed_corpus.zip test/core/end2end/fuzzers/client_fuzzer_corpus/*
zip $OUT/server_fuzzer_seed_corpus.zip test/core/end2end/fuzzers/server_fuzzer_corpus/*
zip $OUT/ssl_server_fuzzer_seed_corpus.zip test/core/security/corpus/ssl_server_corpus/*
