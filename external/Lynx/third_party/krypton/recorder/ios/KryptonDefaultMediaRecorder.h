// Copyright 2022 The Lynx Authors. All rights reserved.

#import "KryptonMediaRecorderService.h"

NS_ASSUME_NONNULL_BEGIN

@interface KryptonDefaultMediaRecorder : NSObject <KryptonMediaRecorder>
- (void)configRecordFileDirectory:(NSString *)directory;
@end

@interface KryptonDefaultMediaRecorderService : NSObject <KryptonMediaRecorderService>
- (void)setTemporaryDirectory:(NSString *)directory;
@end

NS_ASSUME_NONNULL_END
