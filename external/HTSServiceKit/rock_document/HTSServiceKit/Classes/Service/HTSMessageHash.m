//
//  HTSMessageHash.m
//  HTSServiceKit
//

#import "HTSMessageHash.h"

@interface HTSMessageHash ()
{
    NSMutableDictionary<id, NSHashTable *> *p_hash;
}

@end

@implementation HTSMessageHash

- (instancetype)init
{
    if (self = [super init]) {
        p_hash = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)registerMessage:(id) oObserver forKey:(id) nsKey
{
    if (oObserver == nil || nsKey == nil) {
        assert(0);
        return;
    }

    NSHashTable *selectorImplememters = [p_hash objectForKey:nsKey];
    if (selectorImplememters == nil) {
        selectorImplememters = [NSHashTable weakObjectsHashTable];
        [p_hash setObject:selectorImplememters forKey:nsKey];
    }
    
    if ([selectorImplememters containsObject:oObserver]) {
        return;
    }

    [selectorImplememters addObject:oObserver];
}

- (void)unregisterMessage:(id) oObserver forKey:(id) nsKey
{
    if (oObserver == nil || nsKey == nil) {
        assert(0);
    }
    
    NSHashTable *ary = [p_hash objectForKey:nsKey];
    [ary removeObject:oObserver];
}

- (void)unregisterKeyMessage:(id)oObserver
{
    for(NSHashTable *selectorImplememters in [p_hash allValues]) {
        [selectorImplememters removeObject:oObserver];
    }
}

- (NSArray *)getKeyMessageList:(id)nsKey
{
    return [[p_hash objectForKey:nsKey] allObjects];
}

@end
