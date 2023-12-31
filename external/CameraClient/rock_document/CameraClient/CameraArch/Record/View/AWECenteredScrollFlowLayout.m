//
//  AWECenteredScrollFlowLayout.m
//  AWEStudio
//
//  Created by jindulys on 2018/12/11.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "AWECenteredScrollFlowLayout.h"

@implementation AWECenteredScrollFlowLayout

- (void)prepareLayout
{
    [super prepareLayout];
    if (!self.collectionView) return;
    // 水平滚动
    self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    // 设置内边距
    CGFloat w = self.collectionView.frame.size.width;
    NSInteger count = [self.collectionView numberOfItemsInSection:0];
    CGFloat leftInset = (w/2 - self.itemSize.width/2);
    CGFloat rightInset = leftInset;
    if (count) {
        UICollectionViewLayoutAttributes *firstAttr = [self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
        UICollectionViewLayoutAttributes *lastAttr = [self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:count-1 inSection:0]];
        leftInset = MAX(0, w/2-firstAttr.size.width/2);
        rightInset = MAX(0, w/2-lastAttr.size.width/2);
    }
    self.sectionInset = UIEdgeInsetsMake(0, leftInset, 0, rightInset);
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self updatedLayoutAttributes:[super layoutAttributesForItemAtIndexPath:indexPath] forIndex:indexPath.item];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray<UICollectionViewLayoutAttributes *> *attributes = [super layoutAttributesForElementsInRect:rect];
    NSMutableArray *updatedAttributes = [NSMutableArray array];
    [attributes enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [updatedAttributes addObject:[self updatedLayoutAttributes:obj forIndex:obj.indexPath.item]];
    }];
    return updatedAttributes.copy;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
    // 计算出最终显示的矩形框
    CGRect rect;
    rect.origin.y = 0;
    rect.origin.x = proposedContentOffset.x;
    rect.size = self.collectionView.frame.size;
    
    // 获得super已经计算好的布局属性
    NSArray *array = [super layoutAttributesForElementsInRect:rect];
    
    // 计算collectionView最中心点的x值
    CGFloat centerX = proposedContentOffset.x + self.collectionView.frame.size.width * 0.5;
    
    // 存放最小的间距值
    CGFloat minDelta = MAXFLOAT;
    NSIndexPath *stoppedIndexPath;
    for (UICollectionViewLayoutAttributes *attrs in array) {
        if (ABS(minDelta) > ABS(attrs.center.x - centerX)) {
            minDelta = attrs.center.x - centerX;
            stoppedIndexPath = attrs.indexPath;
        }
    }
    
    // 修改原有的偏移量
    proposedContentOffset.x += minDelta;
    if (self.delegate && [self.delegate respondsToSelector:@selector(collectionViewScrollStopAtIndex:)]) {
        [self.delegate collectionViewScrollStopAtIndex:stoppedIndexPath.row];
    }
    return proposedContentOffset;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset
{
    if (![self.delegate respondsToSelector:@selector(collectionViewCurrentSelectedIndex)]) {
        return proposedContentOffset;
    }
    
    NSInteger selectedIndex = [self.delegate collectionViewCurrentSelectedIndex];
    if (selectedIndex >= [self.collectionView numberOfItemsInSection:0]) {
        return proposedContentOffset;
    }
    
    // 计算出最终显示的矩形框
    CGRect rect = CGRectZero;
    rect.origin.y = 0;
    rect.origin.x = proposedContentOffset.x;
    rect.size = self.collectionView.frame.size;
    
    // 获得super已经计算好的布局属性
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:selectedIndex inSection:0];
    UICollectionViewLayoutAttributes *selectedLayoutAttribute = [super layoutAttributesForItemAtIndexPath:indexPath];
    // 计算collectionView最中心点的x值
    CGFloat centerX = proposedContentOffset.x + self.collectionView.frame.size.width * 0.5;
    proposedContentOffset.x += selectedLayoutAttribute.center.x - centerX;
    return proposedContentOffset;
}

#pragma mark - Private

- (UICollectionViewLayoutAttributes *)updatedLayoutAttributes:(UICollectionViewLayoutAttributes *)attributes forIndex:(NSInteger)idx
{
    if (!self.enableScale) {
        return attributes;
    }
    UICollectionViewLayoutAttributes *obj = attributes.copy;
    CGFloat centerX = self.collectionView.contentOffset.x + self.collectionView.frame.size.width * 0.5;
    CGFloat delta = ABS(attributes.center.x - centerX);
    CGFloat transform = 1.0;
    if (self.ratioBlock) {
        transform = self.ratioBlock(delta);
    }
    // 设置缩放比例
    obj.transform = CGAffineTransformMakeScale(transform, transform);
    return obj;
}

@end
