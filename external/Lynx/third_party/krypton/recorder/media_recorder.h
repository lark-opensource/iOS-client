//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_CANVAS_MEDIA_RECORDER_H_
#define LYNX_CANVAS_MEDIA_RECORDER_H_

#include <stdint.h>

#include <string>
#include <vector>

#include "canvas/canvas_app.h"
#include "canvas/event_target.h"
#include "canvas/instance_guard.h"
#include "canvas/surface/surface.h"
#include "jsbridge/bindings/canvas/napi_media_recorder_config.h"
#include "jsbridge/napi/base.h"

namespace lynx {
namespace canvas {
namespace au {
class AudioEngine;
}

class CanvasElement;
class AudioSampler;
using piper::BridgeBase;
using piper::ImplBase;

class MediaRecorder : public EventTarget {
 public:
  using SurfaceCallback =
      std::function<bool(uintptr_t, std::unique_ptr<Surface>)>;
  struct Config {
    std::string mime_type;
    uint32_t duration;
    bool delete_file_on_destroy{true};
    struct Video {
      uint32_t width, height, fps, bps;
    } video;
    struct Audio {
      std::weak_ptr<au::AudioEngine> engine;
      uint32_t bps, chanels, sample_rate;
    } audio;
    bool auto_pause_and_resume{true};
    Config(MediaRecorderConfig&, uint32_t src_width, uint32_t src_height);
    void SetAudioConfig(std::weak_ptr<au::AudioEngine> weak_engine);
    void ResetAudioConfig();
  };
  struct DataInfo {
    std::string path;
    double duration;
    uint64_t size;
    DataInfo(const std::string& p, double d, uint64_t s)
        : path(p), duration(d), size(s) {}
  };

  static MediaRecorder* CreateInstance(const Config&, SurfaceCallback);
  MediaRecorder(const Config&, SurfaceCallback);
  virtual ~MediaRecorder();

  // called from js thread
  bool Start();
  bool Stop();
  bool Pause();
  bool Resume();
  bool Clip();
  int32_t AddClipTimeRange(int32_t before, int32_t after);
  std::string GetMimeType() { return config_.mime_type; }
  uint32_t GetVideoBitsPerSecond() { return config_.video.bps; }
  uint32_t GetAudioBitsPerSecond() { return config_.audio.bps; }
  uint32_t GetVideoWidth() { return config_.video.width; }
  uint32_t GetVideoHeight() { return config_.video.height; }
  bool IsTypeSupported(const std::string& type);
  std::string GetState();

  // may be called in any thread
  void OnRecordStartWithResult(bool result, const char* error);
  void OnRecordStopWithData(const DataInfo&);
  void OnRecordStopWithError(const char* error);
  void OnClipStopWithData(const DataInfo&);
  void OnClipStopWithError(const char* error);
  void OnWrapped() override;
  void OnAutoPause();
  void OnAutoResume();

 protected:
  enum State {
    kInitialized,
    kRunning,
    kPaused,
    kAutoPaused,
    kStopping,
    kStopped,
    kError,
  };

  enum EventType {
    kEventError = 0,
    kEventRecordStart,
    kEventRecordStop,
    kEventRecordPause,
    kEventRecordResume,
    kEventClipStart,
    kEventClipEnd,
  };

  enum ErrorType {
    kErrorUnknown = 0,
    kErrorRecordStart,
    kErrorRecordStop,
    kErrorRecordPause,
    kErrorRecordResume,
    kErrorAddClipTimeRange,
    kErrorClip,
  };

  virtual bool DoStart() = 0;
  virtual bool DoStop() = 0;
  virtual bool DoPause() = 0;
  virtual bool DoResume() = 0;
  virtual bool DoGetCurrentTime(int64_t& time) = 0;
  virtual bool DoClip() = 0;

  bool AddSurface(std::unique_ptr<Surface> surface);
  void RemoveSurface();
  bool MergeClipTimeRanges(
      std::function<void(uint64_t, uint64_t)> range_callback);
  void RunOnJSThread(std::function<void(MediaRecorder&)> func);

 private:
  void InvokeCallbackWithError(ErrorType err_type, const std::string& err_msg,
                               EventType event = kEventError);
  void InvokeCallbackWithData(EventType event_type, const DataInfo& data);
  void InvokeCallback(EventType event_type);
  void RealInvokeCallback(EventType event_type, Napi::Value value);
  void PostStatusChanged();
  const char* StatusString();
  void HoldObject();
  void ReleaseObject();
  void TryToInitAudio();
  void TryToDestroyAudio();
  bool CheckOnJSThread() const;
  static const char* EventTypeToString(EventType type);
  static const char* ErrorTypeToString(ErrorType type);

 protected:
  const std::string id_;
  Config config_;
  State state_;
  SurfaceCallback surface_callback_;
  std::shared_ptr<CanvasApp> canvas_app_{nullptr};
  std::shared_ptr<InstanceGuard<MediaRecorder>> instance_guard_{nullptr};
  uintptr_t surface_key_{0};
  std::vector<std::pair<uint64_t, uint64_t>> clip_time_ranges_;
  std::shared_ptr<AppShowStatusObserver> app_show_status_observer_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_CANVAS_MEDIA_RECORDER_H_
