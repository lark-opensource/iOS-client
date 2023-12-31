//
//  IWKDelegateCompletionProbe.m
//  BDWebCore
//
//  Created by li keliang on 2020/1/3.
//

#import "IWKDelegateCompletionProbe.h"
#import "IWKUtils.h"

#import <BDMonitorProtocol/BDMonitorProtocol.h>
#import <objc/runtime.h>

@implementation IWKDelegateCompletionProbe
static BOOL kShouldCatchFatalError = NO;
+ (void)setCatchFatalError:(BOOL)catchFatalError
{
    kShouldCatchFatalError = catchFatalError;
}

+ (BOOL)shouldCatchFatalError
{
    return kShouldCatchFatalError;
}

+ (instancetype)probeWithSelector:(SEL)selector
{
    IWKDelegateCompletionProbe *probe = [IWKDelegateCompletionProbe new];
    probe.probeName = NSStringFromSelector(selector);
    return probe;
}

#pragma mark -

- (void)callOnce:(__nullable id)result
{
    if ([objc_getAssociatedObject(self, _cmd) boolValue]) {
        NSString *errorMsg = [NSString stringWithFormat:@"%@ completion handler pass to -[%@] was called more than once.", NSStringFromClass([self.caller class]), self.probeName];
        [IWKDelegateCompletionProbe p_monitorLog:errorMsg];
    } else {
        objc_setAssociatedObject(self, _cmd, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    if (self.completionHandler) {
        NSUInteger numberOfArguments = IWK_blockMethodSignature(self.completionHandler).numberOfArguments;
        if (numberOfArguments == 1) {
            ((void(^)(void))self.completionHandler)();
        } else if (numberOfArguments == 2) {
            ((void(^)(id))self.completionHandler)(result);
        }
    }
    
    if (self.class.shouldCatchFatalError) {
        self.completionHandler = nil;
    }
}

- (void)dealloc
{
    if (self.completionHandler) {
        NSString *errorMsg = [NSString stringWithFormat:@"%@ completion handler pass to -[%@] was not called.", NSStringFromClass([self.caller class]), self.probeName];
        [IWKDelegateCompletionProbe p_monitorLog:errorMsg];
        
        if (self.class.shouldCatchFatalError) {
            [self callOnce:nil];
        }
    }
}

+ (void)p_monitorLog:(NSString *)errorMsg
{
#if DEBUG
        NSLog(@"[ERROR] %@", errorMsg);
#endif
    [BDMonitorProtocol hmdTrackService:@"IWKDelegateCompletionProbe"
                                metric:@{}
                              category:@{
                                  @"status" : @"1",
                                  @"errorDesc" : errorMsg ?: @""
                              } extra:@{}];
}

@end
