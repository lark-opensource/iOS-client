// Copyright 2021 The Lynx Authors. All rights reserved.

#include "video_player_context_ios.h"
#import "KryptonDefaultVideoPlayer.h"
#include "canvas/background_lock.h"
#include "canvas/base/log.h"
#include "canvas/gpu/gl/gl_api.h"
#include "canvas/gpu/gl/scoped_gl_reset_restore.h"
#include "canvas/ios/canvas_app_ios.h"

@interface KryptonDefaultVideoPlayerDelegate : NSObject <KryptonVideoPlayerDelegate>
- (instancetype)initWithVideoPlayerContext:(lynx::canvas::VideoPlayerContextIOS*)context;
@end

@implementation KryptonDefaultVideoPlayerDelegate {
  lynx::canvas::VideoPlayerContextIOS* _context;
}

- (instancetype)initWithVideoPlayerContext:(lynx::canvas::VideoPlayerContextIOS*)context {
  self = [self init];
  if (self) {
    DCHECK(context);
    _context = context;
  }
  return self;
}

- (void)onVideoStatusChanged:(KryptonVideoState)status {
  _context->onVideoStatusChanged(status);
}
@end

namespace lynx {
namespace canvas {

std::unique_ptr<VideoPlayerContext> VideoPlayerContext::CreatePlayer(
    const std::shared_ptr<CanvasApp>& canvas_app, PlayerLoadOptions load_options) {
  return std::make_unique<VideoPlayerContextIOS>(std::move(canvas_app), std::move(load_options));
}

VideoPlayerContextIOS::VideoPlayerContextIOS(const std::shared_ptr<CanvasApp>& canvas_app,
                                             PlayerLoadOptions load_options)
    : VideoPlayerContext(canvas_app) {
  id<KryptonVideoPlayerService> service = nil;
  if (load_options.use_custom_player) {
    id protocol = @protocol(KryptonVideoPlayerService);
    service = std::static_pointer_cast<CanvasAppIOS>(canvas_app)->GetService(protocol);
    if (service) {
      DCHECK([service conformsToProtocol:protocol]);
      KRYPTON_LOGE("use custom video player service");
    } else {
      KRYPTON_LOGE("custom video player service not set, fallback to default");
    }
  }

  if (!service) {
    service = [[KryptonDefaultVideoPlayerService alloc] init];
  }
  auto player = [service createVideoPlayer];
  if (!player) {
    KRYPTON_LOGE("service createVideoPlayer return nil.");
    return;
  }

  internal_delegate_ = [[KryptonDefaultVideoPlayerDelegate alloc] initWithVideoPlayerContext:this];
  [player setDelegate:internal_delegate_];

  internal_context_ = player;
  instance_guard_ = std::make_shared<InstanceGuard<VideoPlayerContext>>(this);
  KRYPTON_CONSTRUCTOR_LOG(VideoPlayerContextIOS);
  KRYPTON_LOGI("VideoPlayerContextIOS ")
      << this << " internalContext " << (__bridge void*)internal_context_;
}

VideoPlayerContextIOS::~VideoPlayerContextIOS() {
  [internal_context_ dispose];
  KRYPTON_DESTRUCTOR_LOG(VideoPlayerContextIOS);

  if (pixel_buffer_) {
    pixel_buffer_->Act([](auto& impl) {
#ifdef OS_IOS
      BackgroundLock::Instance().WaitForForeground();
#endif
      impl.reset();
    });
  }
}

//
// id<KryptonVideoPlayerProtocol> CanvasAppIOS::CreatePlayer(id<KryptonVideoPlayerDelegate>
// delegate,
//                                                          bool use_custom_player) {
//  if (use_custom_player) {
//    id<KryptonVideoPlayerService> service = [app_
//    getService:@protocol(KryptonVideoPlayerService)]; if (service != nil) {
//      KRYPTON_LOGI("krypton use custom video player service");
//      return [service createPlayerWithDelegate:delegate];
//    } else {
//      KRYPTON_LOGI(
//          "krypton use default video player service, as custom video player service is not set");
//    }
//  } else {
//    KRYPTON_LOGI("krypton use default video player service");
//  }
//
//  return [[KryptonDefaultVideoPlayerService new] createPlayerWithDelegate:delegate];
//}

void VideoPlayerContextIOS::Play() {
  internal_to_play_ = true;
  [internal_context_ play];
}

void VideoPlayerContextIOS::Pause() {
  internal_to_play_ = false;
  [internal_context_ pause];
}

std::shared_ptr<shell::LynxActor<TextureSource>> VideoPlayerContextIOS::GetNewTextureSource() {
  double ts = [internal_context_ getCurrentTime];
  CVPixelBufferRef pixel_buffer = [internal_context_ copyPixelBuffer];
  if (!pixel_buffer_) {
    return nullptr;
  }
  pixel_buffer_->Act([ts, pixel_buffer](auto& impl) {
    static_cast<PixelBuffer*>(impl.get())->UpdatePixelBuffer(ts, pixel_buffer);
  });
  return pixel_buffer_;
}

void VideoPlayerContextIOS::onVideoStatusChanged(KryptonVideoState status) {
  switch (status) {
    case kVideoStateCanPlay: {
      width_ = [internal_context_ getVideoWidth];
      height_ = [internal_context_ getVideoHeight];

      auto pixel_buffer = std::make_unique<PixelBuffer>(width_, height_);
      pixel_buffer_ = std::make_shared<shell::LynxActor<TextureSource>>(
          std::move(pixel_buffer), canvas_app_->gpu_task_runner());

      auto volume = GetMuted() ? 0 : VideoPlayerContext::GetVolume();
      [internal_context_ setVolume:volume];
      [internal_context_ setLooping:VideoPlayerContext::GetLoop()];

      duration_ = [internal_context_ getDuration];

      /// NotifyState calls JS callback synchronously, if the developer triggers the dispose method
      /// on VideoElement in the JS callback, `this` will be released synchronously, so we need a
      /// weak instance guard to identify whether `this` is disposed
      std::weak_ptr<InstanceGuard<VideoPlayerContext>> weak_guard = instance_guard_;

      this->NotifyState(State::kCanPlay);
      if (weak_guard.lock() && (internal_to_play_ || GetAutoplay())) {
        Play();
      }
    } break;
    case kVideoStateEnd: {
      if (!GetLoop()) {
        internal_to_play_ = false;
      }
      this->NotifyState(State::kEnd);
    } break;
    case kVideoStateError:
      this->NotifyState(State::kError);
      break;
    case kVideoStateCanDraw:
      this->NotifyState(State::kCanDraw);
      break;
    case kVideoStateSeekEnd:
      this->NotifyState(State::kSeekEnd);
      break;
    case kVideoStateStartPlay:
      this->NotifyState(State::kStartPlay);
      break;
    case kVideoStatePaused:
      this->NotifyState(State::kPaused);
      break;
    default:
      break;
  }
}

void VideoPlayerContextIOS::Load(const std::string& url) {
  if (url.empty()) {
    this->NotifyState(VideoPlayerContext::State::kEnd);
    return;
  }

  NSString* urlStr = [NSString stringWithCString:url.c_str() encoding:NSUTF8StringEncoding];
  [internal_context_ setSource:urlStr];
}

double VideoPlayerContextIOS::GetCurrentTime() { return [internal_context_ getCurrentTime]; }

void VideoPlayerContextIOS::SetCurrentTime(double time) { [internal_context_ setCurrentTime:time]; }

void VideoPlayerContextIOS::SetVolume(double volume) {
  VideoPlayerContext::SetVolume(volume);

  [internal_context_ setVolume:volume];
}

void VideoPlayerContextIOS::SetLoop(bool loop) {
  VideoPlayerContext::SetLoop(loop);

  [internal_context_ setLooping:loop];
}

bool VideoPlayerContextIOS::GetLoop() { return [internal_context_ getLooping]; }

double VideoPlayerContextIOS::GetDuration() { return duration_; }

}  // namespace canvas
}  // namespace lynx
