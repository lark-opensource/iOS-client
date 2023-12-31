//
//  LKCException.m
//  LarkMonitor
//
//  Created by sniperj on 2020/1/3.
//

#import "LKCException.h"
#import "LKCExceptionBase.h"
#import "LKCustomExceptionConfig.h"


@implementation LKCException

+ (instancetype)sharedInstance {
    static LKCException *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LKCException alloc] init];
    });
    return instance;
}

- (void)setupCustomExceptionWithConfig:(NSDictionary *)config {
    [self parseLKCustomExceptionModule:config];
    for (LKCustomExceptionConfig *config in _modules) {
        id<LKCExceptionProtocol> exception = [self getCustomExceptionByConfig:config];
        [exception start];
    }
}

- (void)stopCustomException {
    for (LKCustomExceptionConfig *config in _modules) {
        id<LKCExceptionProtocol> exception = [self getCustomExceptionByConfig:config];
        [exception end];
    }
}

- (void)parseLKCustomExceptionModule:(NSDictionary *)config {
    NSMutableArray *modules = [NSMutableArray array];
    NSArray *registModules = [LKCustomExceptionConfig getAllRegistExceptionClass];
    [config enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[NSDictionary class]]) {
            for (Class clazz in registModules) {
                if ([[(id)clazz configKey] isEqualToString:key]) {
                    LKCustomExceptionConfig *config = [[clazz alloc] initWithDictionary:obj];
                    [modules addObject:config];
                }
            }
        }
    }];
    _modules = modules;
}

- (id<LKCExceptionProtocol>)getCustomExceptionByConfig:(LKCustomExceptionConfig *)config {
    id<LKCExceptionProtocol> customException = [config getCustomException];
    if ([customException respondsToSelector:@selector(updateConfig:)]) {
        [customException updateConfig:config];
    }
    return customException;
}

@end
