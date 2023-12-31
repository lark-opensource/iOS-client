//
//  SwiftKVOCrashProtect
//  LarkCrashSanitizer
//
//  Created by SolaWing on 2020/1/13.
//

#import <Foundation/Foundation.h>
#import <LarkCrashSanitizer/LarkCrashSanitizer-Swift.h>
#import <LKLoadable/Loadable.h>

NS_ASSUME_NONNULL_BEGIN

@interface SwiftKVOCrashProtect : NSObject

@end

@implementation SwiftKVOCrashProtect

@end

LoadableRunloopIdleFuncBegin(LarkCrashSanitizer_SwiftKVO_CRASH)
if ([UIDevice currentDevice].systemVersion.integerValue == 12) {
    [[WMFSwiftKVOCrashWorkaround new] performWorkaround];
}
LoadableRunloopIdleFuncEnd(LarkCrashSanitizer_SwiftKVO_CRASH)

NS_ASSUME_NONNULL_END
