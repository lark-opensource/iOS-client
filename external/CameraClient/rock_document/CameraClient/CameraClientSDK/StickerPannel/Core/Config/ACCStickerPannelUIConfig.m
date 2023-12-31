//
//  ACCStickerPannelUIConfig.m
//  AAWELaunchOptimization-Pods-DouYin
//
//  Created by liyingpeng on 2020/8/19.
//

#import "ACCStickerPannelUIConfig.h"
#import <CreativeKit/ACCFontProtocol.h>

@implementation ACCStickerPannelUIConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        _horizontalInset = 0;
        _numberOfItemsInOneRow = 4;
        _sizeRatio = 1;
        _slidingTabbarViewButtonTextNormalFont = [ACCFont() acc_boldSystemFontOfSize:15];
        _slidingTabbarViewButtonTextSelectFont = [ACCFont() acc_systemFontOfSize:15 weight:ACCFontWeightMedium];
        
        _isCollectionViewLayoutFixedSpace = YES;
        _shouldStickerBottomBarCollectionViewCellShowTitle = YES;
        _isStickerBottomBarCollectionViewCellSizeFixed = NO;
        _stickerCollectionViewCellInsets = UIEdgeInsetsMake(8, 8, 8, 8);
        _stickerCollectionViewCellImageContentMode = UIViewContentModeScaleToFill;
    }
    return self;
}

@end
