// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_AUDIO_ENGINE_H_
#define LYNX_KRYPTON_AURUM_AUDIO_ENGINE_H_

#include <mutex>
#include <set>

#include "aurum/audio_context.h"
#include "aurum/audio_interface.h"
#include "aurum/aurum.h"
#include "aurum/capture_base.h"
#include "aurum/loader/platform_loader.h"
#include "jsbridge/napi/shim/shim_napi.h"

#ifdef OS_ANDROID
#include "aurum/android/audio_android.h"
#elif defined(OS_IOS)
#include "aurum/darwin/audio_ios.h"
#endif

namespace lynx {
namespace canvas {
namespace au {

class Capture;
struct SampleCallbackContext {
  std::mutex working_lock;
  bool released = false;
  AudioInterface *audio_impl = nullptr;
};

class AudioEngine {
 public:
  AudioEngine(uint32_t identify, Napi::Env env, Napi::Object exports_in,
              const Platform &platform)
      : platform_(platform),
        env_(env),
        identify_(identify),
        audio_context_(this) {
    exports_ = Napi::Persistent(exports_in);
    audio_impl_ = CreateAudioImpl();
    if (audio_impl_) {
      Status status = audio_impl_->Init(this);
      if (status.code) {
        KRYPTON_LOGE("AudioEngine init error ") << status.code;
        platform.OnInitFail(platform.user_ptr, status.line, status.code);
      } else {
        KRYPTON_LOGE("AudioEngine init success ");
        running_ = true;
      }
    }
  }

  AudioEngine(const AudioEngine &) = delete;

  AudioInterface *CreateAudioImpl() {
#ifdef OS_ANDROID
    return new AudioAndroid();
#elif defined(OS_IOS)
    return new AudioIOS();
#else
#error "unsupported platform!"
    return nullptr;
#endif
  }

  AudioContext &GetContext() { return audio_context_; }
  const Platform &GetPlatform() const { return platform_; }
  uint32_t GetIdentify() const { return identify_; }
  bool IsRunning() const { return running_; }
  void ForceSetRunning(bool running) { running_ = running; }

  void BindSampleCallbackContext(SampleCallbackContext *cb_ctx);

  Napi::Value GetJSExports() const { return aurum_js_exports_.Value(); }

  void SetAurumJSExports(Napi::Object exports) {
    aurum_js_exports_ = Napi::Persistent(exports);
  }

  void SendNodeEvent(int node_id, AudioNodeBase::NodeEvent event,
                     const std::string &err_msg);

  void SendDecodeResult(int execute_id, bool success, int channels,
                        int sample_rate, int samples, float *data);

  Capture *SetupCapture();
  void PauseCapture();
  void ResumeCapture();

  Sample Consume(int samples);

  inline void Pause() {
    audio_impl_->Pause();
    if (!GetContext().ref_mode) {
      if (audio_capture_ != nullptr) {
        audio_capture_->Pause();
      }
    }
    KRYPTON_LOGI("au::AudioEngine pause");
  }

  inline void Resume() {
    if (!GetContext().ref_mode) {
      audio_impl_->Resume();
      if (audio_capture_ != nullptr) {
        audio_capture_->Resume();
      }
    } else if (GetContext().ref_count > 0) {
      audio_impl_->Resume();
    }
    KRYPTON_LOGI("au::AudioEngine resume");
  }

  void AddSampleListener(SampleCallback *callback) {
    DCHECK(callback);
    std::lock_guard<std::mutex> lock(sample_callback_context_->working_lock);
    sample_callbacks_.insert(callback);
  }

  void RemoveSampleListener(SampleCallback *callback) {
    DCHECK(callback);
    std::lock_guard<std::mutex> lock(sample_callback_context_->working_lock);
    sample_callbacks_.erase(callback);
  }

  bool RunAfterLockSync(std::function<bool(AudioEngine *)> func) {
    if (sample_callback_context_ == nullptr ||
        sample_callback_context_->released) {
      return false;
    }
    std::lock_guard<std::mutex> lock(sample_callback_context_->working_lock);
    return func(this);
  }

#ifdef OS_IOS
  inline void OnCaptureStart() {
    if (audio_capture_ != nullptr) {
      audio_capture_->Resume();
    }
  }

  inline void OnCaptureStop() {
    if (audio_capture_ != nullptr) {
      audio_capture_->Pause();
    }
  }
#endif

  virtual ~AudioEngine() {
    KRYPTON_LOGE("~AudioEngine");
    running_ = false;
    DCHECK(sample_callback_context_ != nullptr);
    std::lock_guard<std::mutex> lock(sample_callback_context_->working_lock);
    sample_callback_context_->released = true;
    sample_callback_context_->audio_impl = nullptr;
    delete audio_capture_;
    delete audio_impl_;
    audio_impl_ = nullptr;
    audio_capture_ = nullptr;
    sample_callback_context_ = nullptr;
  }

  template <typename S>
  inline void Dispatch(S *s, void (*callback)(S *)) {
    platform_.Dispatch(platform_.user_ptr, (void *)s,
                       (void (*)(void *))callback);
  }

  template <typename S>
  inline void Dispatch(const S *s, void (*callback)(const S *)) {
    platform_.Dispatch(platform_.user_ptr, (void *)s,
                       (void (*)(void *))callback);
  }

  template <typename S>
  inline void Execute(S *s, void (*callback)(S *)) {
    platform_.Execute(platform_.user_ptr, (void *)s,
                      (void (*)(void *))callback);
  }

  template <typename S>
  inline void Execute(const S *s, void (*callback)(const S *)) {
    platform_.Execute(platform_.user_ptr, (void *)s,
                      (void (*)(void *))callback);
  }

  void SetBgmVolume(float value);
  void SetMicVolume(float value);
  void SetPostVolume(float value);

 private:
  enum class ExecuteEvent : uint32_t { AudioDataDecode = 10 };
  Platform platform_;
  AudioInterface *audio_impl_;
  CaptureBase *audio_capture_ = nullptr;
  SampleCallbackContext *sample_callback_context_ = nullptr;
  Napi::Env env_;
  Napi::ObjectReference exports_;
  Napi::ObjectReference aurum_js_exports_;
  uint32_t identify_;
  AudioContext audio_context_;
  std::set<SampleCallback *> sample_callbacks_;
  int cycle_count_ = 0;
  std::atomic<bool> running_ = false;
};
}  // namespace au
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_AUDIO_ENGINE_H_
