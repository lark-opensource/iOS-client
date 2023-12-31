//
//  BDSCCDomainListLRU.m
//  BDWebKit_Example
//
//  Created by bytedance on 2022/6/28.
//
#import "BDSCCDomainListLRU.h"
#import <ByteDanceKit/BTDMacros.h>
#import <TTNetworkManager/TTNetworkManager.h>

@interface BDSCCLRUMutableDictionary ()

@property (nonatomic, strong) NSMutableDictionary *dict;

@property (nonatomic, strong) NSMutableArray *arrayForLRU;

@property (nonatomic, assign) NSUInteger maxCountLRU;

@property (nullable, atomic, strong)dispatch_queue_t serialQueue;

@end

@implementation BDSCCLRUMutableDictionary

- (instancetype)initWithMaxCountLRU:(NSUInteger)maxCountLRU {
    self = [super init];
    if (self) {
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT, 0);
        _serialQueue = dispatch_queue_create("domain.SerialQueue", attr);
        _dict = [[NSMutableDictionary alloc] initWithCapacity:maxCountLRU];
        _arrayForLRU = [[NSMutableArray alloc] initWithCapacity:maxCountLRU];
        _maxCountLRU = maxCountLRU;
    }
    return self;
}
#pragma mark - NSDictionary

- (NSUInteger)count {
    return [_dict count];
}

- (NSEnumerator *)keyEnumerator {
    return [_dict keyEnumerator];
}

- (id)objectForKey:(id)aKey {
    return [self objectForKey:aKey returnEliminateObjectUsingBlock:^id(BOOL maybeEliminate) {
        return nil;
    }];
}

- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(id, id, BOOL *))block {
    [_dict enumerateKeysAndObjectsUsingBlock:block];
}

#pragma mark - NSMutableDictionary

- (void)removeObjectForKey:(id)aKey {
    [_dict removeObjectForKey:aKey];
    [self _removeObjectLRU:aKey];
}

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey {
    BOOL isExist = ([_dict objectForKey:aKey] != nil);
    
    if (isExist) {
        [self _adjustPositionLRU:aKey];
    } else {
        [self _addObjectLRU:aKey];
    }
}

- (BOOL)searchObject:(id<NSCopying>)aKey {
    BOOL isExist = ([_dict objectForKey:aKey] != nil);
    @weakify(self);
    dispatch_sync(_serialQueue, ^{
        @strongify(self);
        if(isExist == YES){
            [self _adjustPositionLRU:aKey];
        }
    });
    return isExist;
}

- (void)removeAllObjects {
    [_dict removeAllObjects];
    [_arrayForLRU removeAllObjects];
}

- (void)removeObjectsForKeys:(NSArray *)keyArray {
    [_dict removeObjectsForKeys:keyArray];
    [_arrayForLRU removeObjectsInArray:keyArray];
}

#pragma mark - LRUMutableDictionary

- (id)objectForKey:(id)aKey returnEliminateObjectUsingBlock:(id (^)(BOOL))block {
    id object = [_dict objectForKey:aKey];
    if (object) {
        [self _adjustPositionLRU:aKey];
    }
    if (block) {
        BOOL maybeEliminate = object ? NO : YES;
        id newObject = block(maybeEliminate);
        if (newObject) {
            [self setObject:newObject forKey:aKey];
            return [_dict objectForKey:aKey];
        }
    }
    return object;
}

#pragma mark - LRU

- (void)_adjustPositionLRU:(id)anObject {
    NSUInteger idx = [_arrayForLRU indexOfObject:anObject];
    if (idx != NSNotFound) {
        [_arrayForLRU removeObjectAtIndex:idx];
        [_arrayForLRU insertObject:anObject atIndex:0];
    }
}

- (void)_addObjectLRU:(id)anObject {
    [_arrayForLRU insertObject:anObject atIndex:0];
    [_dict setValue:@"1" forKey:anObject];
    if ((_maxCountLRU > 0) && (_arrayForLRU.count > _maxCountLRU)) {
        [_dict removeObjectForKey:[_arrayForLRU lastObject]];
        [_arrayForLRU removeLastObject];
    }
}

- (void)_removeObjectLRU:(id)anObject {
    [_arrayForLRU removeObject:anObject];
}

@end
