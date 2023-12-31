//
//  OPTraceService.m
//  LarkOPInterface
//
//  Created by changrong on 2020/9/14.
//

#import "OPTraceService.h"
#import "OPMacros.h"

@interface OPTraceService()
@property (nonatomic, strong) OPTraceConfig *config;
@end
@interface OPTraceService(OPTrace)
- (OPTrace *)generateTrace:(nullable NSString *)parent;
- (OPTrace *)generateTraceWithBizName:(nonnull NSString *)bizName;
@end

@implementation OPTraceService

+ (instancetype)defaultService {
    static id defaultService;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultService = [[OPTraceService alloc] init];
    });
    return defaultService;
}

- (OPTrace *)generateTrace {
    return [self generateTrace:nil];
}


- (OPTrace *)generateTraceWithParent:(OPTrace *)parent {
    if (!parent) {
        OPLogError(@"use with parent, parent is nil!");
        NSAssert(NO, @"use with parent, parent is nil!");
        return [self generateTrace];
    }
    return [self generateTrace:parent.traceId];
}

- (OPTrace *)generateTraceWithParent:(nullable OPTrace *)parent bizName:(nonnull NSString *)bizName {
    if (!parent) {
        OPLogWarn(@"use with parent, parent is nil!");
        return [self generateTraceWithBizName:bizName];
    }
    return [parent subTraceWithBizName:bizName];
}

- (OPTrace *)generateTraceWithTraceID:(nonnull NSString *)traceID bizName:(nonnull NSString *)bizName {
    return [[OPTrace alloc] initWithTraceId:traceID BizName:bizName];
}


#pragma mark - For Tracing Lifecycle
- (void)setup:(OPTraceConfig *)config {
    if (self.config) {
        OPLogInfo(@"config has been register, old=%@, new=%@", self.config, config)
    }
    self.config = config;
}

#pragma mark - Internal
@end

@implementation OPTraceService(OPTrace)

- (OPTrace *)generateTrace:(nullable NSString *)parent {
    NSString *traceId = [self generateNewTraceId:parent];
    return [[OPTrace alloc] initWithTraceId:traceId];
}

- (OPTrace *)generateTraceWithBizName:(nonnull NSString *)bizName {
    NSString *traceId = [self generateNewTraceId:nil];
    return [[OPTrace alloc] initWithTraceId:traceId BizName:bizName];
}

- (NSString *)generateNewTraceId:(nullable NSString *)parent {
    if (!self.config) {
        OPLogError(@"no config for trace service");
        OPAssert(NO, @"no config for trace service");
        return parent ?: @"";
    }
    NSString *prefix = parent ?: self.config.prefix;
    return self.config.generator(prefix);
}

@end
