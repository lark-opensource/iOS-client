// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_PLATFORM_IOS_VIDEO_PLAYER_CONTEXT_IOS_H_
#define CANVAS_PLATFORM_IOS_VIDEO_PLAYER_CONTEXT_IOS_H_

#include "KryptonVideoPlayerService.h"
#include "canvas/platform/ios/pixel_buffer.h"
#include "video_context_texture_cache.h"
#include "video_player_context.h"

namespace lynx {
namespace canvas {

class VideoPlayerContextIOS : public VideoPlayerContext {
 public:
  VideoPlayerContextIOS(const std::shared_ptr<CanvasApp>& canvas_app,
                        PlayerLoadOptions load_options);
  ~VideoPlayerContextIOS() override;

  /// VideoContext interface Impl
  void Play() override;

  void Pause() override;

  std::shared_ptr<shell::LynxActor<TextureSource>> GetNewTextureSource()
      override;

  /// VideoPlayerContext interface Impl
  void Load(const std::string& url) override;

  double GetCurrentTime() override;

  void SetCurrentTime(double time) override;

  void SetVolume(double volume) override;

  void SetLoop(bool loop) override;

  bool GetLoop() override;

  double GetDuration() override;

  void onVideoStatusChanged(KryptonVideoState status);

 private:
  id<KryptonVideoPlayer> internal_context_;
  id<KryptonVideoPlayerDelegate> internal_delegate_;
  bool internal_to_play_{false};
  double duration_{NAN};

  std::shared_ptr<InstanceGuard<VideoPlayerContext>> instance_guard_;
  std::shared_ptr<shell::LynxActor<TextureSource>> pixel_buffer_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_PLATFORM_IOS_VIDEO_PLAYER_CONTEXT_IOS_H_
