// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_BASE_TRACE_EVENT_TRACE_CONTROLLER_H_
#define LYNX_BASE_TRACE_EVENT_TRACE_CONTROLLER_H_

#include <unistd.h>

#include <chrono>
#include <map>
#include <memory>
#include <string>
#include <vector>

#include "base/base_export.h"
#include "base/trace_event/perfetto_trace_backend.h"
#include "third_party/fml/thread.h"

namespace lynx {
namespace base {
namespace tracing {

struct TraceConfig {
  const uint32_t kDefaultBufferSize = 4096;  // kb
  const uint32_t kDefaultShmemSize = 1024;   // kb
  // TODO(wangjianliang): implement RECORD_UNTIL_FULL,
  // RECORD_AS_MUCH_AS_POSSIBLE, ECHO_TO_CONSOLE
  enum RecordMode {
    RECORD_AS_MUCH_AS_POSSIBLE,
    RECORD_UNTIL_FULL,
    RECORD_CONTINUOUSLY,
    ECHO_TO_CONSOLE
  } record_mode;
  enum BackendType { TRACE_BACKEND_IN_PROCESS, TRACE_BACKEND_SYSTEM } backend;
  enum TransferMode { REPORT_EVENTS, RETURN_AS_STREAM } transfer_mode;
  bool enable_systrace;
  uint32_t buffer_size;
  uint32_t shmem_size;
  std::vector<std::string> included_categories;
  std::vector<std::string> excluded_categories;
  std::string file_path;
  std::string perfetto_config;
  TraceConfig()
      : record_mode(RECORD_AS_MUCH_AS_POSSIBLE),
        backend(TRACE_BACKEND_IN_PROCESS),
        transfer_mode(RETURN_AS_STREAM),
        enable_systrace(false),
        buffer_size(kDefaultBufferSize),
        shmem_size(kDefaultShmemSize) {}
};

class TracePlugin : public std::enable_shared_from_this<TracePlugin> {
 public:
  TracePlugin() = default;
  virtual ~TracePlugin() = default;
  virtual void DispatchBegin() = 0;
  virtual void DispatchEnd() = 0;
};

class BASE_EXPORT_FOR_DEVTOOL TraceController {
 public:
#if LYNX_ENABLE_TRACING
  struct TracingSession {
    TracingSession() : id(-1), started(false), all_read(false){};
    ~TracingSession() {
      for (int fd : opened_fds) {
        if (fd > 0) {
          close(fd);
        }
      }
    }
    std::shared_ptr<TraceConfig> config;
    int id;
    std::unique_ptr<lynx::perfetto::TracingSession> session_impl;
    std::unique_ptr<TraceBackend::Impl> backend_impl;
    std::vector<int> opened_fds;
    std::vector<std::function<void()>> complete_callbacks;
    bool started;
    std::vector<std::function<void(const std::vector<char> &)>> event_callbacks;
    std::vector<char> raw_traces;
    std::vector<char> unsent_traces;
    bool all_read;
    std::mutex read_mutex;
    std::condition_variable read_cv;
    std::chrono::high_resolution_clock::time_point read_trace_begin;
    std::chrono::high_resolution_clock::time_point read_trace_end;
  };
#endif  // LYNX_ENABLE_TRACING

  TraceController() = default;
  virtual ~TraceController() = default;

  virtual void Initialize();
  virtual int StartTracing(const std::shared_ptr<TraceConfig> &config);
  virtual void StopTracing(int session_id);
  virtual void RecordClockSyncMarker(const std::string &sync_id);
  virtual std::string GenerateTracingFilePath() = 0;
#if LYNX_ENABLE_TRACING
  virtual bool RegisterTraceBackend(TraceBackend::Impl *) = 0;
#endif  // LYNX_ENABLE_TRACING
  // run task on ui thread and block until it get finished.
  virtual void AddTracePlugin(TracePlugin *plugin);
#ifdef OS_ANDROID
  virtual void RefreshATraceTags() = 0;
#endif  // OS_ANDROID
  void AddCompleteCallback(int session_id,
                           const std::function<void()> callback);
  void RemoveCompleteCallbacks(int session_id);

  void AddEventsCallback(
      int session_id,
      const std::function<void(const std::vector<char> &)> callback);
  void RemoveEventsCallbacks(int session_id);

 private:
#if LYNX_ENABLE_TRACING
  const std::string kTraceFileSuffix = ".pftrace";
  virtual TracingSession &CreateNewSession(
      const std::shared_ptr<TraceConfig> config);
  std::map<int, std::unique_ptr<TracingSession>> tracing_sessions_;
  std::unique_ptr<TraceBackend::Impl> empty_backend_;
  std::vector<TracePlugin *> trace_plugins_;
  std::unique_ptr<fml::Thread> worker_thread_;
#endif  // LYNX_ENABLE_TRACING
};

}  // namespace tracing
}  // namespace base
}  // namespace lynx
#endif  // LYNX_BASE_TRACE_EVENT_TRACE_CONTROLLER_H_
