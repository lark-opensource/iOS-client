//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "recorder/media_recorder.h"

#include "canvas/base/log.h"
#include "config/config.h"
#include "jsbridge/napi/callback_helper.h"
#include "third_party/fml/make_copyable.h"

namespace lynx {
namespace canvas {

namespace {
std::string GenerateUniqueId() {
  static uint32_t s_unique_id = 0;
  return std::to_string(++s_unique_id);
}
constexpr char collector_name[] = "kryptonMediaRecorderCollector";

class AppShowStatusObserverImpl : public AppShowStatusObserver {
 public:
  AppShowStatusObserverImpl(MediaRecorder& ref) : ref_(ref) {}
  void OnAppEnterForeground() { ref_.OnAutoResume(); }
  void OnAppEnterBackground() { ref_.OnAutoPause(); }

 private:
  MediaRecorder& ref_;
};
}  // namespace

MediaRecorder::MediaRecorder(const Config& config, SurfaceCallback callback)
    : id_(GenerateUniqueId()), config_(config), surface_callback_(callback) {
  KRYPTON_CONSTRUCTOR_LOG(MediaRecorder);
  state_ = kInitialized;
}

MediaRecorder::~MediaRecorder() { KRYPTON_DESTRUCTOR_LOG(MediaRecorder); }

MediaRecorder::Config::Config(MediaRecorderConfig& config, uint32_t src_width,
                              uint32_t src_height) {
  delete_file_on_destroy = config.deleteFilesOnDestroy();
  auto_pause_and_resume = config.autoPauseAndResume();
  mime_type = "video/avc";
  duration = config.duration();

  if (config.hasWidth()) {
    video.width = config.width();
    video.height = config.hasHeight() ? config.height()
                                      : (video.width * src_height / src_width);
  } else if (config.hasHeight()) {
    video.height = config.height();
    video.width = video.height * src_width / src_height;
  } else {
    video.width = src_width;
    video.height = src_height;
  }
  // The width and height of the video must be even
  video.width = ((video.width + 2) >> 2) << 2;
  video.height = ((video.height + 2) >> 2) << 2;
  video.fps = config.fps();
  video.bps = config.hasBps() ? config.bps() : (video.width * video.height * 2);

  ResetAudioConfig();
}

void MediaRecorder::Config::ResetAudioConfig() {
  audio.engine.reset();
  audio.bps = audio.chanels = audio.sample_rate = 0;
}

void MediaRecorder::Config::SetAudioConfig(
    std::weak_ptr<au::AudioEngine> weak_engine) {
  auto engine = weak_engine.lock();
  if (engine) {
    audio.engine = weak_engine;
    audio.bps = 128 * 1024;
    audio.chanels = 2;
    audio.sample_rate = 44100;
  } else {
    ResetAudioConfig();
  }
}

bool MediaRecorder::CheckOnJSThread() const {
  return canvas_app_ != nullptr &&
         canvas_app_->runtime_task_runner()->RunsTasksOnCurrentThread();
}

void MediaRecorder::RemoveSurface() {
  if (surface_callback_) {
    surface_callback_(surface_key_, nullptr);
    KRYPTON_LOGI("Remove surface ") << surface_key_;
    surface_key_ = 0;
  }
}

bool MediaRecorder::AddSurface(std::unique_ptr<Surface> surface) {
  if (surface_callback_) {
    surface_key_ = reinterpret_cast<uintptr_t>(surface.get());
    KRYPTON_LOGI("AddSurface ") << surface_key_;
    return surface_callback_(surface_key_, std::move(surface));
  } else {
    return false;
  }
}

void MediaRecorder::PostStatusChanged() {
  KRYPTON_LOGI("Recorder status changed to ") << StatusString();
}

std::string MediaRecorder::GetState() {
  switch (state_) {
    case kRunning:
      return "recording";
    case kPaused:
    case kAutoPaused:
      return "paused";
    default:
      return "inactive";
  }
}

bool MediaRecorder::IsTypeSupported(const std::string& type) {
  std::string lower_type;
  std::transform(type.begin(), type.end(), lower_type.begin(), ::tolower);
  return lower_type == config_.mime_type;
}

bool MediaRecorder::Start() {
  DCHECK(CheckOnJSThread());

  switch (state_) {
    case kRunning:
      KRYPTON_LOGW("Recorder is running, ignore this command");
      return true;
    case kPaused:
    case kAutoPaused:
      KRYPTON_LOGW("Recorder is paused, continue to resume");
      return Resume();
    case kStopping:
      InvokeCallbackWithError(kErrorRecordStart,
                              "Recorder is stopping, could not start now");
      return false;
    default:
      break;
  }

  HoldObject();  // to release in OnRecordStopWithError or OnRecordStopWithData

  clip_time_ranges_.clear();

  if (!DoStart()) {
    state_ = kError;
    PostStatusChanged();
    // invoke callback in OnRecordStartWithResult
    return false;
  }

  state_ = kRunning;
  PostStatusChanged();
  // invoke callback in OnRecordStartWithResult
  return true;
}

bool MediaRecorder::Stop() {
  DCHECK(CheckOnJSThread());

  switch (state_) {
    case kRunning:
    case kPaused:
    case kAutoPaused:
      break;
    case kError:
      KRYPTON_LOGW(
          "Recorder has already been stopped with error, ignore this command");
      return false;
    default:
      KRYPTON_LOGW("Recorder is not running, ignore this command");
      return true;
  }

  state_ = kStopping;
  DoStop();
  PostStatusChanged();
  // invoke callback in OnRecordStopWithError or OnRecordStopWithData
  return true;
}

bool MediaRecorder::Pause() {
  DCHECK(CheckOnJSThread());

  switch (state_) {
    case kPaused:
      KRYPTON_LOGW("Recorder has already been paused, ignore this command");
      return true;
    case kAutoPaused:
      state_ = kPaused;
      InvokeCallback(kEventRecordPause);
      return true;
    case kRunning:
      break;
    default:
      InvokeCallbackWithError(kErrorRecordPause, "Recorder is not running");
      return false;
  }

  if (!DoPause()) {
    InvokeCallbackWithError(kErrorRecordPause, "platform pause failed.");
    return false;
  }

  state_ = kPaused;
  InvokeCallback(kEventRecordPause);
  PostStatusChanged();
  return true;
}

bool MediaRecorder::Resume() {
  DCHECK(CheckOnJSThread());

  switch (state_) {
    case kRunning:
      KRYPTON_LOGW("Recorder is running, ignore this command");
      return true;
    case kPaused:
    case kAutoPaused:
      break;
    default:
      InvokeCallbackWithError(kErrorRecordResume, "Recorder is not paused");
      return false;
  }

  if (!DoResume()) {
    InvokeCallbackWithError(kErrorRecordResume, "platform resume failed.");
    return false;
  }

  state_ = kRunning;
  InvokeCallback(kEventRecordResume);
  PostStatusChanged();
  return true;
}

bool MediaRecorder::Clip() {
  DCHECK(CheckOnJSThread());

  if (state_ != kStopped) {
    InvokeCallbackWithError(kErrorClip, "status not stopped");
    return false;
  }

  if (clip_time_ranges_.empty()) {
    InvokeCallbackWithError(kErrorClip, "no clip time ranges");
    return false;
  }

  if (!DoClip()) {
    InvokeCallbackWithError(kErrorClip, "platform start clip failed");
    return false;
  }

  HoldObject();  // to release in OnClipStopWithError or OnClipStopWithData

  InvokeCallback(kEventClipStart);
  return true;
}

int32_t MediaRecorder::AddClipTimeRange(int32_t before, int32_t after) {
  DCHECK(CheckOnJSThread());

  switch (state_) {
    case kInitialized:
    case kError:
      return -1;
    default:
      break;
  }

  if (before < 0 || after < 0) {
    InvokeCallbackWithError(kErrorAddClipTimeRange, "no clip time ranges");
    return -1;
  }

  int64_t time_us = 0;
  if (!DoGetCurrentTime(time_us)) {
    InvokeCallbackWithError(kErrorAddClipTimeRange, "get platform time error");
    return -1;
  }

  auto start_time = time_us - before * 1e6, end_time = time_us + after * 1e6;
  if (start_time < 0) {
    start_time = 0;
  }
  if (end_time < start_time) {
    end_time = start_time;
  }

  int32_t index = static_cast<int32_t>(clip_time_ranges_.size());
  KRYPTON_LOGI("record addClipTimeRange index:")
      << index << " time:" << time_us << " before:" << before
      << ", after:" << after;
  clip_time_ranges_.push_back(std::make_pair(start_time, end_time));
  return index;
}

void MediaRecorder::RunOnJSThread(std::function<void(MediaRecorder&)> func) {
  DCHECK(canvas_app_);
  auto weak_guard =
      std::weak_ptr<InstanceGuard<MediaRecorder>>(instance_guard_);
  canvas_app_->runtime_task_runner()->PostTask(
      fml::MakeCopyable([weak_guard, func = std::move(func)]() mutable {
        auto shared_guard = weak_guard.lock();
        if (shared_guard) {
          func(*(shared_guard->Get()));
        }
      }));
}

void MediaRecorder::OnAutoPause() {
  RunOnJSThread([](auto& impl) {
    if (impl.state_ == kRunning) {
      if (impl.DoPause()) {
        impl.state_ = kAutoPaused;
        impl.InvokeCallback(kEventRecordPause);
      } else {
        impl.state_ = kError;
      }
      impl.PostStatusChanged();
    }
  });
}

void MediaRecorder::OnAutoResume() {
  RunOnJSThread([](auto& impl) {
    if (impl.state_ == kAutoPaused) {
      impl.Resume();
    }
  });
}

void MediaRecorder::OnRecordStartWithResult(bool result, const char* error) {
  if (result) {
    RunOnJSThread([](auto& impl) { impl.InvokeCallback(kEventRecordStart); });
  } else {
    const std::string err_str(error ?: "");
    RunOnJSThread([err_str = std::move(err_str)](auto& impl) {
      impl.state_ = kError;
      impl.InvokeCallbackWithError(kErrorRecordStart, err_str);
    });
  }
}

void MediaRecorder::OnRecordStopWithData(const DataInfo& data) {
  RunOnJSThread([data = std::move(data)](auto& impl) {
    impl.state_ = kStopped;
    impl.PostStatusChanged();
    impl.InvokeCallbackWithData(kEventRecordStop, data);
    impl.ReleaseObject();
  });
}

void MediaRecorder::OnRecordStopWithError(const char* error) {
  const std::string err_str(error ?: "");
  RunOnJSThread([err_str = std::move(err_str)](auto& impl) {
    impl.state_ = kError;
    impl.PostStatusChanged();
    // send both onerror and onstop
    impl.InvokeCallbackWithError(kErrorRecordStop, err_str);
    impl.InvokeCallbackWithError(kErrorRecordStop, err_str, kEventRecordStop);
    impl.ReleaseObject();
  });
}

void MediaRecorder::OnClipStopWithData(const DataInfo& data) {
  RunOnJSThread([data = std::move(data)](auto& impl) {
    impl.InvokeCallbackWithData(kEventClipEnd, data);
    impl.ReleaseObject();
  });
}

void MediaRecorder::OnClipStopWithError(const char* error) {
  const std::string err_str(error ?: "");
  RunOnJSThread([err_str = std::move(err_str)](auto& impl) {
    // send both onerror and onclipend
    impl.InvokeCallbackWithError(kErrorClip, err_str);
    impl.InvokeCallbackWithError(kErrorClip, err_str, kEventClipEnd);
    impl.ReleaseObject();
  });
}

void MediaRecorder::OnWrapped() {
  canvas_app_ = CanvasModule::From(Env())->GetCanvasApp();
  if (!instance_guard_) {
    instance_guard_ = InstanceGuard<MediaRecorder>::CreateSharedGuard(this);
  }
  if (!app_show_status_observer_ && config_.auto_pause_and_resume) {
    app_show_status_observer_ = std::shared_ptr<AppShowStatusObserver>(
        new AppShowStatusObserverImpl(*this));
    canvas_app_->RegisterAppShowStatusObserver(app_show_status_observer_);
  }
}

void MediaRecorder::InvokeCallbackWithData(EventType event_type,
                                           const DataInfo& data) {
  auto env = Env();
  Napi::ContextScope cscope(env);
  Napi::HandleScope hscope(env);
  auto ret = Napi::Object::New(env);
  ret["path"] = Napi::String::New(env, data.path);
  ret["url"] = Napi::String::New(env, std::string("file://") + data.path);
  ret["duration"] = Napi::Number::New(env, data.duration);
  ret["size"] = Napi::Number::New(env, data.size);
  RealInvokeCallback(event_type, ret);
}

void MediaRecorder::InvokeCallback(EventType event_type) {
  auto env = Env();
  Napi::ContextScope cscope(env);
  Napi::HandleScope hscope(env);
  RealInvokeCallback(event_type, env.Null());
}

void MediaRecorder::InvokeCallbackWithError(ErrorType err_type,
                                            const std::string& err_msg,
                                            EventType event_type) {
  std::string err_type_str = ErrorTypeToString(err_type);
  std::string err_msg_str = "record ";
  err_msg_str += err_type_str;
  err_msg_str += " error: ";
  err_msg_str += err_msg;
  auto env = Env();
  Napi::ContextScope cscope(env);
  Napi::HandleScope hscope(env);
  auto ret = Napi::Object::New(env);
  ret["err_type"] = Napi::String::New(env, err_type_str);
  ret["err_msg"] = Napi::String::New(env, err_msg_str);
  RealInvokeCallback(event_type, ret);
}

void MediaRecorder::RealInvokeCallback(EventType event_type,
                                       Napi::Value value) {
  auto event_name = EventTypeToString(event_type);
  TriggerEventListeners(event_name, value);
  auto callback_name = std::string("on") + event_name;
  if (JsObject().Has(callback_name.c_str())) {
    Napi::Value callback = JsObject()[callback_name.c_str()];
    if (callback.IsFunction()) {
      piper::CallbackHelper helper;
      Napi::Function callback_function = callback.As<Napi::Function>();
      if (helper.PrepareForCall(callback_function)) {
        helper.Call({value});
      }
    }
  }
}

void MediaRecorder::HoldObject() {
  Napi::Env env = Env();
  Napi::ContextScope cscope(env);
  Napi::HandleScope hscope(env);
  if (!env.Global().Has(collector_name)) {
    env.Global()[collector_name] = Napi::Object::New(env);
  }
  Napi::Value collector = env.Global()[collector_name];
  Napi::Object collector_obj = collector.As<Napi::Object>();
  collector_obj[id_.c_str()] = JsObject();
}

void MediaRecorder::ReleaseObject() {
  Napi::Env env = Env();
  Napi::ContextScope cscope(env);
  Napi::HandleScope hscope(env);
  if (!env.Global().Has(collector_name)) {
    return;
  }
  Napi::Value collector = env.Global()[collector_name];
  Napi::Object collector_obj = collector.As<Napi::Object>();
  if (collector_obj.Has(id_.c_str())) {
    collector_obj.Delete(id_.c_str());
  }
}

bool MediaRecorder::MergeClipTimeRanges(
    std::function<void(uint64_t, uint64_t)> range_callback) {
  if (clip_time_ranges_.empty()) {
    return false;
  }

  std::vector<std::pair<uint64_t, bool>> order_vec;
  for (auto it = clip_time_ranges_.begin(); it != clip_time_ranges_.end();
       ++it) {
    order_vec.emplace_back(std::make_pair(it->first, true));
    order_vec.emplace_back(std::make_pair(it->second, false));
  }

  struct {
    bool operator()(const std::pair<uint64_t, bool>& a,
                    std::pair<uint64_t, bool>& b) const {
      return a.first < b.first;
    }
  } compareFirst;
  std::sort(order_vec.begin(), order_vec.end(), compareFirst);

  static uint64_t min_interval = 5e5;
  bool has_start = false, has_end = false, has_result = false;
  uint64_t first_start = 0, last_end = 0;
  for (auto it = order_vec.begin(); it != order_vec.end(); ++it) {
    if (!it->second) {
      // end
      last_end = it->first;
      has_end = true;
      continue;
    }

    // start
    if (has_start && has_end) {
      if (last_end >= first_start + min_interval &&
          it->first > last_end + min_interval) {
        range_callback(first_start, last_end);
        has_result = true;
        has_start = has_end = false;
      }
    }

    if (!has_start) {
      first_start = it->first;
      has_start = true;
    }
  }

  if (has_start && has_end && last_end >= first_start + min_interval) {
    range_callback(first_start, last_end);
    has_result = true;
  }

  return has_result;
}

const char* MediaRecorder::StatusString() {
  switch (state_) {
    case kInitialized:
      return "initialized";
    case kRunning:
      return "running";
    case kPaused:
      return "paused";
    case kAutoPaused:
      return "auto-paused";
    case kStopped:
      return "stopped";
    case kStopping:
      return "stopping";
    case kError:
      return "error";
    default:
      return "unknown";
  }
}

const char* MediaRecorder::EventTypeToString(EventType type) {
  switch (type) {
    case kEventError:
      return "error";
    case kEventRecordStart:
      return "start";
    case kEventRecordStop:
      return "stop";
    case kEventRecordPause:
      return "pause";
    case kEventRecordResume:
      return "resume";
    case kEventClipStart:
      return "clipstart";
    case kEventClipEnd:
      return "clipend";
    default:
      return "error";
  }
}

const char* MediaRecorder::ErrorTypeToString(ErrorType type) {
  switch (type) {
    case kErrorRecordStart:
      return "start";
    case kErrorRecordStop:
      return "stop";
    case kErrorRecordPause:
      return "pause";
    case kErrorRecordResume:
      return "resume";
    case kErrorClip:
      return "clip";
    case kErrorAddClipTimeRange:
      return "addClipTimeRange";
    default:
      return "";
  }
}

}  // namespace canvas
}  // namespace lynx
