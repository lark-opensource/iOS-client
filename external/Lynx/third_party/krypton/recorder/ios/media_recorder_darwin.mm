//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "media_recorder_darwin.h"
#include <memory>
#include "canvas/base/scoped_cftypedref.h"
#include "canvas/gpu/gl/gl_api.h"
#include "canvas/gpu/gl_surface.h"
#include "canvas/ios/canvas_app_ios.h"
#include "canvas/ios/gl_surface_cv_pixel_buffer.h"
#include "config/config.h"
#if ENABLE_KRYPTON_AURUM
#include "aurum/audio_engine.h"
#include "aurum/aurum.h"
#endif

namespace lynx {
namespace canvas {

using AudioSamplerCallback = std::function<void(void* buffer, int samples)>;

#if ENABLE_KRYPTON_AURUM
class AudioSamplerImpl : au::SampleCallback {
 public:
  AudioSamplerImpl(std::weak_ptr<au::AudioEngine> weak_engine, AudioSamplerCallback callback)
      : weak_engine_(weak_engine), callback_(callback) {}

  ~AudioSamplerImpl() { Stop(); }

  void OnSample(const short* data, int length, int samples) override {
    if (!callback_) {
      return;
    }

    int32_t* ptr = buffer_[next_sample_++ & 7];
    if (length) {
      memcpy(ptr, data, length << 2);
    }
    if (samples > length) {
      memset(ptr + length, 0, (samples - length) << 2);
    }

    callback_(ptr, samples);
  }

  void Start() {
    auto engine = weak_engine_.lock();
    if (engine) {
      engine->AddSampleListener(this);
    }
  }

  void Stop() {
    auto engine = weak_engine_.lock();
    if (engine) {
      engine->RemoveSampleListener(this);
    }
  }

 private:
  std::weak_ptr<au::AudioEngine> weak_engine_;
  AudioSamplerCallback callback_;
  int32_t buffer_[8][512];
  int next_sample_ = 0;
};
#else
class AudioSamplerImpl {
  void Start(){};
  void Stop(){};
};
#endif  // #if ENABLE_KRYPTON_AURUM

MediaRecorder* MediaRecorder::CreateInstance(const Config& config, SurfaceCallback callback) {
  return new MediaRecorderDarwin(config, callback);
}

MediaRecorderDarwin::MediaRecorderDarwin(const Config& config, SurfaceCallback callback)
    : MediaRecorder(config, callback) {}

MediaRecorderDarwin::~MediaRecorderDarwin() {
  instance_guard_ = nullptr;
  [recorder_impl_ destroy:config_.delete_file_on_destroy];
  RemoveSurface();
  if (audio_sampler_) {
    audio_sampler_->Stop();
    delete audio_sampler_;
  }
}

bool MediaRecorderDarwin::InitPlatformImpl() {
  DCHECK(canvas_app_);
  id protocol = @protocol(KryptonMediaRecorderService);
  id<KryptonMediaRecorderService> service =
      std::static_pointer_cast<CanvasAppIOS>(canvas_app_)->GetService(protocol);
  DCHECK([service conformsToProtocol:protocol]);
  if (!service) {
    KRYPTON_LOGE("no media recorder service registered.");
    return false;
  }
  recorder_impl_ = [service createMediaRecorder];
  if (recorder_impl_ == nil) {
    KRYPTON_LOGE("media recorder service create result null.");
    return false;
  }

  [recorder_impl_ configVideoWithMimeType:[NSString stringWithUTF8String:config_.mime_type.c_str()]
                                 duration:config_.duration
                                    width:config_.video.width
                                   height:config_.video.height
                                      bps:config_.video.bps
                                      fps:config_.video.fps];
  AutoInitAudio();
  return true;
}

void MediaRecorderDarwin::OnPostStartWithPixelBuffer(BOOL result) {
  RunOnJSThread([result](auto& impl) {
    MediaRecorderDarwin* recorder = reinterpret_cast<MediaRecorderDarwin*>(&impl);
    recorder->PostStartWithPixelBuffer(result);
  });
}

bool MediaRecorderDarwin::PostStartWithPixelBuffer(BOOL result) {
  if (!result) {
    OnRecordStartWithResult(false, "platform start false return");
    return false;
  }

  auto surface = std::make_unique<GLSurfaceCVPixelBuffer>(config_.video.width, config_.video.height,
                                                          (id<DownStreamListener>)recorder_impl_);
  if (surface == nullptr) {
    OnRecordStartWithResult(false, "create surface null");
    return false;
  }

  if (!AddSurface(std::move(surface))) {
    OnRecordStartWithResult(false, "add surface error");
    return false;
  }

  if (audio_sampler_) {
    audio_sampler_->Start();
  }

  OnRecordStartWithResult(true, nullptr);
  return true;
}

bool MediaRecorderDarwin::DoStart() {
  if (recorder_impl_ == nil) {
    if (!InitPlatformImpl()) {
      OnRecordStartWithResult(false, "init platform impl failed");
      return false;
    }
  }

  auto weak_guard = std::weak_ptr<InstanceGuard<MediaRecorder>>(instance_guard_);
  [recorder_impl_
      startRecordWithStartCallback:^(BOOL result) {
        auto shared_guard = weak_guard.lock();
        if (shared_guard) {
          reinterpret_cast<MediaRecorderDarwin*>(shared_guard->Get())
              ->OnPostStartWithPixelBuffer(result);
        }
      }
      endCallback:^(id<KryptonMediaRecorderData> _Nullable result, NSString* _Nullable err) {
        auto shared_guard = weak_guard.lock();
        if (shared_guard) {
          if (result != nil) {
            lynx::canvas::MediaRecorder::DataInfo ret(std::string([result.path UTF8String]),
                                                      result.duration, result.size);
            shared_guard->Get()->OnRecordStopWithData(ret);
          } else {
            shared_guard->Get()->OnRecordStopWithError([err UTF8String]);
          }
        }
      }];
  return true;
}

bool MediaRecorderDarwin::DoStop() {
  if (recorder_impl_ == nil) {
    return false;
  }

  [recorder_impl_ stopRecord];
  RemoveSurface();
  if (audio_sampler_) {
    audio_sampler_->Stop();
  }
  return true;
}

bool MediaRecorderDarwin::DoPause() {
  if (recorder_impl_ == nil) {
    return false;
  }
  [recorder_impl_ pauseRecord];
  if (audio_sampler_) {
    audio_sampler_->Stop();
  }
  return true;
}

bool MediaRecorderDarwin::DoResume() {
  if (recorder_impl_ == nil) {
    return false;
  }
  [recorder_impl_ resumeRecord];
  if (audio_sampler_) {
    audio_sampler_->Start();
  }
  return true;
}

void MediaRecorderDarwin::AutoInitAudio() {
  audio_sampler_ = nullptr;
#if ENABLE_KRYPTON_AURUM
  auto audio_engine = config_.audio.engine.lock();
  if (audio_engine && audio_engine->IsRunning()) {
    __weak id<KryptonMediaRecorder> weak_impl = recorder_impl_;
    audio_sampler_ = new AudioSamplerImpl(audio_engine, [weak_impl](void* buffer, int samples) {
      [weak_impl onAudioSample:buffer length:samples];
    });
    [recorder_impl_ configAudioWithChanels:config_.audio.chanels
                                       bps:config_.audio.bps
                                sampleRate:config_.audio.sample_rate];
  }
#endif
}

bool MediaRecorderDarwin::DoGetCurrentTime(int64_t& time) {
  if (recorder_impl_ == nil) {
    return false;
  }

  time = [recorder_impl_ lastPresentationTime];
  return true;
}

bool MediaRecorderDarwin::DoClip() {
  if (recorder_impl_ == nil) {
    return false;
  }

  std::vector<uint64_t> time_array;

  bool merge_result = MergeClipTimeRanges([&time_array](uint64_t start, uint64_t end) {
    time_array.emplace_back(start);
    time_array.emplace_back(end);
  });

  if (!merge_result || time_array.empty()) {
    return false;
  }

  size_t count = time_array.size();
  NSMutableArray* array = [NSMutableArray arrayWithCapacity:count];
  for (size_t i = 0; i < count; ++i) {
    array[i] = [NSNumber numberWithUnsignedLongLong:time_array[i]];
  }

  auto weak_guard = std::weak_ptr<InstanceGuard<MediaRecorder>>(instance_guard_);

  [recorder_impl_
      clipWithTimeRanges:array
          andEndCallback:^(id<KryptonMediaRecorderData> _Nullable result, NSString* _Nullable err) {
            auto shared_guard = weak_guard.lock();
            if (shared_guard) {
              if (result != nil) {
                lynx::canvas::MediaRecorder::DataInfo ret(std::string([result.path UTF8String]),
                                                          result.duration, result.size);
                shared_guard->Get()->OnClipStopWithData(ret);
              } else {
                shared_guard->Get()->OnClipStopWithError([err UTF8String]);
              }
            }
          }];
  return true;
}

}  // namespace canvas
}  // namespace lynx
