// Copyright (c) 2022 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_COMPRESS_TT_COMPRESS_NATIVE_H
#define NET_TT_NET_COMPRESS_TT_COMPRESS_NATIVE_H

#include <memory>
#include <regex>
#include <string>
#include "base/memory/singleton.h"
#include "net/base/load_timing_info.h"
#include "net/tt_net/route_selection/tt_server_config.h"
#include "net/url_request/url_request.h"
#include "url/gurl.h"

/** Default value for ::BROTLI_PARAM_QUALITY parameter. */
#define TT_BROTLI_DEFAULT_QUALITY 4
typedef struct z_stream_s z_stream;

namespace net {

class IOBuffer;
class URLRequest;

enum CompressType {
  COMPRESS_NONE,

  COMPRESS_ZLIB,

  COMPRESS_BROTLI,

  COMPRESS_ZSTD
};

class CompressDataStream {
 public:
  CompressDataStream() {}
  virtual ~CompressDataStream() = default;

  virtual int CompressImplement(IOBuffer* input_buffer,
                                int input_buffer_size,
                                bool final_chunk,
                                LoadTimingInfo::CompressInfo& compress_info);

  virtual int InitCompressStream();

  DISALLOW_COPY_AND_ASSIGN(CompressDataStream);
};

class TTNET_IMPLEMENT_EXPORT CompressNativeWrapper : public TTServerConfigObserver {
 public:
  CompressNativeWrapper();

  ~CompressNativeWrapper() override;

  struct CompressConfig {
    CompressConfig();
    CompressConfig(const CompressConfig& other);
    ~CompressConfig();
    bool enabled;
    size_t max_body_size;
    size_t min_body_size;
    int type;
    int br_level;
    int fail_cnt_limit;
    std::set<std::string> equal_path;
    std::vector<std::string> prefix_path;
    std::set<std::string> block_path_equal_list;
    std::vector<std::string> host_group;
    std::vector<std::regex> block_path_regex_list;
  };

  std::unique_ptr<CompressDataStream> CreateCompressDataStream(
      size_t body_size);

  bool IsRequestBodyNeedCompress(const GURL& url) const;

  /**
  compress std::string using Brotli
  @param input input a std::string
  @param output reference to a output std::string
  @return status code
  */
  int CompressUsingBrotli(const std::string& input, std::string& output);

  /**
  Decompress std::string using Brotli
  @param input input a std::string
  @param output reference to a output std::string
  @return status code
  */
  int DecompressUsingBrotli(const std::string& input, std::string& output);

  // TTServerConfigObserver implementation
  void OnServerConfigChanged(
      UpdateSource source,
      const base::Optional<base::Value>& tnc_config_value) override;

  CompressConfig GetCompressConfig() const { return compress_config_; }

  bool IsUrlMatchedConfig(const std::string& request_host,
                          const std::string& request_path) const;

  void HandleRequestResult(const net::URLRequest* url_request, int net_error);

  bool IsBodySizeMatch(size_t body_size) const;

 private:
  CompressConfig compress_config_;

  int fail_count_;

  bool has_global_forbiden_;

  DISALLOW_COPY_AND_ASSIGN(CompressNativeWrapper);
};

}  // namespace net

#endif  // NET_TT_NET_COMPRESS_TT_COMPRESS_NATIVE_H