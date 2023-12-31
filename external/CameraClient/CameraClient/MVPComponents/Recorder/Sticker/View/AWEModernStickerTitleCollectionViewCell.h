//
//  AWEModernStickerTitleCollectionViewCell.h
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/4/15.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWEStudioBaseCollectionViewCell.h"
#import <CreationKitInfra/AWEModernStickerDefine.h>
@class IESCategoryModel;
@class AWEModernStickerTitleCellViewModel;

@interface AWEModernStickerTitleCollectionViewCell : AWEStudioBaseCollectionViewCell

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, assign) AWEStickerPanelType panelType;
@property (nonatomic, assign) BOOL ignoreSetSelected;

/// 计算特效分类 tab 的布局信息
/// @param height cell 高度
/// @param title tab 文案
/// @param image tab 图片
/// @param completion 计算结果回调
+ (void)categoryFrameWithContainerHeight:(CGFloat)height
                                   title:(NSString *)title
                                   image:(UIImage *)image
                              completion:(void(^)(CGSize cellSize, CGRect titleFrame, CGRect imageFrame))completion;

/// 计算收藏tab 的布局信息
+ (void)favoirteFrameWithContainerHeight:(CGFloat)height
                              completion:(void(^)(CGSize cellSize, CGRect titleFrame, CGRect imageFrame))completion;

- (void)bindViewModel:(AWEModernStickerTitleCellViewModel *)viewModel;

//- (void)configWithCategoryModel:(IESCategoryModel *)categoryModel;
- (void)showYellowDotAnimated:(BOOL)animated;
- (void)playTitleAnimationWithYellowDotShow:(BOOL)showYellowDot;
- (void)playImageAnimationWithYellowDotShow:(BOOL)showYellowDot;

@end
