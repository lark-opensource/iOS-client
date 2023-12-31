//
//  AWEModernStickerTitleCollectionView.m
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/4/15.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWEModernStickerTitleCollectionView.h"

@implementation AWEModernStickerTitleCollectionView

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout
{
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        if (@available(iOS 10.0, *)) {
            self.prefetchingEnabled = NO;
        }
    }
    return self;
}

@end
