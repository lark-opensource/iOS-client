//
//  HTSBootTask.m
//  HTSBootLoader
//
//  Created by Huangwenchen on 2019/11/14.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import "HTSBootNode.h"
#import "HTSBootLogger.h"
#import "HTSBootConfigKey.h"
#import "HTSSignpost.h"
#import "HTSAppContext.h"

@interface HTSBootNode()

@property (copy  , nonatomic) NSString * uniqueId;
@property (copy  , nonatomic) NSString * desc;
@property (strong, nonatomic) Class<HTSBootTask> taskClass;
@property (assign, nonatomic) BOOL canRun;
@property (assign, nonatomic) BOOL isMainThread;
@property (copy,   nonatomic) NSString * className;
@property (strong, nonatomic) NSNumber * delayOrForbidS;
@end

@implementation HTSBootNode

- (instancetype)initWithDictionary:(NSDictionary *)dic{
    if (self = [super init]) {
        NSString * className = [dic objectForKey:HTS_TASK_CLASS];
        //没有配置id的情况下，认为类名就是id
        self.uniqueId = [dic objectForKey:HTS_TASK_ID] ?: className;
        self.className = className;
        self.taskClass = NSClassFromString(className);
        NSParameterAssert(self.class != nil);
        self.desc = [dic objectForKey:HTS_TASK_DESC];
        self.isMainThread = [([dic objectForKey:HTS_TASK_THREAD] ?: @(YES)) boolValue];
        self.delayOrForbidS = [dic objectForKey:HTS_TASK_DELAY_OR_FORBID];
        _canRun = YES;
    }
    return self;
}

- (void)run{
    @synchronized (self) {
        if (!self.canRun) {
            return;
        }
        self.canRun = NO;
    }
    os_signpost_id_t signpostId = hts_signpost_begin(self.className.UTF8String);
    CFAbsoluteTime begin = CFAbsoluteTimeGetCurrent() * 1000;
    NSAssert([self.taskClass conformsToProtocol:@protocol(HTSBootTask)], @"Task(%@) not conforms to HTSBootTask",self.taskClass);
    id<HTSAppEventPlugin> plugin = HTSCurrentContext().appDelegate.appEventPlugin;
    if (plugin && [plugin respondsToSelector:@selector(applicationExecuteBootTask:pluginPosition:)]) {
        [plugin applicationExecuteBootTask:self.className pluginPosition:HTSPluginPositionBegin];
    }
    if ([self.taskClass respondsToSelector:@selector(execute)]) {
        NSNumber *delayOrForbid = self.delayOrForbidS;
        if (delayOrForbid) {
            double delayOrForbidS = delayOrForbid.doubleValue;
            if (delayOrForbidS == 0) {
                return;
            } else if (delayOrForbidS > 0) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayOrForbidS * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.taskClass execute];
                });
            } else if (delayOrForbidS < 0) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(-delayOrForbidS * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
                    [self.taskClass execute];
                });
            }
        } else {
            [self.taskClass execute];
        }
    }
    if (plugin && [plugin respondsToSelector:@selector(applicationExecuteBootTask:pluginPosition:)]) {
        [plugin applicationExecuteBootTask:self.className pluginPosition:HTSPluginPositionEnd];
    }
    CFAbsoluteTime end = CFAbsoluteTimeGetCurrent() * 1000;
    CFTimeInterval duration = end - begin;
    [[HTSBootLogger sharedLogger] logName:self.uniqueId duration:duration];
    hts_signpost_end(signpostId,self.className.UTF8String);
}

@end
