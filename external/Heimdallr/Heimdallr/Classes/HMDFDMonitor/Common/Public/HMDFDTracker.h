//
//  HMDFDTracker.h
//  Pods
//
//  Created by wangyinhui on 2021/6/28.
//

#import "HMDTracker.h"

//upgrade max_fd in app, rang (getdtablesize, 10240), if max_fd <= getdtablesize(), do nothing.
bool hmd_upgrade_max_fd(int max_fd);


@interface HMDFDTracker : HMDTracker

+ (nonnull instancetype)sharedTracker;
- (void)recodeFileDescriptors;
- (void)recodeWarnFDBacktrace:(int)fd withErr:(int)err;
@end

