// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_MEDIA_VIDEO_ELEMENT_H_
#define CANVAS_MEDIA_VIDEO_ELEMENT_H_

#include "canvas/canvas_image_source.h"
#include "canvas/event_target.h"
#include "canvas/instance_guard.h"
#include "jsbridge/bindings/canvas/napi_video_load_options.h"
#include "jsbridge/napi/base.h"
#include "media_stream.h"
#include "video_context.h"

namespace lynx {
namespace canvas {
class VideoPlayerContext;

using piper::BridgeBase;
using piper::ImplBase;

constexpr char kVideoStateLoading[] = "loading";
constexpr char kVideoStateError[] = "error";
constexpr char kVideoStateLoaded[] = "load";
constexpr char kVideoStatePaused[] = "paused";
constexpr char kVideoStatePlaying[] = "playing";
constexpr char kVideoStateDisposed[] = "disposed";

constexpr unsigned short HAVE_NOTHING = 0;
constexpr unsigned short HAVE_METADATA = 1;
constexpr unsigned short HAVE_CURRENT_DATA = 2;
constexpr unsigned short HAVE_FUTURE_DATA = 3;
constexpr unsigned short HAVE_ENOUGH_DATA = 4;

class VideoElement : public CanvasImageSource, public EventTarget {
 public:
  enum Type { NotReady = 0, VideoPlayer = 1, Camera = 2 };

  static std::unique_ptr<VideoElement> Create() {
    return std::unique_ptr<VideoElement>(new VideoElement());
  }

  static std::unique_ptr<VideoElement> Create(
      std::unique_ptr<VideoLoadOptions> load_options);

  VideoElement();

  VideoElement(const VideoElement&) = delete;

  ~VideoElement() override;

  void SetSrc(const std::string& src);
  std::string GetSrc() const;

  void SetSrcObject(MediaStream* src_object);
  MediaStream* GetSrcObject();

  void SetCurrentTime(double currentTime);
  double GetCurrentTime();

  void SetMuted(bool mute);
  bool GetMuted();

  void SetLoop(bool loop);
  bool GetLoop();

  void SetAutoplay(bool autoplay);
  bool GetAutoplay();

  void SetVolume(double volume);
  double GetVolume();

  double GetDuration();

  unsigned short GetReadyState();

  bool GetPaused();

  void Play();

  void Pause();

  void Dispose();

  uint32_t GetWidth() override;

  uint32_t GetHeight() override;

  uint32_t GetVideoWidth();

  uint32_t GetVideoHeight();

  std::string GetState();

  double GetTimestamp();

  void PaintTo(CanvasElement* canvas, double dx = 0, double dy = 0,
               double sx = 0, double sy = 0);
  void PaintTo(CanvasElement* canvas, double dx, double dy, double sx,
               double sy, double sw);
  void PaintTo(CanvasElement* canvas, double dx, double dy, double sx,
               double sy, double sw, double sh);

  bool IsVideoElement() const override { return true; };

#ifndef ENABLE_RENDERKIT_CANVAS
  std::shared_ptr<shell::LynxActor<TextureSource>> GetTextureSource() override;
#endif

  void OnWrapped() override;

  void HoldObject();
  void ReleaseObject();

 private:
  void RegisterStateListener();
  void NotifyState(VideoContext::State state);
  void InvokeStateCallback(const char* func_name, const char* event_name);
  void ParsePlayerLoadOptions(std::unique_ptr<VideoLoadOptions> options);

  Type type_{NotReady};
  std::string src_;
  MediaStream* src_object_{nullptr};
  Napi::ObjectReference src_object_ref_;
  std::shared_ptr<VideoContext> video_context_{nullptr};
  std::shared_ptr<InstanceGuard<VideoElement>> instance_guard_{nullptr};

  bool muted_{false};
  double volume_{1};
  bool loop_{false};
  bool autoplay_{false};
  std::string id_;
  VideoContext::PlayerLoadOptions player_load_options_;

  std::string state_{kVideoStateLoading};
  unsigned short ready_state_{HAVE_NOTHING};
};

}  // namespace canvas
}  // namespace lynx
#endif  // CANVAS_MEDIA_VIDEO_ELEMENT_H_
