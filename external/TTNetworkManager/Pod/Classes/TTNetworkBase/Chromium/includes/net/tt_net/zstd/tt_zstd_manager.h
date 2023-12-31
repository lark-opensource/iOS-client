// Copyright (c) 2022 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_ZSTD_TT_ZSTD_MANAGER_H
#define NET_TT_NET_ZSTD_TT_ZSTD_MANAGER_H

#include "base/files/file_path.h"
#include "base/memory/singleton.h"
#include "net/tt_net/route_selection/tt_server_config.h"
#include "net/url_request/url_fetcher_delegate.h"

namespace net {

struct HttpRequestInfo;
class IOBufferWithSize;
class FilePath;
class URLFetcher;

class TTZstdManager : public URLFetcherDelegate, TTServerConfigObserver {
 public:
  static const char kZstdHeaderKey[];
  static const char kTtzipHeaderValue[];

  typedef void* (*ZSTDCreateDCtx)();

  typedef size_t (*ZSTDDecompressStream)(void* zds, void* output, void* input);

  typedef size_t (*ZSTDFreeDCtx)(void* dctx);

  typedef unsigned int (*ZSTDIsError)(size_t code);

  typedef void* (*ZSTDCreateDDict)(void* dictBuffer, size_t dictSize);

  typedef size_t (*ZSTDDCtxRefDDict)(void* dctx, void* ddict);

  typedef size_t (*ZSTDFreeDDict)(void* ddict);

  typedef size_t (*ZSTDDCtxReset)(void* dctx, void* reset);

  static TTZstdManager* GetInstance();

  // Outer Func
  void Init(const std::string& root_dir_path,
            scoped_refptr<base::SingleThreadTaskRunner> file_task_runner);

  bool HandleRequestHeader(HttpRequestInfo& request_info);

  void OnRequestJobFinished(bool is_zstd_encode_job);

  void* ObtainZstdDctx(const std::string& version,
                       int& error_code,
                       int& zstd_error_code);

  void IncrementZstdErrorCount();

  int GetCurrentJobCount() const;

  void RecycleZstdDctx(void* dctx);

  // Zstd Func
  void SetZstdFunc(ZSTDCreateDCtx create_dctx_func,
                   ZSTDDecompressStream decompress_stream_func,
                   ZSTDFreeDCtx free_dctx_func,
                   ZSTDIsError zstd_is_error_func,
                   ZSTDCreateDDict zstd_create_ddict_func,
                   ZSTDDCtxRefDDict zstd_dctx_ref_ddict_func,
                   ZSTDFreeDDict zstd_free_ddict_func,
                   ZSTDDCtxReset zstd_dctx_reset_func);

  size_t ZstdDecompressStream(void* zds, void* output, void* input);

  unsigned int ZstdIsError(size_t code);

 private:
  friend struct base::DefaultSingletonTraits<TTZstdManager>;

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  friend class TTZstdManagerTest;
  friend class TTZstdSourceStreamTest;

  FRIEND_TEST_ALL_PREFIXES(TTZstdManagerTest, Init);
  FRIEND_TEST_ALL_PREFIXES(TTZstdManagerTest, InitDictOnFileThread);
  FRIEND_TEST_ALL_PREFIXES(TTZstdManagerTest, LoadDictMemoryOnFileThread);
  FRIEND_TEST_ALL_PREFIXES(TTZstdManagerTest, StartDownloadDict);
  FRIEND_TEST_ALL_PREFIXES(TTZstdManagerTest, MonitorDictResult);
  FRIEND_TEST_ALL_PREFIXES(TTZstdManagerTest, OnServerConfigChanged);
  FRIEND_TEST_ALL_PREFIXES(TTZstdManagerTest, HandleRequestHeader);
  FRIEND_TEST_ALL_PREFIXES(TTZstdManagerTest, VerifyDictMd5);
  FRIEND_TEST_ALL_PREFIXES(TTZstdManagerTest, ZstdFunc);

  FRIEND_TEST_ALL_PREFIXES(TTZstdSourceStreamTest, SetUp);
  FRIEND_TEST_ALL_PREFIXES(TTZstdSourceStreamTest, Init);
  FRIEND_TEST_ALL_PREFIXES(TTZstdSourceStreamTest, FilterData);

  bool IsinitializedForTesting() const;

  void SetErrorRequestLogListForTesting(
      const std::vector<std::string>& error_request_log_list);

  void Set64BitLibraryForTesting(bool is64BitLibrary);
#endif

  TTZstdManager();
  ~TTZstdManager() override;

  struct ZstdConfig {
    struct DictConfig {
      DictConfig();
      DictConfig(const DictConfig& other);
      ~DictConfig();

      std::string version;
      std::string url;
      std::string md5;
    };

    ZstdConfig();
    ZstdConfig(const ZstdConfig& other);
    ~ZstdConfig();

    bool enable;
    bool enable_32_bit_library;
    std::map<std::string, DictConfig> path_dict_map;
    std::map<std::string, DictConfig> path_pattern_dict_map;
    int max_failover_error_count;
    int max_concurrent_job_count;
    int download_dict_delay_interval_s;
    int expire_dict_memory_check_interval_s;
    int memory_ttl_s;
    int64_t dict_size_limit;
    int max_dctx_cache_count;
  };

  enum LoadState {
    NONE,
    LOADING,
    SUCCESS,
    FAIL,
  };

  struct DictMemoryData {
    DictMemoryData();
    DictMemoryData(const DictMemoryData& other);
    ~DictMemoryData();

    LoadState state{NONE};
    scoped_refptr<net::IOBufferWithSize> data{nullptr};
    int dict_load_time{0};

    void* ddict{nullptr};  // ZSTD_DDict
  };

  // Network Thread Func
  void InitImpl();

  void LoadDictMemory(const std::string& version);

  void OnDictMemoryUpdate(
      const std::map<std::string, DictMemoryData>& update_dict_memory_map);

  void StartDownloadDict(
      const std::vector<ZstdConfig::DictConfig>& download_dict_config_list);

  void DownloadNextDict();

  void CheckExpiredDictMemory();

  bool IsSetZstdFunc() const;

  void ReportErrorStats(const std::vector<std::string>& error_msg_list);

  void MonitorDictStart();

  void MonitorDictResult(bool success);

  void FreeDDictMemory(void *ddict);

  // TTServerConfigObserver implementation
  void OnServerConfigChanged(
      UpdateSource source,
      const base::Optional<base::Value>& tnc_config_value) override;

  // net::URLFetcherDelegate implementation
  void OnURLResponseStarted(const net::URLFetcher* source) override;

  void OnURLFetchComplete(const net::URLFetcher* source) override;

  void OnURLFetchDownloadProgress(const net::URLFetcher* source,
                                  int64_t current,
                                  int64_t total,
                                  int64_t current_network_bytes) override;

  void OnURLFetchUploadProgress(const net::URLFetcher* source,
                                int64_t current,
                                int64_t total) override;

  // File Thread Func
  void InitDictOnFileThread(const std::string& root_dir_path,
                            const ZstdConfig& zstd_config);

  void LoadDictMemoryOnFileThread(const std::vector<std::string>& version_list);

  bool VerifyDictMd5(const base::FilePath& zip_file, const std::string& md5);

  // Network Thread Var
  bool is_initialized_{false};

  ZstdConfig zstd_config_;
  std::string zstd_dir_path_;

  base::RepeatingTimer expire_dict_check_timer_;

  int current_download_dict_index_{0};
  std::vector<ZstdConfig::DictConfig> download_dict_config_list_;

  // Dict memory data
  std::map<std::string, DictMemoryData> dict_memory_map_;
  std::list<void*> dctx_cache_list_;

  int current_zstd_error_count_{0};
  int current_job_count_{0};
#ifdef __LP64__
  bool is_64_bit_library_{true};
#else
  bool is_64_bit_library_{false};
#endif

  std::unique_ptr<URLFetcher> fetcher_;

  scoped_refptr<base::SingleThreadTaskRunner> file_task_runner_;
  scoped_refptr<base::SingleThreadTaskRunner> network_runner_;

  // Statistics
  bool is_reported_{false};
  std::vector<std::string> error_request_log_list_;
  std::string uuid_;
  int64_t start_time_{0};

  // Zstd Func Var
  ZSTDCreateDCtx zstd_create_dctx_func_{nullptr};
  ZSTDDecompressStream zstd_decompress_stream_func_{nullptr};
  ZSTDFreeDCtx zstd_free_dctx_func_{nullptr};
  ZSTDIsError zstd_is_error_func_{nullptr};
  ZSTDCreateDDict zstd_create_ddict_func_{nullptr};
  ZSTDDCtxRefDDict zstd_dctx_ref_ddict_func_{nullptr};
  ZSTDFreeDDict zstd_free_ddict_func_{nullptr};
  ZSTDDCtxReset zstd_dctx_reset_func_{nullptr};

  // File Thread Var
  base::FilePath dict_dir_path_;

  DISALLOW_COPY_AND_ASSIGN(TTZstdManager);
};

}  // namespace net

#endif  // NET_TT_NET_ZSTD_TT_ZSTD_MANAGER_H
