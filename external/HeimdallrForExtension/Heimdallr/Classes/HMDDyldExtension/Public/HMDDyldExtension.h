//
//  HMDDyldExtension.h
//  Pods
//
//  Created by APM on 2022/9/1.
//

#import "HMDDyldPreloadInfo.h"

typedef NS_ENUM(NSUInteger, HMDDyldExtensionErrorType) {
    HMDDyldExtensionErrorNoData = 1000,
    HMDDyldExtensionErrorDataTypeError,
    HMDDyldExtensionErrorPathError,
    HMDDyldExtensionErrorShortInterval,
};

@interface HMDDyldExtension : NSObject

+ (void)preloadDyldWithGroupID:(nullable NSString *)appGroupID
                   finishBlock:(nullable void (^)(HMDDyldPreloadInfo *_Nullable info))finishBlock;

@end
