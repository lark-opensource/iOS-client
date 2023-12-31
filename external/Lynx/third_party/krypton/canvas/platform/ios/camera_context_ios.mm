// Copyright 2022 The Lynx Authors. All rights reserved.

#import "camera_context_ios.h"
#include "canvas/background_lock.h"
#include "canvas/base/log.h"
#include "canvas/ios/canvas_app_ios.h"

@interface KryptonDefaultCameraDelegate : NSObject <KryptonCameraDelegate>
- (void)setCameraContext:(lynx::canvas::CameraContextIOS*)context;
@end

@implementation KryptonDefaultCameraDelegate {
  lynx::canvas::CameraContextIOS* _context;
}

- (void)setCameraContext:(lynx::canvas::CameraContextIOS*)context {
  DCHECK(context);
  _context = context;
}

- (void)cameraDidOutputSampleBuffer:(nonnull CMSampleBufferRef)sampleBuffer {
  if (_context) {
    _context->OnCameraOutputSampleBuffer(sampleBuffer);
  } else {
    DCHECK(false);
  }
}

@end

namespace lynx {
namespace canvas {

void CameraContext::DoRequestUserMedia(const std::shared_ptr<CanvasApp>& canvas_app,
                                       std::unique_ptr<CameraOption> option,
                                       const UserMediaCallback& callback) {
  id protocol = @protocol(KryptonCameraService);
  id<KryptonCameraService> service =
      std::static_pointer_cast<CanvasAppIOS>(canvas_app)->GetService(protocol);
  DCHECK([service conformsToProtocol:protocol]);
  if (!service) {
    KRYPTON_LOGE("no camera service registered.");
    callback(std::unique_ptr<VideoContext>(nullptr), "no camera service registered.");
    return;
  }
  auto camera = [service createCamera];
  if (!camera) {
    KRYPTON_LOGE("service createCamera return nil.");
    callback(std::unique_ptr<VideoContext>(nullptr), "service createCamera return nil.");
    return;
  }

  KryptonCameraConfig* config = [[KryptonCameraConfig alloc] init];
  config.resolution = [NSString stringWithUTF8String:option->resolution.c_str()];
  config.faceMode = [NSString stringWithUTF8String:option->face_mode.c_str()];
  NSError* error = [camera requestWithConfig:config];
  if (error) {
    callback(std::unique_ptr<VideoContext>(nullptr), {[[error localizedDescription] UTF8String]});
    return;
  }

  auto delegate = [[KryptonDefaultCameraDelegate alloc] init];
  [camera setDelegate:delegate];
  auto camera_context = std::make_unique<CameraContextIOS>(canvas_app, camera, delegate);
  [delegate setCameraContext:camera_context.get()];
  callback(std::move(camera_context), {});
}

CameraContextIOS::CameraContextIOS(const std::shared_ptr<CanvasApp>& canvas_app,
                                   id<KryptonCamera> camera, id<KryptonCameraDelegate> delegate)
    : CameraContext(canvas_app) {
  internal_context_ = camera;
  internal_delegate_ = delegate;

  KryptonCameraConfig* config = [camera getCameraConfig];
  if (!config) {
    config = [[KryptonCameraConfig alloc] init];
  }
  CGSize size = [config realFrameSize];
  width_ = size.width;
  height_ = size.height;
  auto pixel_buffer = std::make_unique<PixelBuffer>(width_, height_);
  pixel_buffer_ = std::make_shared<shell::LynxActor<TextureSource>>(std::move(pixel_buffer),
                                                                    canvas_app_->gpu_task_runner());
  KRYPTON_CONSTRUCTOR_LOG(CameraContextIOS);
}

CameraContextIOS::~CameraContextIOS() {
  KRYPTON_DESTRUCTOR_LOG(CameraContextIOS);
  if (pixel_buffer_) {
    pixel_buffer_->Act([](auto& impl) {
#ifdef OS_IOS
      BackgroundLock::Instance().WaitForForeground();
#endif
      impl.reset();
    });
  }
}

void CameraContextIOS::Play() { [internal_context_ play]; }

void CameraContextIOS::Pause() { [internal_context_ pause]; }

void CameraContextIOS::OnCameraOutputSampleBuffer(CMSampleBufferRef sample_buffer) {
  std::lock_guard<std::mutex> lock(mutex_);

  CMTime sample_time = CMSampleBufferGetPresentationTimeStamp(sample_buffer);
  time_stamp_ = (double)sample_time.value / sample_time.timescale;
  time_stamp_ *= 1e9;

  if (sample_buffer_) {
    CFRelease(sample_buffer_);
  }
  sample_buffer_ = CMSampleBufferGetImageBuffer(sample_buffer);
  CFRetain(sample_buffer_);
  sample_buffer_updated_ = true;
}

double CameraContextIOS::Timestamp() {
  std::lock_guard<std::mutex> lock(mutex_);
  return time_stamp_;
}

CVPixelBufferRef CameraContextIOS::TakePixelBuffer() {
  if (!sample_buffer_updated_ || !sample_buffer_) {
    return nullptr;
  }

  sample_buffer_updated_ = false;

  CVPixelBufferRef result = sample_buffer_;

  // do not holder by sample_buffer_
  sample_buffer_ = nullptr;

  return result;
}

std::shared_ptr<shell::LynxActor<TextureSource>> CameraContextIOS::GetNewTextureSource() {
  std::lock_guard<std::mutex> lock(mutex_);
  CVPixelBufferRef pixel_buffer = TakePixelBuffer();
  if (pixel_buffer) {
    pixel_buffer_->Act([ts = time_stamp_, pixel_buffer](auto& impl) {
      static_cast<PixelBuffer*>(impl.get())->UpdatePixelBuffer(ts, pixel_buffer);
    });
  }
  return pixel_buffer_;
}
}  // namespace canvas
}  // namespace lynx
