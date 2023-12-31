//
//  NSURLSessionTaskSwizzle.m
//  LarkApp
//
//  Created by SolaWing on 2019/9/6.
//

#import "NSURLSessionTaskSwizzle.h"
#import <objc/runtime.h>
#import <LKLoadable/Loadable.h>
#import <UIKit/UIKit.h>

#define Log(...)
// #define Log(...) NSLog( __VA_ARGS__ )

@implementation NSURLSessionTaskSwizzle

#if !TARGET_IPHONE_SIMULATOR

LoadableRunloopIdleFuncBegin(LarkCrashSanitizer_CFNetworkBug)
// https://bytedance.feishu.cn/space/doc/doccn9CaGoUAw5E4sGLr1jsSKSb
// https://forums.developer.apple.com/thread/110493
// 苹果提前forget bug, 导致load orig crash, 只在iOS 12出现
// 现在通过延迟cancel避免时序提前forget的问题，但可能导致收到不应该收到的completion回调，需要cancel方额外注意。
if ((NSInteger)[UIDevice currentDevice].systemVersion.floatValue != 12) { return; }

Class cls = NSClassFromString(@"__NSCFURLSessionTask");
SEL sel = NSSelectorFromString(@"resume");
Method method = class_getInstanceMethod(cls, sel);
BOOL(*origin_resume)(id,SEL) = (void*)method_getImplementation(method);
static char resumeTimeKey;
method_setImplementation(method, imp_implementationWithBlock(^BOOL(NSURLSessionTask* self){
    objc_setAssociatedObject(self, &resumeTimeKey, @(CACurrentMediaTime()) , OBJC_ASSOCIATION_COPY);
    Log(@"[Task Resume %p] %@:\n%@", self, self.currentRequest.URL, @"");
    return origin_resume(self, sel);
}));

sel = NSSelectorFromString(@"cancel");
method = class_getInstanceMethod(cls, sel);
void(*origin_cancel)(id,SEL) = (void*)method_getImplementation(method);
method_setImplementation(method, imp_implementationWithBlock(^(NSURLSessionTask* self){
    Log(@"[Task Cancel %p] %@:\n%@", self, self.currentRequest.URL, [NSThread callStackSymbols]);
    CFTimeInterval resumeTime = [(NSNumber*)objc_getAssociatedObject(self, &resumeTimeKey) doubleValue];
    CFTimeInterval diff = MAX(CACurrentMediaTime() - resumeTime, 0);
    if (diff < 0.2) {
        // 只有快速cancel时延迟，至少200ms后才能cancel. 防止在启动前cancel导致崩溃
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, diff * NSEC_PER_SEC), dispatch_get_global_queue(0, 0), ^{
            Log(@"[Task Cancel Delay %p] %@", self, self.currentRequest.URL);
            origin_cancel(self, sel);
        });
    } else {
        origin_cancel(self, sel);
    }
}));
LoadableRunloopIdleFuncEnd(LarkCrashSanitizer_CFNetworkBug)

#endif

@end
