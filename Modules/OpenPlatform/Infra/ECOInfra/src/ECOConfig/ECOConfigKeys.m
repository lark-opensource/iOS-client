//
//  ECOConfigKeys.m
//  ECOInfra
//
//  Created by 窦坚 on 2021/6/15.
//

#import "ECOConfigKeys.h"

static NSMutableSet<NSString *> *configKeys;

@interface ECOConfigKeys()
@end

@implementation ECOConfigKeys

+ (NSArray<NSString *> *)allRegistedKeys {
    return configKeys.allObjects;
}

+ (void)registerConfigKeys:(NSArray<NSString *> * _Nonnull)keys {
    if (!configKeys) {
        configKeys = [[NSMutableSet alloc] init];
    }

    [configKeys addObjectsFromArray:keys];
}

@end

@interface ECOConfigFetchContext()
@end

@implementation ECOConfigFetchContext
- (instancetype)init
{
    self = [super init];
    if (self) {
        _shouldBreakUpdate = NO;
    }
    return self;
}
@end
