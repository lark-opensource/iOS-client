//
//  ACCVideoEditStickerSinglePannelVCViewController.h
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/8/18.
//

#import <UIKit/UIKit.h>
#import "ACCStickerPannelUIConfig.h"
#import "ACCStickerPannelAnimationVC.h"
#import "ACCStickerPannelLogger.h"

NS_ASSUME_NONNULL_BEGIN

@class ACCVideoEditStickerSinglePannelVC;
@class IESEffectModel;

@protocol ACCStickerPannelDataDelegate <NSObject>

- (void)stickerPannelVC:(ACCVideoEditStickerSinglePannelVC *)pannelVC didSelectSticker:(IESEffectModel *)sticker downloadTrigger:(nullable dispatch_block_t)downloadTrigger;

@end

@interface ACCVideoEditStickerSinglePannelVC : ACCStickerPannelAnimationVC

@property (nonatomic, weak) id<ACCStickerPannelDataDelegate> delegate;
@property (nonatomic, strong) id<ACCStickerPannelLogger> logger;

// ui config
@property (nonatomic, strong) ACCStickerPannelUIConfig *uiConfig;

// data config
@property (nonatomic, copy) NSString *pannelName;
@property (nonatomic, assign) BOOL enablePagination; // default yes
@property (nonatomic, assign) NSInteger pageItemCount;

@end

NS_ASSUME_NONNULL_END
