// Copyright 2022 The Lynx Authors. All rights reserved.

#import <AVFoundation/AVFoundation.h>
#import "KryptonPermissionService.h"
#import "LynxKryptonHelper.h"
#include "canvas/ios/canvas_app_ios.h"
#include "canvas/platform/permission_manager.h"

namespace lynx {
namespace canvas {

static void RequestMediaPermission(const std::shared_ptr<CanvasApp>& canvas_app,
                                   KryptonPermissionType permission,
                                   const PermissionManager::ResponseCallback& callback) {
  id protocol = @protocol(KryptonPermissionService);
  id<KryptonPermissionService> service =
      std::static_pointer_cast<CanvasAppIOS>(canvas_app)->GetService(protocol);
  if (service == nil) {
    DCHECK(false);
    KRYPTON_LOGE("custom permission service not set");
    callback(YES);
    return;
  }

  if ([service requestGranted:permission]) {
    callback(YES);
    return;
  }

  PermissionManager::ResponseCallback callback_copy = callback;
  [service requestPermissions:permission
                    withBlock:^(BOOL accepted) {
                      callback_copy(accepted);
                    }];
}

void PermissionManager::RequestCamera(const std::shared_ptr<CanvasApp>& canvas_app,
                                      const ResponseCallback& callback) {
  RequestMediaPermission(canvas_app, kPermissionCamera, callback);
}

void PermissionManager::RequestMicrophone(const std::shared_ptr<CanvasApp>& canvas_app,
                                          const ResponseCallback& callback) {
  RequestMediaPermission(canvas_app, kPermissionRecordAudio, callback);
}

}  // namespace canvas
}  // namespace lynx
