//
//  LKOpenTrace.m
//  LarkOpenTrace
//
//  Created by sniperj on 2020/12/21.
//

#import "LKOpenTrace.h"
#import <Heimdallr/HMDOTBridge.h>
#import <Heimdallr/HMDOTSpan.h>
#import <objc/runtime.h>
#import <LarkOpenTrace/LarkOpenTrace-Swift.h>


@implementation LKOpenTrace

+(void)load {
    [[HMDOTBridge sharedInstance] enableTraceBinding: YES];
    Method oriMethod = class_getInstanceMethod([HMDOTBridge class], @selector(appendSpans:forTraceID:));
    Method newMethod = class_getInstanceMethod([self class], @selector(my_appendSpans:forTraceID:));
    class_addMethod([HMDOTBridge class], @selector(my_appendSpans:forTraceID:), method_getImplementation(oriMethod), method_getTypeEncoding(oriMethod));
    BOOL isAddedMethod = class_addMethod([HMDOTBridge class], @selector(appendSpans:forTraceID:), method_getImplementation(newMethod), method_getTypeEncoding(newMethod));
    if (isAddedMethod) {
        class_replaceMethod([HMDOTBridge class], @selector(my_appendSpans:forTraceID:), method_getImplementation(oriMethod), method_getTypeEncoding(oriMethod));
    } else {
        method_exchangeImplementations(oriMethod, newMethod);
    }
}

- (void)my_appendSpans:(NSArray<HMDOTSpan *> *)spans forTraceID:(NSString *)traceID {
    [self my_appendSpans:spans forTraceID:traceID];
    for (HMDOTSpan *span in spans) {
        if ([span respondsToSelector:@selector(reportDictionary)]) {
            NSData *data = [NSJSONSerialization dataWithJSONObject:[span performSelector:@selector(reportDictionary)] options:0 error:NULL];
            NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [LKOpenTraceLogger logWithInfo:str];
        }
    }
}

@end
