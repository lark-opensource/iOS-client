//
//  ACCCommonMultiRowsCollectionLayout.m
//  Aweme
//
//  Created by 卜旭阳 on 2021/11/3.
//

#import "ACCCommonMultiRowsCollectionLayout.h"

@interface ACCCommonMultiRowsCollectionLayout()

@property (nonatomic, assign) CGSize currentContentSize;
@property (nonatomic, copy) NSArray *attributesArray;

@end

@implementation ACCCommonMultiRowsCollectionLayout

- (void)prepareLayout
{
    [super prepareLayout];

    NSMutableArray *attributesArray = [NSMutableArray array];
    NSInteger count = [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:0];
    for (NSInteger idx = 0; idx < count; ++idx) {
        [attributesArray addObject:[self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:idx inSection:0]]];
    }

    NSMutableArray *xArray = [NSMutableArray array];
    for (NSInteger idx = 0; idx < self.numberOfRows; ++idx) {
        [xArray addObject:@(self.sectionInset.left)];
    }

    __block CGFloat maxY = 0;
    [attributesArray enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *attributes, NSUInteger idx, BOOL * _Nonnull stop) {
        NSNumber *min = [xArray valueForKeyPath:@"@min.self"];
        NSInteger index = [xArray indexOfObject:min];
        if (!min || index == NSNotFound) {
            return;
        }

        CGRect frame = attributes.frame;
        frame.origin.x = min.doubleValue;
        frame.origin.y = index * (frame.size.height + self.SpacingY) + self.sectionInset.top;
        attributes.frame = frame;

        xArray[index] = @(CGRectGetMaxX(frame) + self.spacingX);
        maxY = MAX(maxY, CGRectGetMaxY(frame));
    }];

    CGFloat maxX = [[xArray valueForKeyPath:@"@max.self"] doubleValue] - self.spacingX;
    self.currentContentSize = CGSizeMake(maxX + self.sectionInset.right, maxY + self.sectionInset.bottom);
    self.attributesArray = attributesArray;
}

- (CGSize)collectionViewContentSize
{
    return self.currentContentSize;
}

- (nullable NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
    return self.attributesArray;
}

@end
