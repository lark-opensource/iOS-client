//
//  ACCStickerPannelUIConfig.h
//  AAWELaunchOptimization-Pods-DouYin
//
//  Created by liyingpeng on 2020/8/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCStickerPannelUIConfig : NSObject

// common Configuration

@property (nonatomic, assign) CGFloat horizontalInset;

// pannel sticker item height/width ratio
@property (nonatomic, assign) CGFloat sizeRatio;

// pannel show top offset, default is 0.11
@property (nonatomic, assign) CGFloat pannelTopOffset;

// pannel column number
@property (nonatomic, assign) NSInteger numberOfItemsInOneRow;

// sliding font config
@property (nonatomic, strong) UIFont *slidingTabbarViewButtonTextNormalFont;
@property (nonatomic, strong) UIFont *slidingTabbarViewButtonTextSelectFont;

// for multiple pannel configuration

@property (nonatomic, assign) BOOL isCollectionViewLayoutFixedSpace;
@property (nonatomic, assign) BOOL shouldStickerBottomBarCollectionViewCellShowTitle;
@property (nonatomic, assign) BOOL isStickerBottomBarCollectionViewCellSizeFixed;

// sticker cell image

@property (nonatomic, assign) UIEdgeInsets stickerCollectionViewCellInsets;

@property (nonatomic, assign) UIViewContentMode stickerCollectionViewCellImageContentMode;

@end

NS_ASSUME_NONNULL_END
