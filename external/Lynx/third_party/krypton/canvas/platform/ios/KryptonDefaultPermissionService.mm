// Copyright 2023 The Lynx Authors. All rights reserved.

#import "KryptonDefaultPermissionService.h"
#import <AVFoundation/AVFoundation.h>
#include "canvas/base/log.h"

@implementation KryptonDefaultPermissionService
- (BOOL)requestGranted:(KryptonPermissionType)permissions {
  if ((permissions & kPermissionCamera) != 0) {
    if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] !=
        AVAuthorizationStatusAuthorized) {
      return NO;
    }
  }
  if ((permissions & kPermissionRecordAudio) != 0) {
    if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio] !=
        AVAuthorizationStatusAuthorized) {
      return NO;
    }
  }
  return YES;
}

- (void)requestPermissions:(KryptonPermissionType)permissions
                 withBlock:(nonnull void (^)(BOOL))callback {
  // for lynx default impl, we do not request audio and video permission together

  if ((permissions & kPermissionCamera) != 0) {
    return [self requestPermissionForMediaType:AVMediaTypeVideo withBlock:callback];
  }

  if ((permissions & kPermissionRecordAudio) != 0) {
    return [self requestPermissionForMediaType:AVMediaTypeAudio withBlock:callback];
  }

  // default return yes
  callback(YES);
}

- (void)requestPermissionForMediaType:(AVMediaType)mediaType
                            withBlock:(nonnull void (^)(BOOL))callback {
  AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
  if (authStatus == AVAuthorizationStatusAuthorized) {
    callback(YES);
  } else if (authStatus == AVAuthorizationStatusNotDetermined) {
    [AVCaptureDevice requestAccessForMediaType:mediaType
                             completionHandler:^(BOOL granted) {
                               callback(YES);
                             }];
  } else {
    callback(NO);
  }
}

@end
