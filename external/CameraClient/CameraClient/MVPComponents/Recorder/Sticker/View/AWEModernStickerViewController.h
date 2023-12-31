//
//  AWEModernStickerViewController.h
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/4/13.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWEStudioBaseViewController.h"
#import "AWEStickerPickerDelegate.h"
#import "AWEModernStickerSwitchTabView.h"
#import <CreationKitArch/AWECameraContainerToolButtonWrapView.h>

#import <TTVideoEditor/VERecorder.h>
#import "ACCPropSelection.h"
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CreativeKit/ACCPanelViewProtocol.h>

FOUNDATION_EXPORT void * const ACCRecordStickerPanelContext;

@class IESEffectModel;
@class AWEStickerDataManager;
@class ACCAnimatedButton;
@class IESMMCamera;
@class AWEVideoPublishViewModel;
@class AWEVideoBGStickerManager;
@class AWEModernStickerCollectionViewCell;
@protocol ACCMusicModelProtocol;

NS_ASSUME_NONNULL_BEGIN

@protocol AWEModernStickerViewControllerDelegate <NSObject>

@required
- (void)modernStickerViewControllerDidShow;
- (void)modernStickerViewControllerTappedCameraButton:(UIButton *)cameraButton;
- (void)stickerHintViewShowWithEffect:(IESEffectModel *)effect;
- (void)stickerHintViewRemove;
- (id<ACCCameraService>)cameraService;

@optional
- (AWEVideoPublishViewModel *)providedPublishModel;
- (void)modernStickerViewControllerDidSelectTabAtIndex:(NSInteger)index;
- (void)modernStickerViewControllerDidTapToChangeTabAtIndex:(NSInteger)index;
- (void)modernStickerViewControllerDidChangeSelection:(ACCPropSelection *)selection;
- (BOOL)modernStickerViewControllerShouldApplyEffect:(nullable IESEffectModel *)effect errorToast:(NSString * _Nullable *)error;
- (void)requestRecommendedMusicListForPropWithEffect:(IESEffectModel *)effect creationID:(NSString *)createId;

@end

@interface AWEModernStickerViewController : AWEStudioBaseViewController <AWEModernStickerPicker, ACCPanelViewProtocol>

@property (nonatomic, assign) BOOL isKaraokeAudioMode;
@property (nonatomic, assign) BOOL isPhotoMode;
@property (nonatomic, assign) BOOL isShowing;
@property (nonatomic, assign, readonly) BOOL hasShownBefore;
@property (nonatomic, copy) void(^externalDismissBlock)(void);
@property (nonatomic, copy) AWEModernRecordStickerVCDismissBlock dismissBlock;
@property (nonatomic, weak) id<AWEModernStickerPickerDelegate> delegate;
@property (nonatomic, weak) id<AWEModernStickerViewControllerDelegate> actionDelegate;
@property (nonatomic, copy) NSDictionary *trackingInfoDictionary;
@property (nonatomic, copy) NSDictionary *schemaTrackParams;
@property (nonatomic, assign) BOOL isStoryMode;
@property (nonatomic, assign) BOOL needTrackEvent;
@property (nonatomic, copy) NSString *createId;
@property (nonatomic, assign) NSInteger pixaLoopImageSourceMark; //图片变视频的照片来源，0：单击屏幕拍照，1:直接点道具面板照片，2:相册选择
@property (nonatomic, strong) AWEVideoBGStickerManager* videoBGStickerManager;
@property (nonatomic, copy) void (^pickStickerMusicBlock)(id<ACCMusicModelProtocol> musicModel, NSURL *musicUrl, NSError *musicError, BOOL isMusicForceBind);
@property (nonatomic, weak) UIView *loadingViewAnchorView;
@property (nonatomic, readonly, strong) UIView *stickerBackgroundView;
@property (nonatomic, copy) void (^cancelStickerMusicBlock)(IESEffectModel *cellEffect);
@property (nonatomic, strong, nullable) IESEffectModel *lastClickedEffectModel;
@property (nonatomic, strong) NSNumber *inputSelectCategoryIndex; // 外部传选中指定cate
@property (nonatomic, strong) void(^stickerViewDidRefreshCategories)(void); // category数据+UI都刷新完成的回调
@property (nonatomic, strong, readonly) IESEffectModel *selectedEffectModel;
@property (nonatomic, strong, readonly) IESEffectModel *selectedChildEffectModel;
@property (nonatomic, strong) IESEffectModel *effectToApply;
@property (nonatomic, strong) ACCPropSelection *propSelection;

- (instancetype)initWithDataManager:(AWEStickerDataManager *)dataManager;
- (void)prepareForShow;
- (void)performDidShowAction;
- (void)showOnViewController:(UIViewController *)controller;

- (void)stickerWillApplyAction;
- (void)sticker:(IESEffectModel *)sticker isCancel:(BOOL)isCancel appliedSuccess:(BOOL)success;
- (void)stickerClearAllEffect;

- (void)setSelectedSticker:(IESEffectModel *)model selectedChildSticker:(IESEffectModel *)childModel;

- (void)setSelectedSticker:(IESEffectModel *)model selectedComposerEffect:(id<AWEComposerEffectProtocol>)composerEffect;

- (void)switchCameraToFront:(BOOL)isFront;

// update collection view.
- (void)updateCollectionView;
- (void)updateSwapCameraButtonWithBlock:(void(^)(UIButton *, AWECameraContainerToolButtonWrapView *))updateBlock;
// reload data if needed and scroll to designated tab
- (void)refreshStickerViews;

- (NSInteger)selectedTabIndex;

- (NSIndexPath * _Nullable)selectedPropIndexPath;

- (AWEModernStickerSwitchTabView *)switchTabView;

- (IESEffectModel *)potentialChildEffectOfParentEffect:(IESEffectModel *)parentEffect;

// TC专用，Quick & Dirty
- (nullable AWEModernStickerCollectionViewCell *)cellForEffect:(NSString *)effectID;

@end

NS_ASSUME_NONNULL_END
