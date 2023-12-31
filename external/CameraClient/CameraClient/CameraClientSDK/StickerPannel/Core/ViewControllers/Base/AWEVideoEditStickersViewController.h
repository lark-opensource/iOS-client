//
//  AWEVideoEditStickersViewController.h
//  AWEStudio
//
//  Created by guochenxiang on 2018/9/14.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACCStickerPannelLogger.h"
#import "ACCStickerPannelAnimationVC.h"
#import "ACCStickerPannelUIConfig.h"
#import "ACCStickerPannelDataConfig.h"

@class AWEModernVideoEditViewController, AWEVideoEditStickersViewController, IESEffectModel, IESThirdPartyStickerModel;
@protocol ACCStickerPannelFilter;

@protocol AWEVideoEditStickersVCDelegate <NSObject>

@optional

// will be deprecated, use stickerViewController:didSelectSticker:fromTab:downloadTrigger: instead.
- (void)videoEditStickersViewController:(AWEVideoEditStickersViewController *)videoEditStickersVC didSelectSticker:(IESEffectModel *)sticker fromTab:(NSString *)tabName downloadProgressBlock:(void(^)(CGFloat))downloadProgressBlock downloadedBlock:(void(^)(void))downloadedBlock;

- (void)stickerViewController:(AWEVideoEditStickersViewController *)videoEditStickersVC didSelectSticker:(IESEffectModel *)sticker fromTab:(NSString *)tabName downloadTrigger:(dispatch_block_t)downloadTrigger;

- (void)stickerViewController:(AWEVideoEditStickersViewController *)videoEditStickersVC didSelectThirdPartySticker:(IESThirdPartyStickerModel *)sticker fromTab:(NSString *)tabName downloadTrigger:(dispatch_block_t)downloadTrigger;

@end

@interface AWEVideoEditStickersViewController : ACCStickerPannelAnimationVC

@property (nonatomic, weak) id<AWEVideoEditStickersVCDelegate> delegate;
@property (nonatomic, strong) NSString *loadingStickerId;
@property (nonatomic, strong) ACCStickerPannelUIConfig *uiConfig;
@property (nonatomic, strong) ACCStickerPannelDataConfig *dataConfig;

@property (nonatomic, strong) id<ACCStickerPannelLogger> logger;
@property (nonatomic, strong) id<ACCStickerPannelFilter> pannelFilter;

@property (nonatomic, assign) BOOL enableEmojiSticker;

@end

