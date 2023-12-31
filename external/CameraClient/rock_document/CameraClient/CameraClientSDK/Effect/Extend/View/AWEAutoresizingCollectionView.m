//
//  AWEAutoresizingCollectionView.m
//  CameraClient
//
//  Created by Shen Chen on 2020/5/24.
//

#import "AWEAutoresizingCollectionView.h"

@implementation AWEAutoresizingCollectionView
- (CGSize)intrinsicContentSize {
    return self.contentSize;
}

- (void)setContentSize:(CGSize)contentSize {
    [super setContentSize:contentSize];
    [self invalidateIntrinsicContentSize];
}

@end
