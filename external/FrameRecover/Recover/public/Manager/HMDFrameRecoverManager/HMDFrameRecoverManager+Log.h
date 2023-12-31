//
//  HMDFrameRecoverManager+Log.h
//  Pods
//
//  Created by bytedance on 2022/11/25.
//

#import "HMDFrameRecoverManager.h"

typedef enum : NSUInteger {
    HMDFrameRecoverLogLevelDebug,
    HMDFrameRecoverLogLevelInfo,
    HMDFrameRecoverLogLevelWarn,
    HMDFrameRecoverLogLevelError,
    HMDFrameRecoverLogLevelFatal,
    
    HMDFrameRecoverLogLevelImpossible
} HMDFrameRecoverLogLevel;

@interface HMDFrameRecoverManager (Log)

@property(class, atomic) HMDFrameRecoverLogLevel logLevel;

@end
