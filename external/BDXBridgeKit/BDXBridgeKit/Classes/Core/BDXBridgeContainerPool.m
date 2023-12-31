//
//  BDXBridgeContainerPool.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/8/13.
//

#import "BDXBridgeContainerPool.h"

@interface BDXBridgeContainerPool ()

@property (nonatomic, copy) NSMapTable<NSString *, id<BDXBridgeContainerProtocol>> *containers;

@end

@implementation BDXBridgeContainerPool

+ (instancetype)sharedPool
{
    static BDXBridgeContainerPool *pool = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pool = [BDXBridgeContainerPool new];
    });
    return pool;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _containers = [NSMapTable strongToWeakObjectsMapTable];
    }
    return self;
}

- (void)setObject:(id<BDXBridgeContainerProtocol>)object forKeyedSubscript:(NSString *)key
{
    [self.containers setObject:object forKey:key];
}

- (id<BDXBridgeContainerProtocol>)objectForKeyedSubscript:(NSString *)key
{
    return [self.containers objectForKey:key];
}

@end

