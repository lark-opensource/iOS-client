//
//  ACCSpeciesInfoCardCollectionViewLayout.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/6/17.
//

#import "ACCSpeciesInfoCardCollectionViewLayout.h"

@implementation ACCSpeciesInfoCardCollectionViewLayout

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray *attrsArray = [super layoutAttributesForElementsInRect:rect];
    CGFloat centerX = self.collectionView.contentOffset.x + self.collectionView.bounds.size.width * 0.5f;
    
    for (UICollectionViewLayoutAttributes *attrs in attrsArray) {
        CGFloat distance = fabs(attrs.center.x - centerX);
        CGFloat apartScale = distance / self.collectionView.bounds.size.width;
        CGFloat scale = fabs(cos(apartScale * M_PI / 4));
        attrs.transform = CGAffineTransformMakeScale(1.0, scale);
    }
    return attrsArray;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}

@end
