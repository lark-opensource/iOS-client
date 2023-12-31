// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef CANVAS_PLATFORM_IOS_CAMERA_CONTEXT_IOS_H_
#define CANVAS_PLATFORM_IOS_CAMERA_CONTEXT_IOS_H_

#include <memory>
#include <mutex>

#include "KryptonCameraService.h"
#include "camera_context.h"
#include "canvas/platform/ios/pixel_buffer.h"
#include "video_context_texture_cache.h"

namespace lynx {
namespace canvas {

class CameraContextIOS : public CameraContext {
 public:
  CameraContextIOS(const std::shared_ptr<CanvasApp>& canvas_app,
                   id<KryptonCamera> camera,
                   id<KryptonCameraDelegate> delegate);

  ~CameraContextIOS();

  void Play() override;

  void Pause() override;

  std::shared_ptr<shell::LynxActor<TextureSource>> GetNewTextureSource()
      override;

  double Timestamp() override;

  void OnCameraOutputSampleBuffer(CMSampleBufferRef sample_buffer);

 private:
  CVPixelBufferRef
  TakePixelBuffer();  // auto retained, need to release after usage

 private:
  id<KryptonCamera> internal_context_;
  id<KryptonCameraDelegate> internal_delegate_;
  std::shared_ptr<shell::LynxActor<TextureSource>> pixel_buffer_{nullptr};
  CVImageBufferRef sample_buffer_{nullptr};
  bool sample_buffer_updated_{false};
  double time_stamp_{0};
  std::mutex mutex_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_PLATFORM_IOS_CAMERA_CONTEXT_IOS_H_
