//
//  UIGestureRecognizer+BTDAdditions.m
//  ByteDanceKit
//
//  Created by wangdi on 2018/3/2.
//

#import "UIGestureRecognizer+BTDAdditions.h"
#import <objc/runtime.h>

static const int block_key;

@interface _BTDUIGestureRecognizerBlockTarget : NSObject

@property (nonatomic, copy) void (^block)(id sender);
- (id)initWithBlock:(void (^)(id sender))block;
- (void)invoke:(id)sender;

@end

@implementation _BTDUIGestureRecognizerBlockTarget

- (id)initWithBlock:(void (^)(id sender))block
{
    self = [super init];
    if (self) {
        _block = [block copy];
    }
    return self;
}

- (void)invoke:(id)sender
{
    if (_block) _block(sender);
}

@end

@implementation UIGestureRecognizer (BTDAdditions)

+ (instancetype)btd_gestureRecognizerWithActionBlock:(void (^)(id))block
{
    UIGestureRecognizer *gestureRecognizer = [[self alloc] init];
    [gestureRecognizer btd_addActionBlock:block];
    return gestureRecognizer;
}

- (void)btd_addActionBlock:(void (^)(id sender))block
{
    _BTDUIGestureRecognizerBlockTarget *target = [[_BTDUIGestureRecognizerBlockTarget alloc] initWithBlock:block];
    [self addTarget:target action:@selector(invoke:)];
    NSMutableArray *targets = [self _allUIGestureRecognizerBlockTargets];
    [targets addObject:target];
}

- (void)btd_removeAllActionBlocks
{
    NSMutableArray *targets = [self _allUIGestureRecognizerBlockTargets];
    [targets enumerateObjectsUsingBlock:^(id target, NSUInteger idx, BOOL *stop) {
        [self removeTarget:target action:@selector(invoke:)];
    }];
    [targets removeAllObjects];
}

- (NSMutableArray *)_allUIGestureRecognizerBlockTargets
{
    NSMutableArray *targets = objc_getAssociatedObject(self, &block_key);
    if (!targets) {
        targets = [NSMutableArray array];
        objc_setAssociatedObject(self, &block_key, targets, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return targets;
}

@end
