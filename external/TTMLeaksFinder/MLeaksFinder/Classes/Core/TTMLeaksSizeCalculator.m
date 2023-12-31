//
//  TTMLeaksSizeCalculator.m
//  TTMLeaksFinder
//
//  Created by  郎明朗 on 2021/5/14.
//

#import "TTMLeaksSizeCalculator.h"
#import "TTMLNodeEnumerator.h"
#import <objc/runtime.h>
#import <FBRetainCycleDetector/FBObjectGraphConfiguration.h>

static const NSInteger MaxTreeDepth = 30;
static const NSInteger MaxNodeNumber = 10000;
static const void *kGraphElement = &kGraphElement;
static const void *kObjectSet = &kObjectSet;

extern FBObjectiveCGraphElement *_Nullable FBWrapObjectGraphElement(FBObjectiveCGraphElement *_Nullable sourceElement,
                                                             id _Nullable object,
                                                             FBObjectGraphConfiguration *_Nullable configuration);


@implementation TTMLeaksSizeCalculator

+ (double)tt_memoryUseOfObj:(id)obj {
    return [[self class] tt_memoryUseOfObj:obj maxNodeNumber:MaxNodeNumber maxTreeDepth:MaxTreeDepth];
}

+ (double)tt_memoryUseOfObj:(id)obj maxNodeNumber:(NSInteger)maxNodeNumber maxTreeDepth:(NSInteger)maxTreeDepth {
    
    TTMLNodeEnumerator *wrappedObject = [[TTMLNodeEnumerator alloc] initWithObject:FBWrapObjectGraphElement(nil,obj, [[FBObjectGraphConfiguration alloc] init])];//@langminglang 这里没有使用缓存
    
    NSMutableSet *objectSet = [[NSMutableSet alloc] init];
    
    // Stack will keep current path in the graph
    NSMutableArray<TTMLNodeEnumerator *> *stack = [NSMutableArray new];
    [stack addObject:wrappedObject];
    
    double totalSize = 0;
    NSUInteger current_tree_depth = 0;
    NSUInteger current_node_number = 0;
    
    // Let's start with the root
    while ([stack count] > 0) {
        NSUInteger current_stcak_size = [stack count];
        current_tree_depth ++;
        if (current_tree_depth > MaxTreeDepth) {
            break;
        }
        for (NSUInteger i = 0; i < current_stcak_size; i++) {
            // Algorithm creates many short-living objects. It can contribute to few
            // hundred megabytes memory jumps if not handled correctly, therefore
            // we're gonna drain the objects with our autoreleasepool.
            @autoreleasepool {
                // Take topmost node in stack and mark it as visited
                TTMLNodeEnumerator *top = [stack firstObject];
                
                id object = top.object.object;
                
                if ([object isProxy]) {// 不访问 NSProxy ，有坑(crash)
                    [stack removeObjectAtIndex:0];
                    continue;
                }
                
                // We don't want to retraverse the same subtree
                if ([objectSet containsObject:@([top.object objectAddress])]) {
                    [stack removeObjectAtIndex:0];
                    continue;
                }
                // Add the object address to the set as an NSNumber to avoid. And unnecessarily retaining the object
                [objectSet addObject:@([top.object objectAddress])];
                
                
                #define specialCase(cls, size) \
                if ([object isKindOfClass:[cls class]]) { \
                    totalSize += size; \
                }
                // 目前单独适配 NSData, NSString UIImage类型，另UIView，Text系列，UIImageView，Webview系列等未想到好的适配方法
                specialCase(NSData, [(NSData *)object length])
                // 2是utf-16的常见编码长度，只算一个预估值
                specialCase(NSString, [(NSString*)object length] * 2)
                // 可能会夸大UIImage对象对内存的影响
                specialCase(UIImage, [(UIImage*)object size].width * [(UIImage*)object size].height * 4)
                totalSize += class_getInstanceSize([object class]);
                current_node_number ++;
                
                // find all property of top
                if (current_tree_depth < MaxTreeDepth && current_node_number < maxNodeNumber ) { //提高效率
                    TTMLNodeEnumerator *firstAdjacent = [top nextObject];
                    while (firstAdjacent) {
                        [stack addObject:firstAdjacent];
                        firstAdjacent = [top nextObject];
                    }
                }
                // Node has no more adjacent nodes, it itself is done, move on
                [stack removeObjectAtIndex:0];
            }
        }
    }
    return totalSize;
}
@end
