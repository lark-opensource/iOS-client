// Copyright (c) 2020 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TTNET_NETLOG_NET_LOG_MANAGER_H_
#define NET_TTNET_NETLOG_NET_LOG_MANAGER_H_

#include <set>
#include <string>
#include "base/files/file_path.h"
#include "base/memory/ref_counted.h"
#include "base/memory/singleton.h"
#include "base/timer/timer.h"
#include "net/tt_net/netlog/tt_encrypt_util.h"
#include "net/tt_net/netlog/tt_net_log_file_observer.h"
#include "net/tt_net/route_selection/tt_server_config.h"
#include "net/url_request/url_request_context_getter.h"
#include "url/gurl.h"

namespace base {
class ImportantFileWriter;
}

namespace net {

class URLRequest;
class MemLruNetLogObserver;
class URLRequestContext;

class NetLogManager : public TTServerConfigObserver {
 public:
  enum LogLevel { DEV = 0, COLOR = 1, USER = 2 };
  enum ConfigLevel { LOW = 0, MID = 1, HIGH = 2 };

  static NetLogManager* GetInstance();
  ~NetLogManager() override;

  void OnRequestCompleted(URLRequest* request, bool started, int net_error);

  bool Init(URLRequestContextGetter* context_getter,
            scoped_refptr<base::SingleThreadTaskRunner> file_task_runner_,
            const std::string& temp_log_path,
            const std::string& log_path,
            bool is_main_process);

  bool DevLevel() const;
  bool ColorLevel() const;
  bool UserLevel() const;
  std::string StripQueryIfNecessary(const GURL& url) const;

  void ParseUserJSONConfigInfo(const std::string& config);

 private:
  friend struct base::DefaultSingletonTraits<NetLogManager>;

  // CompressFileWriter always work on file thread.
  class CompressFileWriter : public TTNetlogFileObserver::FileCloseListener {
   public:
    CompressFileWriter();

    ~CompressFileWriter() override;

    void OnLogFileClosed(const std::string& file_name_str,
                         int64_t create_log_file_time) override;

    void CleanOldestLog();

    void CompressAndEntrypt(const std::string& json,
                            const std::string& file_name_str);

    void CompressAndEntryptFileLogs(const std::string& file_name,
                                    int64_t create_log_file_time);

    void CheckUncompressedFileLogs(int64_t now);

    void SetLogRootPath(const base::FilePath& temp_log_dir,
                        const base::FilePath& compress_log_dir) {
      temp_log_dir_ = temp_log_dir;
      compress_log_dir_ = compress_log_dir;
    }

    void set_is_main_process(bool val) { is_main_process_ = val; }

    void set_total_log_file_size_limit(int64_t val) {
      total_log_file_size_limit_ = val;
    }

    const base::FilePath& temp_log_dir() const { return temp_log_dir_; }

   private:
    bool is_main_process_;

    TokenEncryptor encryptor_;

    base::FilePath temp_log_dir_;

    base::FilePath compress_log_dir_;

    std::atomic<int64_t> total_log_file_size_limit_{0};
  };

  struct TNCConfig {
    LogLevel log_level{USER};

    // Wether enable continuous output log to file.
    bool enable_file_log{false};

    // The largest number of log entries in single log file,
    // when continuously output log file. In millisecond.
    int64_t split_file_log_count{30000};

    // The longest time of single file when continuous output log file.
    int64_t split_file_log_interval{60 * 60 * 1000};

    // Restriction of all temp files' size. In byte.
    int64_t temp_log_file_size_limit{10 * 1024 * 1024};

    // Restriction of all compressed files' size. In byte.
    int64_t total_log_file_size_limit{1024 * 1024 * 10};

    // Whether to save error-logs, which are based on net-errors.
    bool enable_error_log{false};

    // Logs of requests with these net-errors will be written.
    std::set<int> target_net_errors;

    // Restriction of continnuous output count, after beyond restriction,
    // do not output log in error_log_output_interval time.
    size_t error_log_output_limit{3};

    // In millisecond.
    int64_t error_log_output_interval{10 * 60 * 1000};

    // Number of error-log entries cached in memory
    size_t error_log_cache_limit{1000};

    // NetLog will not save the query part of URLs with these schemes.
    std::set<std::string> schemes_without_query;

    // The maximum time for NetLog configuration to open is 1 hour by default.
    int64_t duration_time_s{0};

    // The reason of update config.
    UpdateSource update_source{UpdateSource::TTSERVER};

    // The level of this config.
    ConfigLevel config_level{HIGH};
    TNCConfig();
    ~TNCConfig();
    TNCConfig(const TNCConfig& other);
    bool operator==(const TNCConfig& other) {
      return (log_level == other.log_level) &&
             (enable_file_log == other.enable_file_log) &&
             (split_file_log_count == other.split_file_log_count) &&
             (split_file_log_interval == other.split_file_log_interval) &&
             (temp_log_file_size_limit == other.temp_log_file_size_limit) &&
             (total_log_file_size_limit == other.total_log_file_size_limit) &&
             (enable_error_log == other.enable_error_log) &&
             (target_net_errors == other.target_net_errors) &&
             (error_log_output_limit == other.error_log_output_limit) &&
             (error_log_output_interval == other.error_log_output_interval) &&
             (error_log_cache_limit == other.error_log_cache_limit) &&
             (schemes_without_query == other.schemes_without_query) &&
             (duration_time_s == other.duration_time_s) &&
             (update_source == other.update_source) &&
             (config_level == other.config_level);
    }
    bool operator!=(const TNCConfig& other) { return !(*this == other); }
  };

  NetLogManager();

  void OnServerConfigChanged(
      const UpdateSource source,
      const base::Optional<base::Value>& tnc_config_value) override;

  void ReadTNCConfigFromCache();

  bool SetLogRootPath(const std::string& temp_log_path,
                      const std::string& log_path);

  void ReportLogStorageInfo() const;

  bool ParseJsonResult(const UpdateSource source,
                       const base::Optional<base::Value>& tnc_config_value);

  void StartFileLog();

  void StopFileLog();

  void StartErrorLog();

  void StopErrorLog();

  void SaveErrorLog();

  void StopNetLogObservingByTimer();

  bool initialized_;

  bool is_main_process_;

  TNCConfig tnc_config_;

  // Mark if the config is changed.
  bool is_config_changed_{false};

  int64_t last_output_log_time_;

  size_t continuous_output_log_count_;

  bool file_log_observer_started_;

  base::FilePath log_dir_path_;

  base::FilePath temp_log_path_;

  bool mem_net_log_observer_started_;

  // Trigger the function after a delay of duration_time.
  base::OneShotTimer net_log_timeout_close_timer_;

  scoped_refptr<URLRequestContextGetter> url_request_context_getter_;

  std::unique_ptr<TTNetlogFileObserver> file_net_log_observer_;

  std::unique_ptr<MemLruNetLogObserver> mem_net_log_observer_;

  // accessed by file thread
  scoped_refptr<base::SingleThreadTaskRunner> file_task_runner_;

  std::unique_ptr<CompressFileWriter> compress_file_writer_;

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
 public:
  void DeinitForTesting();
  void SetLogLevelForTesting(LogLevel level) { tnc_config_.log_level = level; }
  void SetURLRequestContextGetterForTesting(
      URLRequestContextGetter* context_getter) {
    url_request_context_getter_ = context_getter;
  }
  void SetCreateLogDirectoryFailedForTesting(bool fail) {
    create_directory_failed_for_testing_ = fail;
  }

  void CompressAndEntryptForTesting(const std::string& json,
                                    const std::string& file_name_str) {
    compress_file_writer_->CompressAndEntrypt(json, file_name_str);
  }

  void CleanOldestLogForTesting() { compress_file_writer_->CleanOldestLog(); }

  void CheckUncompressedFileLogsForTesting(int64_t now) {
    compress_file_writer_->CheckUncompressedFileLogs(now);
  }

  bool IsLowLevelForTesting() const { return tnc_config_.config_level == LOW; }

  bool IsMidLevelForTesting() const { return tnc_config_.config_level == MID; }

  bool IsHighLevelForTesting() const {
    return tnc_config_.config_level == HIGH;
  }

  bool IsDurationTimeForTesting() const {
    return tnc_config_.duration_time_s != 0;
  }

 private:
  friend class NetLogManagerTest;
  friend class NetLogManagerTestByMockTime;
  friend class NetLogManagerTestFunction;
  std::string recent_net_log_json_for_testing_;
  std::string file_name_str_for_testing_;
  int64_t start_for_testing_{0};
  int64_t end_for_testing_{0};
  int64_t seq_for_testing_{0};
  bool create_directory_failed_for_testing_{false};
#endif

  DISALLOW_COPY_AND_ASSIGN(NetLogManager);
};

}  // namespace net

#endif /* NET_TTNET_NETLOG_NET_LOG_MANAGER_H_ */
