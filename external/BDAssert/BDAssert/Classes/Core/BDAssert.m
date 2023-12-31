//
//  BDAssert.m
//  BDAssert
//
//  Created by 李琢鹏 on 2019/1/31.
//

#import "BDAssert.h"

void BDAssert(BOOL condition, NSString *desc, ...) {
    va_list args;
    va_start(args, desc);
    if (__builtin_expect(!(condition), 0)) {
#if !defined(NS_BLOCK_ASSERTIONS)
        [NSException raise:@"BDAssert" format:desc arguments:args];
#else
        [BDAssertionPluginManager handleFailureWithDesc:[[NSString alloc] initWithFormat:desc arguments:args]];
#endif
    }
    va_end(args);
}

void BDParameterAssert(BOOL condition) {
    if (__builtin_expect(!(condition), 0)) {
#if !defined(NS_BLOCK_ASSERTIONS)
        [NSException raise:@"BDAssert" format:@"Void parameter"];
#else
        [BDAssertionPluginManager handleFailureWithDesc:@"Void parameter"];
#endif
    }
}

@implementation BDAssertionPluginManager

static NSMutableArray<Class<BDAssertionPlugin>> *_plugins;
+(void)addPlugin:(Class<BDAssertionPlugin>)plugin {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _plugins = [NSMutableArray array];
    });
    [_plugins addObject:plugin];
}

+(void)removePlugin:(Class<BDAssertionPlugin>)plugin {
    [_plugins removeObject:plugin];
}

+ (void)handleFailureWithDesc:(NSString *)desc {
    for (Class<BDAssertionPlugin> plugin in _plugins) {
        if ([plugin respondsToSelector:@selector(handleFailureWithDesc:)]) {
            [plugin handleFailureWithDesc:desc];
        }
    }
}


@end
