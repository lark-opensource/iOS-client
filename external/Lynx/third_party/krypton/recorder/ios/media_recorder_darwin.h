//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_CANVAS_MEDIA_RECORDER_DARWIN_H_
#define LYNX_CANVAS_MEDIA_RECORDER_DARWIN_H_

#import "KryptonMediaRecorderService.h"
#include "recorder/media_recorder.h"

namespace lynx {
namespace canvas {

class AudioSamplerImpl;

class MediaRecorderDarwin : public MediaRecorder {
 public:
  MediaRecorderDarwin(const Config&, SurfaceCallback);
  ~MediaRecorderDarwin();

  bool GetAudioTimeOffset(uint64_t& result);

 private:
  bool DoStart() override;
  bool DoStop() override;
  bool DoPause() override;
  bool DoResume() override;
  bool DoGetCurrentTime(int64_t& time) override;
  bool DoClip() override;
  void AutoInitAudio();
  bool InitPlatformImpl();
  bool PostStartWithPixelBuffer(BOOL result);
  void OnPostStartWithPixelBuffer(BOOL result);

 private:
  id<KryptonMediaRecorder> recorder_impl_;
  AudioSamplerImpl* audio_sampler_{nullptr};
};
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_CANVAS_MEDIA_RECORDER_DARWIN_H_
