//
//  BDXBridgeContext.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/6/17.
//

#import "BDXBridgeContext.h"

NSString * const BDXBridgeContextContainerKey = @"BDXBridgeContextContainerKey";

@interface BDXBridgeContext ()

@property (nonatomic, copy) NSMapTable<NSString *, id> *weakObjects;
@property (nonatomic, copy) NSMapTable<NSString *, id> *strongObjects;

@end

@implementation BDXBridgeContext

- (instancetype)init
{
    self = [super init];
    if (self) {
        _weakObjects = [NSMapTable strongToWeakObjectsMapTable];
        _strongObjects = [NSMapTable strongToStrongObjectsMapTable];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    BDXBridgeContext *copy = [[BDXBridgeContext allocWithZone:zone] init];
    if (copy) {
        copy.weakObjects = [self.weakObjects copy];
        copy.strongObjects = [self.strongObjects copy];
    }
    return copy;
}

- (void)setWeakObject:(id)object forKey:(NSString *)key
{
    [self.weakObjects setObject:object forKey:key];
}

- (void)setStrongObject:(id)object forKey:(NSString *)key
{
    [self.strongObjects setObject:object forKey:key];
}

- (id)objectForKeyedSubscript:(NSString *)key
{
    __block id object = nil;
    [[self mapTables] enumerateObjectsUsingBlock:^(NSMapTable *table, NSUInteger idx, BOOL *stop) {
        object = [table objectForKey:key];
        if (object) {
            *stop = YES;
            return;
        }
    }];
    return object;
}

- (NSArray<NSMapTable *> *)mapTables
{
    // Return an order-sensitive array.
    return @[self.weakObjects, self.strongObjects];
}

@end
