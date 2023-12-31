// Copyright (c) 2022 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_ZSTD_TT_ZSTD_SOURCE_STREAM_H
#define NET_TT_NET_ZSTD_TT_ZSTD_SOURCE_STREAM_H

#include <string>

#include "net/filter/filter_source_stream.h"
#include "net/tt_net/zstd/tt_zstd_errors.h"

namespace net {

struct LoadTimingInfo;
class HttpRequestHeaders;
class HttpResponseHeaders;

class TTZstdSourceStream : public FilterSourceStream {
 public:
  ~TTZstdSourceStream() override;

  static std::unique_ptr<TTZstdSourceStream> Create(
      std::unique_ptr<SourceStream> previous,
      const std::string& path,
      const HttpRequestHeaders& request_headers,
      const HttpResponseHeaders& response_headers);

 private:
  TTZstdSourceStream(std::unique_ptr<SourceStream> upstream,
                     const std::string& path,
                     const std::string& request_ttzip_version,
                     const std::string& response_ttzip_version);

  enum State { PROCESSING, SUCCESS, ERROR };

  struct ZSTDInBuffer {
    const void* src;
    size_t size;
    size_t pos;
  };

  struct ZSTDOutBuffer {
    void* dst;
    size_t size;
    size_t pos;
  };

  // SourceStream implementation
  std::string GetTypeAsString() const override;

  int FilterData(IOBuffer* output_buffer,
                 int output_buffer_size,
                 IOBuffer* input_buffer,
                 int input_buffer_size,
                 int* consumed_bytes,
                 bool upstream_end_reached) override;

  void TryFillSourceStreamInfo(LoadTimingInfo* load_timing_info) const override;

  void Init();

  // Inner Var
  State state_{PROCESSING};
  void* zstd_dctx_{nullptr};

  // Statistics
  int error_code_{ERR_ZSTD_OK};
  std::string error_msg_;
  std::string path_;
  std::string request_ttzip_version_;
  std::string response_ttzip_version_;
  size_t consumed_bytes_{0};
  size_t produced_bytes_{0};
  int64_t duration_{0};
  int concurrent_job_count_{0};

  DISALLOW_COPY_AND_ASSIGN(TTZstdSourceStream);
};

}  // namespace net

#endif  // NET_TT_NET_ZSTD_TT_ZSTD_SOURCE_STREAM_H
