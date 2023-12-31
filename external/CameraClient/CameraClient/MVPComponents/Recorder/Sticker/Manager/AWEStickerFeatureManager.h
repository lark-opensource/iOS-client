//
//  AWEStickerFeatureManager.h
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/3/26.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AWEStickerPickerDelegate.h"
#import <TTVideoEditor/IESMMBaseDefine.h>
#import "AWEModernStickerViewController.h"
#import "AWEVideoBGStickerManager.h"

@class IESMMRecoder;
@class IESEffectModel;
@class AWEModernStickerViewController;
@class AWEStickerDataManager;
@protocol AWEStickerPickerDelegate;

typedef void(^AWEStickerFeatureWillApplyStickerCompleteBlock)(void);
typedef void(^AWEStickerFeatureApplyStickerCompletionBlock)(BOOL success, IESEffectModel *sticker, NSString *resName);
typedef void(^AWEStickerFeatureWillApplyStickerBlock)(IESEffectModel *sticker, AWEStickerFeatureWillApplyStickerCompleteBlock complete);
typedef void(^AWEStickerFeatureStickerLoadStatusBlock)(IESStickerStatus status, IESEffectModel *sticker);

@protocol AWEStickerFeatureDelegate

@optional
- (UIViewController *)containerViewController;
- (void)showPhotoSensitiveAlertWithSticker:(IESEffectModel *)effectModel;
- (BOOL)isLocalSticker:(IESEffectModel *)effectModel;

@end


@interface AWEStickerFeatureManager : NSObject <AWEModernStickerPickerDelegate>

@property (nonatomic, weak) NSObject<AWEStickerFeatureDelegate> *delegate;
@property (nonatomic, assign) BOOL isPhotoMode;
@property (nonatomic, assign) BOOL isStoryMode;
@property (nonatomic, strong) AWEStickerDataManager *stickerDataManager;
@property (nonatomic, copy) NSDictionary *trackingInfoDictionary;
@property (nonatomic, copy) NSDictionary *schemaTrackParams;
@property (nonatomic, strong, readonly) AWEModernStickerViewController *stickerController;
@property (nonatomic, assign) BOOL needTrackEvent;

/**
 注意：applyStickerCompletionBlock 是在主线程进行调用的
 */
@property (nonatomic, copy) AWEStickerFeatureApplyStickerCompletionBlock applyStickerCompletionBlock;

/**
 willapplyStickerBlock 是在主线程进行调用的
 */
@property (nonatomic, copy) AWEStickerFeatureWillApplyStickerBlock willapplyStickerBlock;

/**
 贴纸加载状态block，ve线程调用
 */
@property(nonatomic, copy) AWEStickerFeatureStickerLoadStatusBlock stickerStatusBlock;

- (instancetype)initWithPanelType:(AWEStickerPanelType)panelType;

- (void)setStickerFeatureDelegate:(NSObject<AWEStickerFeatureDelegate> *)delegate;
- (void)setStickerViewControllerDismissBlock:(void (^)(IESEffectModel *))dismissBlock;
- (void (^)(IESEffectModel *))getStickerViewControllerDismissBlock;
- (void)showStickerViewControllerWithBlock:(void(^)(void))block;
- (void)hideStickerViewController:(BOOL)hidden;
- (void)clearStickerAllEffect;
- (void)applySticker:(IESEffectModel *)item completion:(AWEApplyStickerCompletionBlock)completion;

- (void)didChooseImage:(UIImage *)image;

- (void)setIsShowingStickerController:(BOOL)isShowingStickerController;
- (void)setSelectedSticker:(IESEffectModel *)model selectedChildSticker:(IESEffectModel *)childModel;
- (void)switchCameraToFront:(BOOL)isFront;

- (void)updateModernStickerViewController;

//performance track
- (void)trackEffectApplyToRecognize:(NSDictionary *)commonParams;
- (void)invalidatePhotoSensitiveTimer;

@end
