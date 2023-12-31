//
//  ACCSegmentBlender.m
//  CameraClient-Pods-Aweme
//
//  Created by Shen Chen on 2020/8/18.
//

#import "ACCSegmentBlender.h"

@implementation ACCSegmentBlender

- (NSArray<NSObject<ACCSegmentItem> *>*)blendItems:(NSArray<NSObject<ACCSegmentItem> *> *)inputItems
{
    // filter out invalid items and set zorder
    NSMutableArray<NSObject<ACCSegmentItem> *> *items = [NSMutableArray array];
    [inputItems enumerateObjectsUsingBlock:^(NSObject<ACCSegmentItem> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.zorder = idx;
        if (obj.startPosition < obj.endPosition) {
            [items addObject:obj];
        }
    }];
    // sort by two ends into two queues
    NSArray<NSObject<ACCSegmentItem> *> *fromQueue = [items sortedArrayUsingComparator:^NSComparisonResult(NSObject<ACCSegmentItem> *  _Nonnull obj1, NSObject<ACCSegmentItem> *  _Nonnull obj2) {
        NSComparisonResult result = [self compareFloat:obj1.startPosition and:obj2.startPosition];
        if (result != NSOrderedSame) {
            return result;
        } else {
            return -[self compareFloat:obj1.zorder and:obj2.zorder];
        }
    }];
    NSArray<NSObject<ACCSegmentItem> *> *toQueue = [items sortedArrayUsingComparator:^NSComparisonResult(NSObject<ACCSegmentItem> *  _Nonnull obj1, NSObject<ACCSegmentItem> *  _Nonnull obj2) {
        NSComparisonResult result = [self compareFloat:obj1.endPosition and:obj2.endPosition];
        if (result != NSOrderedSame) {
            return result;
        } else {
            return -[self compareFloat:obj1.zorder and:obj2.zorder];
        }
    }];
    NSInteger fromIndex = 0;
    NSInteger toIndex = 0;
    NSMutableArray<NSObject<ACCSegmentItem> *> *crossingItems = [NSMutableArray arrayWithCapacity:items.count];
    NSMutableArray<NSObject<ACCSegmentItem> *> *segments = [NSMutableArray array];
    BOOL fromStart = YES;
    NSObject<ACCSegmentItem> *topSegment;
    NSObject<ACCSegmentItem> *currentItem;
    while (fromIndex < fromQueue.count || toIndex < toQueue.count) {
        // pick the next smallest point from two queues
        if (toIndex >= toQueue.count) {
            fromStart = YES;
        } else if (fromIndex >= toQueue.count) {
            fromStart = NO;
        } else {
            fromStart = (fromQueue[fromIndex].startPosition <= toQueue[toIndex].endPosition);
        }
        
        if (fromStart) { // is start point
            currentItem = fromQueue[fromIndex];
            if (!topSegment || currentItem.zorder > topSegment.zorder) {
                if (topSegment) {
                    // end of current top segment, add to segments
                    topSegment.endPosition = currentItem.startPosition;
                    [segments addObject:topSegment];
                }
                topSegment = currentItem.copy;
            }
            // add current item to crossing items
            [self addItem:currentItem toZOrderedArray:crossingItems];
            fromIndex += 1;
        } else { // is end point
            currentItem = toQueue[toIndex];
            // end of current item, remove current item from crossing items
            [crossingItems removeObject:currentItem]; // TODO: use remove object at index
            
            if (topSegment && currentItem.zorder == topSegment.zorder) {
                // end of current top segment, add to segments
                topSegment.endPosition = currentItem.endPosition;
                [segments addObject:topSegment];
                [crossingItems removeObject:currentItem];
                // next top segment is from the top of crossing items
                topSegment = crossingItems.lastObject.copy;
                topSegment.startPosition = currentItem.endPosition;
            }
            toIndex += 1;
        }
    }
    if (segments.count < 1) {
        return segments;
    }
    // merge same segments
    NSMutableArray<NSObject<ACCSegmentItem> *> *finalSegments = [NSMutableArray array];
    NSInteger i = 1;
    NSObject<ACCSegmentItem> *currentSegment = segments.firstObject.copy;
    while (i < segments.count) {
        if (segments[i].startPosition <= currentSegment.endPosition && [currentSegment canMergeWith:segments[i]] ) {
            currentSegment.endPosition = segments[i].endPosition;
        } else {
            if (currentSegment.startPosition < currentSegment.endPosition) {
                [finalSegments addObject:currentSegment];
            }
            currentSegment = segments[i].copy;
        }
        i += 1;
    }
    if (currentSegment.startPosition < currentSegment.endPosition) {
        [finalSegments addObject:currentSegment];
    }
    return finalSegments;
}

- (void)addItem:(NSObject<ACCSegmentItem> *)item toZOrderedArray:(NSMutableArray<NSObject<ACCSegmentItem> *> *)array
{
    NSInteger l = 0;
    NSInteger r = array.count;
    NSInteger m;
    while (l <= r - 1) {
        m = (l + r) / 2;
        if (array[m].zorder < item.zorder) {
            l = m + 1;
        } else if (array[m].zorder > item.zorder) {
            r = m;
        } else {
            break;
        }
    }
    [array insertObject:item atIndex:l];
}

- (NSComparisonResult)compareFloat:(double)float1 and:(double)float2 {
    if (float1 < float2) {
        return NSOrderedAscending;
    } else if (float1 > float2) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

@end
