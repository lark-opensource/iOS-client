//
//  TTNodeEnumerator.m
//  MLeaksFinder
//
//  Created by renpengcheng on 2019/2/20.
//  Copyright © 2019 zeposhe. All rights reserved.
//

#import "TTMLNodeEnumerator.h"
#import <FBRetainCycleDetector/FBObjectiveCGraphElement.h>
#import <FBRetainCycleDetector/FBRetainCycleUtils.h>

@implementation TTMLGraphNode

- (instancetype)initWithObject:(id)object {
    if (self = [super init]) {
        self.object = object;
        self.children = [NSMutableArray new];
        self.clazzName = NSStringFromClass([object class]);
    }
    return self;
}

- (void)dealloc {
    
}

//|-A
//|-B
//  |-C
- (NSString *)treeDescription {
    return [self treeDescriptionWithDepth:0];
}

- (NSMutableString *)treeDescriptionWithDepth:(NSInteger)depth {
    NSMutableString *s = [[NSMutableString alloc] init];
    for (int i = 0; i < depth; i++) {
        [s appendString:@"  "];
    }
    [s appendString:@"|-"];
    [s appendString:[self description]];
    [s appendString:@"\n"];
    
    for (TTMLGraphNode *child in self.children) {
        [s appendString:[child treeDescriptionWithDepth:depth+1]];
    }
    
    return s;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@ <0x%02zx>", [super description], NSStringFromClass([self.object class]), (size_t)self.object];
//    NSMutableArray<TTMLGraphNode *> *queue = [self.children mutableCopy];
//    NSUInteger count = 0;
//    while (queue.count > 0) {
//        count += 1;
//        [queue addObjectsFromArray:queue.firstObject.children];
//        [queue removeObjectAtIndex:0];
//    }
//    return [NSString stringWithFormat:@"{name: %@, childCount: %lu}",
//            NSStringFromClass([self.object class]), (unsigned long)count];
}

- (NSInteger)traverseAndCountClassName:(NSString *)className shouldCount:(BOOL)shouldCount; {
    __block int count = 0;
    if ([NSStringFromClass([self.object class]) isEqualToString:className]) {
        shouldCount = YES;
    }
    if (shouldCount) {
        count += 1;
    }
    [self.children enumerateObjectsUsingBlock:^(TTMLGraphNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        count += [obj traverseAndCountClassName:className shouldCount:shouldCount];
    }];
    return count;
}

@end

@implementation TTMLNodeEnumerator
{
    NSSet *_retainedObjectsSnapshot;
    NSEnumerator *_enumerator;
}

- (instancetype)initWithObject:(FBObjectiveCGraphElement *)object {
    return [self initWithObject:object addChildDelegate:nil];
}

- (instancetype)initWithObject:(FBObjectiveCGraphElement *)object addChildDelegate:(id<TTMLNodeAddChildrenDelegate>)delegate {
    if (self = [super init]) {
        _object = object;
        self.node = [[TTMLGraphNode alloc] initWithObject:object.object];
        self.delegate = delegate;
    }
    
    return self;
}

- (TTMLNodeEnumerator *)nextObject {
    if (!_object) {
        return nil;
    } else if (!_retainedObjectsSnapshot) {
        
        _retainedObjectsSnapshot = [_object allRetainedObjects];
        //合并vc/view 节点和非vc/view节点
        if (self.delegate && [self.delegate respondsToSelector:@selector(addedChildrenForNodeEnumerator:)]) {
            NSSet *addedChildren = [self.delegate addedChildrenForNodeEnumerator:self];
            NSMutableSet *childElements = [[NSMutableSet alloc] init];
            [addedChildren enumerateObjectsUsingBlock:^(id  _Nonnull child, BOOL * _Nonnull stop) {
                FBObjectiveCGraphElement *element = FBWrapObjectGraphElementWithContext(_object,
                                                                                        child,
                                                                                        _object.configuration,
                                                                                        @[@"__child_view/vc__"]);
                if (element){
                    [childElements addObject:element];
                }
            }];
            _retainedObjectsSnapshot = [_retainedObjectsSnapshot setByAddingObjectsFromSet:childElements];
        }
        
        NSArray *ary = [NSArray arrayWithArray: [_retainedObjectsSnapshot allObjects]];
        ary = [ary sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            int seed = arc4random_uniform(2);
            if (seed) {
                return [@((size_t)obj1) compare:@((size_t)obj2)];
            } else {
                return [@((size_t)obj2) compare:@((size_t)obj1)];
            }
        }];
        _enumerator = [ary objectEnumerator];
    }
    
    FBObjectiveCGraphElement *next = [_enumerator nextObject];
    
    if (next) {
        return [[TTMLNodeEnumerator alloc] initWithObject:next addChildDelegate:self.delegate];
    }
    
    return nil;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[TTMLNodeEnumerator class]]) {
        TTMLNodeEnumerator *enumerator = (TTMLNodeEnumerator *)object;
        return [self.object isEqual:enumerator.object];
    }
    
    return NO;
}

- (NSUInteger)hash {
    return [self.object hash];
}

@end
