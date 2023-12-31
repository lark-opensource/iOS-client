//
//  ACCFocusCollectionViewLayout.m
//  CameraClient
//
//  Created by Shen Chen on 2020/4/1.
//  Copyright © 2020 Shen Chen. All rights reserved.
//

#import "ACCFocusCollectionViewLayout.h"

@interface ACCFocusCollectionViewLayout()
@property (nonatomic, strong) NSMutableArray<UICollectionViewLayoutAttributes *> *cache;
@end

@implementation ACCFocusCollectionViewLayout

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.normalCellSize = CGSizeMake(48, 48);
        self.centerCellSize = CGSizeMake(64, 64);
        self.normalMargin = 8;
        self.centerMargin = 14;
        self.resistance = 1;
        self.enablePaging = NO;
        self.bandWidth = 1.0;
    }
    return self;
}

- (void)prepareLayout
{
    NSInteger count = [self.collectionView numberOfItemsInSection:0];
    if ([self needUpdateLayout]) {
        if (!self.cache) {
            self.cache = [self arrayOfLayoutAttributesStartFromIndex:0 count:count];
        }
        if (self.cache.count > count) {
            [self.cache removeObjectsInRange:NSMakeRange(count, self.cache.count - count)];
        } else if (self.cache.count < count) {
            NSArray *array = [self arrayOfLayoutAttributesStartFromIndex:self.cache.count count:count - self.cache.count];
            [self.cache addObjectsFromArray:array];
        }
        [self updateLayoutForBounds:self.collectionView.bounds];
    }
}

- (CGFloat)contentWidth
{
    if (_contentWidth == 0) {
        _contentWidth = self.collectionView.bounds.size.width;
    }
    return _contentWidth;
}

- (CGFloat)itemWidth
{
    return self.normalCellSize.width + 2 * self.normalMargin;
}

- (BOOL)needUpdateLayout
{
    return YES;
}

- (CGSize)collectionViewContentSize
{
    return CGSizeMake(self.contentWidth, self.collectionView.bounds.size.height);
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.cache[indexPath.item];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray<UICollectionViewLayoutAttributes *> *attributesArray = [NSMutableArray array];
    for (UICollectionViewLayoutAttributes *attributes in self.cache) {
        if (CGRectIntersectsRect(attributes.frame, rect)) {
            [attributesArray addObject:attributes];
        }
    }
    return attributesArray;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    [self updateLayoutForBounds:newBounds];
    return YES;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
    CGFloat v = velocity.x;
    CGFloat offset = proposedContentOffset.x;
    CGFloat distance = 0;
    if (fabs(v) > 0.0001 && self.resistance > 0) {
        CGFloat deceleration = v / 1000 * self.resistance;
        distance = 0.5 * v * v / deceleration;
        offset = self.collectionView.contentOffset.x + distance;
        offset = MAX(offset, 0);
        offset = MIN(offset, self.contentWidth - self.collectionView.bounds.size.width);
    }
    if (self.enablePaging) {
        CGFloat itemWidth = self.normalCellSize.width + 2 * self.normalMargin;
        offset = round(offset / itemWidth) * itemWidth;
    }
    if ([self.delegate respondsToSelector:@selector(layout:targetContentOffsetXForProposedContentOffsetX:withScrollingVelocityX:)]) {
        offset = [self.delegate layout:self targetContentOffsetXForProposedContentOffsetX:offset withScrollingVelocityX:v];
    }
    return CGPointMake(offset, proposedContentOffset.y);
}

- (NSMutableArray *)arrayOfLayoutAttributesStartFromIndex:(NSInteger)index count:(NSInteger)count
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:count];
    for (NSInteger i=0; i < count; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index+i inSection:0];
        array[i] = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    }
    return array;
}

- (void)updateLayoutForBounds:(CGRect)bounds {
    CGFloat scrollableContentWidth = (self.cache.count - 1) * [self itemWidth];
    self.contentWidth = scrollableContentWidth + bounds.size.width;
    
    CGFloat centerY = bounds.size.height * 0.5;
    CGFloat midX = CGRectGetMidX(bounds);
    CGFloat centerPosition = bounds.origin.x / [self itemWidth];
    for (UICollectionViewLayoutAttributes *attributes in self.cache) {
        CGFloat position = (CGFloat)attributes.indexPath.item;
        CGFloat distance = [self distanceToPoint:position fromCenter:centerPosition];
        CGSize size = [self sizeAtPoint:position withCenter:centerPosition];
        CGRect frame = CGRectMake(distance + midX - 0.5 * size.width, centerY - 0.5 * size.height, size.width, size.height);
        attributes.frame = frame;
    }
}

- (CGFloat)currentCenterPosition
{
    return self.collectionView.contentOffset.x / [self itemWidth];
}

- (CGFloat)distanceToPoint:(CGFloat)point fromCenter:(CGFloat)center
{
    CGFloat centerValue = self.centerCellSize.width + self.centerMargin * 2;
    CGFloat normalValue = self.normalCellSize.width + self.normalMargin * 2;
    return [self integralOfFunctionWithHighValue:centerValue lowValue:normalValue bandWidth:self.bandWidth fromPoint:0 toPoint:point-center];
}

- (CGSize)sizeAtPoint:(CGFloat)point withCenter:(CGFloat)center
{
    CGFloat w = [self valueOfFunctionWithHighValue:self.centerCellSize.width lowValue:self.normalCellSize.width bandWidth:self.bandWidth atPoint:point - center];
    CGFloat h = [self valueOfFunctionWithHighValue:self.centerCellSize.height lowValue:self.normalCellSize.height bandWidth:self.bandWidth atPoint:point - center];
    return CGSizeMake(w, h);
}

- (CGFloat)valueOfFunctionWithHighValue:(CGFloat)high lowValue:(CGFloat)low bandWidth:(CGFloat)width atPoint:(CGFloat)x
{
    if (x < -width) {
        return low;
    } else if (x < 0) {
        return (high - low) / width * x + high;
    } else if (x < width) {
        return (low - high) / width * x + high;
    } else {
        return low;
    }
}

- (CGFloat)integralOfFunctionWithHighValue:(CGFloat)high lowValue:(CGFloat)low bandWidth:(CGFloat)width fromPoint:(CGFloat)from toPoint:(CGFloat)to
{
    CGFloat sign = 1;
    if (from > to) {
        CGFloat tmp = from;
        from = to;
        to = tmp;
        sign = -1;
    }
    CGFloat s = 0;
    CGFloat t;
    if (from < -width) {
        t = MIN(-width, to);
        s += (t - from) * low;
        if (to < -width) {
            return s * sign;
        }
        from = t;
    }
    if (from < 0) {
        t = MIN(0, to);
        CGFloat startValue = [self valueOfFunctionWithHighValue:high lowValue:low bandWidth:width atPoint:from];
        CGFloat endValue = [self valueOfFunctionWithHighValue:high lowValue:low bandWidth:width atPoint:t];
        s += (t - from) * (startValue + endValue) / 2;
        if (to < 0) {
            return s * sign;
        }
        from = t;
    }
    if (from < width) {
        t = MIN(width, to);
        CGFloat startValue = [self valueOfFunctionWithHighValue:high lowValue:low bandWidth:width atPoint:from];
        CGFloat endValue = [self valueOfFunctionWithHighValue:high lowValue:low bandWidth:width atPoint:t];
        s += (t - from) * (startValue + endValue) / 2;
        if (to < width) {
            return s * sign;
        }
        from = t;
    }
    s += (to - from) * low;
    return s * sign;
}

- (NSInteger)indexOfCurrentCenteredItem
{
    return (NSInteger)round([self currentCenterPosition]);
}

- (CGFloat)contentOffsetForCenteredItemAtIndex:(NSInteger)index
{
    return (CGFloat)(index) * [self itemWidth];
}

@end
