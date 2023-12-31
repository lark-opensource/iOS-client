// Copyright 2020 The Lynx Authors. All rights reserved.

#include "base/trace_event/trace_controller.h"

#include <fcntl.h>

#include <fstream>
#include <memory>
#include <mutex>
#include <numeric>
#include <string>

#include "base/log/logging.h"
#include "base/threading/task_runner_manufactor.h"

namespace lynx {
namespace base {
namespace tracing {

constexpr int kInvalidSessionId = -1;

#if LYNX_ENABLE_TRACING
constexpr const int kTraceBufferLimit = 1024 * 1024;
#endif

void TraceController::Initialize() {
#if LYNX_ENABLE_TRACING
  empty_backend_ = std::make_unique<TraceBackend::Impl>();
  worker_thread_ = std::make_unique<fml::Thread>("Lynx_ConfigServer");
#endif
}

void TraceController::RecordClockSyncMarker(const std::string& sync_id) {
  // TODO(wangjianliang): implement this function.
}

int TraceController::StartTracing(const std::shared_ptr<TraceConfig>& config) {
#if LYNX_ENABLE_TRACING
  lynx::perfetto::TracingInitArgs args;
#if OS_ANDROID
  // only android support system backend
  args.backends |= (config->backend == TraceConfig::TRACE_BACKEND_SYSTEM
                        ? lynx::perfetto::kSystemBackend
                        : lynx::perfetto::kInProcessBackend);
#else
  args.backends |= lynx::perfetto::kInProcessBackend;
#endif
  args.shmem_size_hint_kb = config->shmem_size;
  lynx::perfetto::Tracing::Initialize(args);
  lynx::perfetto::TrackEvent::Register();

  auto& session = CreateNewSession(config);
  session.config = config;

  lynx::perfetto::protos::gen::TrackEventConfig track_event_cfg;
  auto* enabled_categories = track_event_cfg.mutable_enabled_categories();
  auto* disabled_categories = track_event_cfg.mutable_disabled_categories();
  enabled_categories->insert(enabled_categories->begin(),
                             config->included_categories.begin(),
                             config->included_categories.end());
  disabled_categories->insert(disabled_categories->begin(),
                              config->excluded_categories.begin(),
                              config->excluded_categories.end());
  if (std::find(enabled_categories->begin(), enabled_categories->end(),
                LYNX_TRACE_CATEGORY_SCREENSHOTS) != enabled_categories->end()) {
    track_event_cfg.add_enabled_tags("Screenshot");
  }

  lynx::perfetto::TraceConfig cfg;
  auto* ds_cfg = cfg.add_data_sources()->mutable_config();
  ds_cfg->set_name("track_event");
  ds_cfg->set_track_event_config_raw(track_event_cfg.SerializeAsString());
  DCHECK(config->buffer_size > 0);
  cfg.set_flush_period_ms(1000);
  cfg.add_buffers()->set_size_kb(config->buffer_size);

  if (config->file_path.empty()) {
    config->file_path = GenerateTracingFilePath();
  }
  if (config->record_mode == TraceConfig::RECORD_CONTINUOUSLY &&
      config->backend == TraceConfig::TRACE_BACKEND_IN_PROCESS) {
    // write trace events from buffer to file every 3 seconds.
    DCHECK(!config->file_path.empty());
    cfg.set_file_write_period_ms(3 * 1000);
    int fd = open(config->file_path.c_str(), O_RDWR | O_CREAT | O_TRUNC, 0600);
    session.opened_fds.push_back(fd);
    session.session_impl->Setup(cfg, fd);
  } else {
    session.session_impl->Setup(cfg);
  }

  session.session_impl->StartBlocking();
  session.backend_impl = std::make_unique<PerfettoTraceBackend>();
  if (session.backend_impl) {
    if (!RegisterTraceBackend(session.backend_impl.get())) {
      session.backend_impl.reset(nullptr);
      return kInvalidSessionId;
    }
  }
  session.backend_impl->Start(session.config->enable_systrace);
  for (auto& trace_plugin : trace_plugins_) {
    if (trace_plugin) {
      trace_plugin->DispatchBegin();
    }
  }
  session.started = true;
  LOGI("Tracing started, session id: " << session.id << " buffer size: "
                                       << config->buffer_size);
#ifdef OS_ANDROID
  RefreshATraceTags();
#endif
  return session.id;
#else
  return kInvalidSessionId;
#endif
}

void TraceController::StopTracing(int session_id) {
#if LYNX_ENABLE_TRACING
  // Stop tracing and read the trace data.
  auto session_pair = tracing_sessions_.find(session_id);
  if (session_pair == tracing_sessions_.end()) {
    LOGE("Tracing session not found: " << session_id);
    return;
  }
  for (auto& trace_plugin : trace_plugins_) {
    if (trace_plugin) {
      trace_plugin->DispatchEnd();
    }
  }
  trace_plugins_.clear();
  auto& session = session_pair->second;
  session->backend_impl->Stop(session->config->enable_systrace);
  RegisterTraceBackend(empty_backend_.get());
  if (session->config->transfer_mode == TraceConfig::RETURN_AS_STREAM) {
    session->backend_impl->Stop();
  } else {
    worker_thread_->GetTaskRunner()->PostTask(
        [s = session.get()]() { s->backend_impl->Stop(); });
  }
  session->session_impl->StopBlocking();
  session->started = false;
  LOGI("Tracing stopped, file path:" << session->config->file_path);
  DCHECK(session->config != nullptr);

  // TODO(wangjianliang): call callback functions asynchronously
  if (session->config->backend == TraceConfig::TRACE_BACKEND_IN_PROCESS) {
    if (session->config->record_mode == TraceConfig::RECORD_CONTINUOUSLY) {
      for (int& fd : session->opened_fds) {
        fsync(fd);
        close(fd);
      }
      session->opened_fds.clear();
    } else {
      if (session->config->transfer_mode == TraceConfig::RETURN_AS_STREAM) {
        std::vector<char> trace_data(
            session->session_impl->ReadTraceBlocking());
        std::ofstream output(session->config->file_path,
                             std::ios::out | std::ios::binary);
        output.write(&trace_data[0], trace_data.size());
        output.flush();
      } else if (session->config->transfer_mode == TraceConfig::REPORT_EVENTS) {
        TracingSession* s = session.get();
        worker_thread_->GetTaskRunner()->PostTask([s, this, session_id]() {
          while (true) {
            bool all_read = false;
            std::vector<char> pending;
            {
              std::unique_lock<std::mutex> lock(s->read_mutex);
              s->read_cv.wait(lock, [s] {
                return s->all_read ||
                       s->unsent_traces.size() > kTraceBufferLimit;
              });
              all_read = s->all_read;
              pending.swap(s->unsent_traces);
            }

            if (!pending.empty()) {
              for (const auto& callback : s->event_callbacks) {
                callback(pending);
              }

              s->raw_traces.insert(s->raw_traces.end(), pending.begin(),
                                   pending.end());
            }

            if (all_read) {
              for (const auto& callback : s->complete_callbacks) {
                callback();
              }
              std::ofstream output(s->config->file_path,
                                   std::ios::out | std::ios::binary);
              output.write(&s->raw_traces[0], s->raw_traces.size());
              output.flush();
              UNUSED_LOG_VARIABLE auto d0 =
                  std::chrono::duration_cast<std::chrono::milliseconds>(
                      s->read_trace_end - s->read_trace_begin)
                      .count();
              LOGI("read trace cost: " << d0 / 1000.0 << "(s)");
              // register an empty backend to avoid using a lock
              tracing_sessions_.erase(session_id);
              break;
            }
          }
        });
        session->read_trace_begin = std::chrono::high_resolution_clock::now();
        session->session_impl->ReadTrace(
            [s](lynx::perfetto::TracingSession::ReadTraceCallbackArgs args) {
              std::unique_lock<std::mutex> lock(s->read_mutex);
              s->unsent_traces.insert(s->unsent_traces.end(), args.data,
                                      args.data + args.size);
              s->all_read = !args.has_more;
              if (s->unsent_traces.size() > kTraceBufferLimit || !args.has_more)
                s->read_cv.notify_one();
              if (!args.has_more)
                s->read_trace_end = std::chrono::high_resolution_clock::now();
            });
      }
    }
  }
  if (session->config->transfer_mode == TraceConfig::RETURN_AS_STREAM) {
    for (const auto& callback : session->complete_callbacks) {
      callback();
    }
    // register an empty backend to avoid using a lock
    tracing_sessions_.erase(session_id);
    DLOGI("Tracing stopped, session id: " << session_id);
  }
#endif
}

#if LYNX_ENABLE_TRACING
TraceController::TracingSession& TraceController::CreateNewSession(
    const std::shared_ptr<TraceConfig> config) {
  static int next_session_id = 0;
  next_session_id++;
  auto new_session = new TracingSession;
  new_session->session_impl = lynx::perfetto::Tracing::NewTrace();
  new_session->id = next_session_id;
  new_session->config = nullptr;
  new_session->started = false;
  tracing_sessions_[next_session_id] =
      std::unique_ptr<TracingSession>(new_session);
  return *new_session;
}
#endif

void TraceController::AddCompleteCallback(
    int session_id, const std::function<void()> callback) {
#if LYNX_ENABLE_TRACING
  auto session_pair = tracing_sessions_.find(session_id);
  if (session_pair == tracing_sessions_.end()) {
    LOGE("Tracing session not found: " << session_id);
    return;
  }
  auto& session = session_pair->second;
  session->complete_callbacks.push_back(callback);
#endif
}

void TraceController::RemoveCompleteCallbacks(int session_id) {
#if LYNX_ENABLE_TRACING
  auto session_pair = tracing_sessions_.find(session_id);
  if (session_pair == tracing_sessions_.end()) {
    LOGE("Tracing session not found: " << session_id);
    return;
  }
  auto& session = session_pair->second;
  session->complete_callbacks.clear();
#endif
}

void TraceController::AddEventsCallback(
    int session_id,
    const std::function<void(const std::vector<char>&)> callback) {
#if LYNX_ENABLE_TRACING
  auto session_pair = tracing_sessions_.find(session_id);
  if (session_pair == tracing_sessions_.end()) {
    LOGE("Tracing session not found: " << session_id);
    return;
  }
  auto& session = session_pair->second;
  session->event_callbacks.push_back(callback);
#endif
}

void TraceController::RemoveEventsCallbacks(int session_id) {
#if LYNX_ENABLE_TRACING
  auto session_pair = tracing_sessions_.find(session_id);
  if (session_pair == tracing_sessions_.end()) {
    LOGE("Tracing session not found: " << session_id);
    return;
  }
  auto& session = session_pair->second;
  session->event_callbacks.clear();
#endif
}

void TraceController::AddTracePlugin(TracePlugin* plugin) {
#if LYNX_ENABLE_TRACING
  if (plugin) {
    trace_plugins_.push_back(plugin);
  }
#endif
}

}  // namespace tracing
}  // namespace base
}  // namespace lynx
