//
//  NSObject+BDXPageKVO.m
//  BDXElement
//
//  Created by AKing on 2020/11/26.
//

#import "NSObject+BDXPageKVO.h"
#import <objc/objc.h>
#import <objc/runtime.h>

#ifndef BDX_DUMMY_CLASS
#define BDX_DUMMY_CLASS(_name_) \
@interface BDX_DUMMY_CLASS_ ## _name_ : NSObject @end \
@implementation BDX_DUMMY_CLASS_ ## _name_ @end
#endif

BDX_DUMMY_CLASS(NSObject_BDXPageKVO)

static const int kNSObjectBDXPageKVOBlockKey;

@interface _BDXNSObjectKVOBlockTarget : NSObject

@property (nonatomic, copy) void (^block)(__weak id obj, id oldVal, id newVal);

- (id)initWithBlock:(void (^)(__weak id obj, id oldVal, id newVal))block;

@end

@implementation _BDXNSObjectKVOBlockTarget

- (id)initWithBlock:(void (^)(__weak id obj, id oldVal, id newVal))block {
    self = [super init];
    if (self) {
        self.block = block;
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (!self.block) return;
    
    BOOL isPrior = [[change objectForKey:NSKeyValueChangeNotificationIsPriorKey] boolValue];
    if (isPrior) return;
    
    NSKeyValueChange changeKind = [[change objectForKey:NSKeyValueChangeKindKey] integerValue];
    if (changeKind != NSKeyValueChangeSetting) return;
    
    id oldVal = [change objectForKey:NSKeyValueChangeOldKey];
    if (oldVal == [NSNull null]) oldVal = nil;
    
    id newVal = [change objectForKey:NSKeyValueChangeNewKey];
    if (newVal == [NSNull null]) newVal = nil;
    
    self.block(object, oldVal, newVal);
}

@end

@implementation NSObject (BDXPageKVO)

- (void)bdx_addObserverBlockForKeyPath:(NSString *)keyPath block:(void (^)(__weak id obj, id oldVal, id newVal))block {
    if (!keyPath || !block) return;
    _BDXNSObjectKVOBlockTarget *target = [[_BDXNSObjectKVOBlockTarget alloc] initWithBlock:block];
    NSMutableDictionary *dic = [self _bdx_allNSObjectObserverBlocks];
    NSMutableArray *arr = dic[keyPath];
    if (!arr) {
        arr = [NSMutableArray new];
        dic[keyPath] = arr;
    }
    [arr addObject:target];
    [self addObserver:target forKeyPath:keyPath options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
}

- (void)bdx_removeObserverBlocksForKeyPath:(NSString *)keyPath {
    if (!keyPath) return;
    NSMutableDictionary *dic = objc_getAssociatedObject(self, &kNSObjectBDXPageKVOBlockKey);
    if (!dic) {
        return;
    }
    NSMutableArray *arr = dic[keyPath];
    [arr enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
        [self removeObserver:obj forKeyPath:keyPath];
    }];
    
    [dic removeObjectForKey:keyPath];
}

- (void)bdx_removeObserverBlocks {
    NSMutableDictionary *dic = objc_getAssociatedObject(self, &kNSObjectBDXPageKVOBlockKey);
    if (!dic) {
        return;
    }
    [dic enumerateKeysAndObjectsUsingBlock: ^(NSString *key, NSArray *arr, BOOL *stop) {
        [arr enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
            [self removeObserver:obj forKeyPath:key];
        }];
    }];
    
    [dic removeAllObjects];
}

- (NSMutableDictionary *)_bdx_allNSObjectObserverBlocks {
    NSMutableDictionary *targets = objc_getAssociatedObject(self, &kNSObjectBDXPageKVOBlockKey);
    if (!targets) {
        targets = [NSMutableDictionary new];
        objc_setAssociatedObject(self, &kNSObjectBDXPageKVOBlockKey, targets, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return targets;
}

@end
