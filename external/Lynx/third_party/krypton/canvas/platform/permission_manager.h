//  Copyright 2022 The Lynx Authors. All rights reserved.

#include <functional>
#include <optional>

#include "canvas/canvas_app.h"

#ifndef CANVAS_PLATFORM_PERMISSION_MANAGER_H_
#define CANVAS_PLATFORM_PERMISSION_MANAGER_H_

namespace lynx {
namespace canvas {
class PermissionManager {
 public:
  using ResponseCallback = std::function<void(bool accepted)>;
  static void RequestCamera(const std::shared_ptr<CanvasApp>& canvas_app,
                            const ResponseCallback& callback);
  static void RequestMicrophone(const std::shared_ptr<CanvasApp>& canvas_app,
                                const ResponseCallback& callback);
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_PLATFORM_PERMISSION_MANAGER_H_
