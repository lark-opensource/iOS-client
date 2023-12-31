//
//  AWETopBlendingView.m
//  CameraClient
//
//  Created by Shen Chen on 2020/1/22.
//

#import "AWETopBlendingView.h"


@implementation AWETopBlendingViewItem

- (instancetype)initWithColor:(UIColor *)color fromPosition:(CGFloat)from toPostion:(CGFloat)to
{
    self = [super init];
    if (self) {
        self.color = color;
        self.from = from;
        self.to = to;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    AWETopBlendingViewItem *item = [[self.class allocWithZone:zone] initWithColor:self.color fromPosition:self.from toPostion:self.to];
    item.zorder = self.zorder;
    return item;
}

- (void)updateNormalizedRangeFrom:(CGFloat)start to:(CGFloat)end
{
    self.from = start;
    self.to = end;
}

- (void)removeFromContainer {
    [self.blendingView removeItem:self];
}

@end

@interface AWETopBlendingView()
@property (nonatomic, strong) NSArray<AWETopBlendingViewItem *> *segments;
@property (nonatomic, strong) NSMutableArray<AWETopBlendingViewItem *> *items;
@end

@implementation AWETopBlendingView

@synthesize items = _items;
- (NSMutableArray<AWETopBlendingViewItem *> *)items
{
    if (!_items) {
        _items = @[].mutableCopy;
    }
    return _items;
}

- (void)addItem:(AWETopBlendingViewItem *)item
{
    [self.items addObject:item];
    item.blendingView = self;
    [self setNeedsLayout];
}

- (void)removeItem:(AWETopBlendingViewItem *)item
{
    NSUInteger index = [self.items indexOfObject:item];
    if (index != NSNotFound) {
        [self.items removeObjectAtIndex:index];
        item.blendingView = nil;
        [self setNeedsLayout];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateSegments];
}

- (void)updateSegments
{
    [self prepareSegments];
    [self drawSegments];
}

- (void)prepareSegments
{
    [self.items enumerateObjectsUsingBlock:^(AWETopBlendingViewItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.zorder = idx;
    }];
    NSArray<AWETopBlendingViewItem *> *fromQueue = [self.items sortedArrayUsingComparator:^NSComparisonResult(AWETopBlendingViewItem*  _Nonnull obj1, AWETopBlendingViewItem*  _Nonnull obj2) {
        NSComparisonResult result = [self compareFloat:obj1.from and:obj2.from];
        if (result != NSOrderedSame) {
            return result;
        } else {
            return [self compareFloat:obj1.zorder and:obj2.zorder];
        }
    }];
    NSArray<AWETopBlendingViewItem *> *toQueue = [self.items sortedArrayUsingComparator:^NSComparisonResult(AWETopBlendingViewItem*  _Nonnull obj1, AWETopBlendingViewItem*  _Nonnull obj2) {
        NSComparisonResult result = [self compareFloat:obj1.to and:obj2.to];
        if (result != NSOrderedSame) {
            return result;
        } else {
            return [self compareFloat:obj1.zorder and:obj2.zorder];
        }
    }];
    NSInteger fromIndex = 0;
    NSInteger toIndex = 0;
    NSMutableArray<AWETopBlendingViewItem *> *crossingItems = [NSMutableArray arrayWithCapacity:self.items.count];
    NSMutableArray<AWETopBlendingViewItem *> *segments = [NSMutableArray array];
    BOOL fromStart = YES;
    AWETopBlendingViewItem *topSegment;
    AWETopBlendingViewItem *currentItem;
    while (fromIndex < fromQueue.count || toIndex < toQueue.count) {
        // pick the next smallest point from two queues
        if (toIndex >= toQueue.count) {
            fromStart = YES;
        } else if (fromIndex >= toQueue.count) {
            fromStart = NO;
        } else {
            fromStart = (fromQueue[fromIndex].from < toQueue[toIndex].to);
        }
        
        if (fromStart) { // is start point
            currentItem = fromQueue[fromIndex];
            if (!topSegment || currentItem.zorder > topSegment.zorder) {
                if (topSegment) {
                    // end of current top segment, add to segments
                    topSegment.to = currentItem.from;
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
                topSegment.to = currentItem.to;
                [segments addObject:topSegment];
                [crossingItems removeObject:currentItem];
                // next top segment is from the top of crossing items
                topSegment = crossingItems.lastObject.copy;
                topSegment.from = currentItem.to;
            }
            toIndex += 1;
        }
    }
    self.segments = segments;
}

- (void)drawSegments
{
    [self.layer.sublayers.copy enumerateObjectsUsingBlock:^(CALayer*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperlayer];
    }];
    CGSize size = self.bounds.size;
    [self.segments enumerateObjectsUsingBlock:^(AWETopBlendingViewItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGRect frame = CGRectMake(obj.from * size.width, 0, (obj.to - obj.from) * size.width, size.height);
        CALayer *layer = [CALayer layer];
        layer.frame = frame;
        layer.backgroundColor = obj.color.CGColor;
        [self.layer addSublayer:layer];
    }];
}

- (void)addItem:(AWETopBlendingViewItem *)item toZOrderedArray:(NSMutableArray<AWETopBlendingViewItem *> *)array
{
    NSInteger l = 0;
    NSInteger r = array.count;
    NSInteger m = (l + r) / 2;
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

- (NSComparisonResult)compareFloat:(CGFloat)float1 and:(CGFloat)float2 {
    if (float1 < float2) {
        return NSOrderedAscending;
    } else if (float1 > float2) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

@end
