//
//  IESFalconDebugLogger.m
//  BDWebKit-Pods-Aweme
//
//  Created by 陈煜钏 on 2020/3/3.
//

#import "IESFalconDebugLogger.h"

@interface IESFalconBaseLogManager : NSObject
+ (BOOL)registerLogContext:(NSInteger)context title:(NSString *)title;
+ (void)logWithContext:(NSInteger)context message:(NSString *)message;
@end

@implementation IESFalconBaseLogManager

+ (id)forwardingTargetForSelector:(SEL)aSelector
{
    return NSClassFromString(@"BDBaseLogManager");
}

@end

void IESFalconDebugLogWrapper (NSString *message) {
    static BOOL IESFalconDebugLogEnabled = NO;
    static NSInteger BDFalconLogContext = 1;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        IESFalconDebugLogEnabled = !!NSClassFromString(@"BDBaseLogManager");
        if (IESFalconDebugLogEnabled) {
            [IESFalconBaseLogManager registerLogContext:BDFalconLogContext title:@"Falcon"];
        }
    });
    if (IESFalconDebugLogEnabled) {
        [IESFalconBaseLogManager logWithContext:BDFalconLogContext message:message];
    }
}
