//
//  NSArray+HMDTopN.m
//  Pods
//
//  Created by zhangxiao on 2021/4/25.
//

#import "NSArray+HMDTopN.h"
#import "NSArray+HMDSafe.h"
#import <objc/runtime.h>

static void hmd_swapHeapTopNArray(NSMutableArray *array, NSUInteger index, NSUInteger toIndex) {
    id temp = [array hmd_objectAtIndex:index];
    array[index] = array[toIndex];
    array[toIndex] = temp;
}

static void hmd_heapTopNHeapFormat(NSMutableArray *array, NSUInteger topN, NSUInteger index, NSComparator cmptr) {
    while (1) {
        NSUInteger maxIndex = index;
        if (!cmptr) { break; }
        if (((2 * index) < topN) && cmptr([array hmd_objectAtIndex:2*index], [array hmd_objectAtIndex:index]) == NSOrderedAscending) {
            maxIndex = 2 * index;
        }
        if ((2 * index + 1 < topN) && cmptr([array hmd_objectAtIndex:2*index + 1], [array hmd_objectAtIndex:maxIndex]) == NSOrderedAscending) {
            maxIndex = 2 * index + 1;
        }

        if (maxIndex != index) {
            hmd_swapHeapTopNArray(array, index, maxIndex);
            index = maxIndex;
        } else {
            break;
        }
    }
}

static void hmd_heapTopNBuildHeap(NSMutableArray *array, NSUInteger topN, NSComparator cmptr) {
    if (topN == 1) { return; }
    for (NSInteger i = topN / 2; i >= 0; i --) {
        hmd_heapTopNHeapFormat(array, topN, i, cmptr);
    }
}

@implementation NSArray (HMDTopN)

+ (NSArray *)hmd_heapTopNWithArray:(NSArray *)array topN:(NSUInteger)topN usingComparator:(NSComparator NS_NOESCAPE)cmptr {
    if (!array || array.count == 0) { return @[]; }
    if (array.count <= topN) { return array; }
    if (!cmptr) { return nil;}
    NSMutableArray *heap = @[].mutableCopy;
    NSInteger index = 0;
    while (index < topN) {
        [heap addObject:array[index++]];
    }
    hmd_heapTopNBuildHeap(heap, topN, cmptr);

    for (NSInteger i = topN; i < array.count; i++) {
        if (cmptr([heap hmd_objectAtIndex:0], [array hmd_objectAtIndex:i]) == NSOrderedAscending) {
            heap[0] = [array hmd_objectAtIndex:i];
            hmd_heapTopNHeapFormat(heap, topN, 0, cmptr);
        }
    }
    return [heap copy];
}

@end


@implementation NSMutableArray (HMDTopN)
@dynamic hmd_cmptr,hmd_topN;

- (NSUInteger)hmd_topN {
    NSNumber *topN = objc_getAssociatedObject(self, _cmd);
    return [topN unsignedIntegerValue];
}

- (void)setHmd_topN:(NSUInteger)hmd_topN {
    objc_setAssociatedObject(self, @selector(hmd_topN), @(hmd_topN), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSComparator)hmd_cmptr {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setHmd_cmptr:(NSComparator)hmd_cmptr {
    objc_setAssociatedObject(self, @selector(hmd_cmptr), hmd_cmptr, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)hmd_heapTopNAddObject:(id)object {
    if (!object) { return; }
    if (self.hmd_topN <= 0 || self.count < (self.hmd_topN) || !self.hmd_cmptr) {
        [self addObject:object];
        return;
    }

    if (self.count == (self.hmd_topN)) {
        hmd_heapTopNBuildHeap(self, self.hmd_topN, self.hmd_cmptr);
    }
    
    [self addObject:object];
    
    if (self.hmd_cmptr([self hmd_objectAtIndex:0], object) == NSOrderedAscending) {
        self[self.count-1] = self[0];
        self[0] = object;
        hmd_heapTopNHeapFormat(self, self.hmd_topN, 0, self.hmd_cmptr);
    }

}

- (NSArray *)hmd_topNArray {
    if (self.count <= self.hmd_topN || self.count <= 1) {
        return [self copy];
    }
    NSArray *array = [self subarrayWithRange:NSMakeRange(0, MIN(self.hmd_topN, self.count))];
    return [array copy];
}

@end
