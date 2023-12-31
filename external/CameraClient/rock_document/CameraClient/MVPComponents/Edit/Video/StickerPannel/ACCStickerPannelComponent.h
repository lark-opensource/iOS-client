//
//  ACCStickerPannelComponent.h
//  Pods
//
//  Created by chengfei xiao on 2019/10/22.
//  贴纸面板

#import <CreativeKit/ACCFeatureComponent.h>

@class ACCAddInfoStickerContext, ACCStickerSelectionContext;

NS_ASSUME_NONNULL_BEGIN

@interface ACCStickerPannelComponent : ACCFeatureComponent

#pragma mark - SubComponent Visible

- (void)configPannelVC:(BOOL)show;
- (NSInteger)addSearchInfoSticker:(ACCAddInfoStickerContext *)context;
- (void)removeStickerPannelWithAlphaAnimated:(BOOL)animated selectedSticker:(nullable ACCStickerSelectionContext *)selectedSticker;
- (void)removeStickerPannelWithAlphaAnimated:(BOOL)animated;
- (void)showStickerPannelWithAlphaAnimated:(BOOL)alphaAnimated;

@end

NS_ASSUME_NONNULL_END
