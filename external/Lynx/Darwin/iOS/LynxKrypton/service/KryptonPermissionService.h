//  Copyright 2023 The Lynx Authors. All rights reserved.

#import "KryptonService.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, KryptonPermissionType) {
  kPermissionCamera = 1 << 0,
  kPermissionRecordAudio = 1 << 1,
};

#pragma mark - KryptonPermissionService

@protocol KryptonPermissionService <KryptonService>

- (void)requestPermissions:(KryptonPermissionType)permissions
                 withBlock:(nonnull void (^)(BOOL))callback;
- (BOOL)requestGranted:(KryptonPermissionType)permissions;

@end

NS_ASSUME_NONNULL_END
