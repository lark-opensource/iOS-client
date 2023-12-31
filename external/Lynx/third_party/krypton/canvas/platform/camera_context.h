//  Copyright 2022 The Lynx Authors. All rights reserved.

#include <functional>
#include <optional>

#include "base/base_export.h"
#include "canvas/media/video_context.h"
#include "canvas/platform/camera_option.h"

#ifndef CANVAS_PLATFORM_CAMERA_CONTEXT_H_
#define CANVAS_PLATFORM_CAMERA_CONTEXT_H_

namespace lynx {
namespace canvas {
class CameraContext : public VideoContext {
 public:
  CameraContext(const std::shared_ptr<CanvasApp>& canvas_app);
  virtual ~CameraContext() = default;

  using UserMediaCallback = std::function<void(std::unique_ptr<VideoContext>,
                                               std::optional<std::string>)>;

  static void RequestUserMedia(const std::shared_ptr<CanvasApp>& canvas_app,
                               const Napi::Object& option,
                               const UserMediaCallback& callback);

  BASE_EXPORT static void DoRequestUserMedia(
      const std::shared_ptr<CanvasApp>& canvas_app,
      std::unique_ptr<CameraOption> option, const UserMediaCallback& callback);
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_PLATFORM_CAMERA_CONTEXT_H_
