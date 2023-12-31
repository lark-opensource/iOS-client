// Copyright (c) 2020 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_LOG_FILE_OBSERVER_H_
#define NET_TT_NET_LOG_FILE_OBSERVER_H_

#include <stdio.h>
#include <queue>

#include "base/files/file_enumerator.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/files/scoped_file.h"
#include "base/macros.h"
#include "base/memory/ref_counted.h"
#include "base/thread_annotations.h"
#include "net/base/net_export.h"
#include "net/log/net_log.h"
#include "net/net_buildflags.h"

namespace base {
class Value;
class SingleThreadTaskRunner;
}  // namespace base

namespace net {

class URLRequestContext;

class NET_EXPORT TTNetlogFileObserver : public NetLog::ThreadSafeObserver {
 public:
  // Implementation must be called on file thread.
  class FileCloseListener {
   public:
    virtual ~FileCloseListener() {}
    virtual void OnLogFileClosed(const std::string& file_name_str,
                                 int64_t create_log_file_time) = 0;
  };

  struct Config {
    // If a temp file hasn't been splitted for |split_file_time_interval|,
    // split it.
    int64_t temp_file_split_time_interval_ms{60 * 60 * 1000};

    // Temp file will be splitted every |file_split_entry_count| entries.
    int64_t temp_file_split_entry_count{30000};

    // Total size limit of all temp files.
    int64_t temp_file_total_size_limit{10 * 1024 * 1024};

    base::FilePath log_dir_path;

    bool is_main_process{false};
  };

  TTNetlogFileObserver(
      scoped_refptr<base::SingleThreadTaskRunner> file_task_runner,
      FileCloseListener* listener);

  ~TTNetlogFileObserver() override;

  void StartObservingWithConfig(URLRequestContext* url_request_context,
                                NetLog* net_log,
                                NetLogCaptureMode capture_mode,
                                const Config& config);

  void StopObserving();

  void OnAddEntry(const NetLogEntry& entry) override;

 private:
  // Network Thread accesses.
  Config config_;
  scoped_refptr<base::SingleThreadTaskRunner> file_task_runner_;

  // File thread accesses.
  base::ScopedFILE log_file_;
  int64_t create_log_file_time_{0};
  std::string log_file_name_;
  FileCloseListener* listener_{nullptr};

  // Multi-thread access.
  base::Lock cache_lock_;
  std::queue<std::unique_ptr<std::string>> netlog_cache_
      GUARDED_BY(cache_lock_);
  std::atomic<int64_t> log_count_{0};
  std::atomic<bool> added_events_{false};

  // Called on file thread.
  void StopCurrentFileOnFileThread();

  void FlushOnFileThread(const Config& config);

  bool CheckCreateNewFile(const base::Time& now, const Config& config);

  bool ValidateTempLogSize(const Config& config);

  size_t AddLogToCache(std::unique_ptr<std::string> log_str);

  void SwapCache(std::queue<std::unique_ptr<std::string>>* temp_cache);

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
 public:
  const std::queue<std::unique_ptr<std::string>>& netlog_cache_for_testing();

 private:
  friend class NetLogManagerTest;
  friend class NetLogManagerTestByMockTime;
  friend class NetLogManagerTestFunction;
#endif

  DISALLOW_COPY_AND_ASSIGN(TTNetlogFileObserver);
};

}  // namespace net

#endif  // NET_TT_NET_LOG_FILE_OBSERVER_H_
