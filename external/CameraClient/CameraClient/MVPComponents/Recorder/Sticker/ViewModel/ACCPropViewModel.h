//
//  ACCPropViewModel.h
//  CameraClient
//
//  Created by chengfei xiao on 2020/4/7.
//

#import <Foundation/Foundation.h>
#import <EffectPlatformSDK/IESEffectModel.h>
#import <CreationKitArch/ACCRecorderViewModel.h>
#import <CreationKitInfra/ACCRACWrapper.h>
#import "AWEStickerFeatureManager.h"
#import <CreationKitArch/ACCStudioDefines.h>
#import <CreationKitArch/AWETimeRange.h>
#import "ACCPropSelection.h"
#import <CreationKitArch/ACCRepoDuetModel.h>

@class ACCGroupedPredicate<T, O>;

NS_ASSUME_NONNULL_BEGIN

//effct apply
typedef RACTwoTuple<IESEffectModel *, IESEffectModel *> *ACCRecordSelectEffectPack;
typedef RACTwoTuple<IESEffectModel *, NSNumber *> *ACCDidApplyEffectPack;

@protocol ACCEffectApplyProvideProtocol <NSObject>
@property (nonatomic, strong, readonly) RACSignal *willApplyStickerSignal;
@property (nonatomic, strong, readonly) RACSignal *didApplyLocalStickerSignal;
@property (nonatomic, strong, readonly) RACSignal *shouldUpdatePickerStickerSignal;
@property (nonatomic, strong, readonly) RACSignal *applyStickerSignal;
@property (nonatomic, strong, readonly) RACSignal <ACCDidApplyEffectPack> *didApplyStickerSignal;
@property (nonatomic, strong, readonly) RACSignal <ACCRecordSelectEffectPack> *didSetCurrentStickerSignal;
//hold value when mount
@property (nonatomic, strong, readonly) IESEffectModel *effectWillApply;
@property (nonatomic, strong, readonly) IESEffectModel *appliedLocalEffect;
@property (nonatomic, strong, readonly) ACCDidApplyEffectPack didApplyEffectPack;
@property (nonatomic, strong, readonly) ACCRecordSelectEffectPack currentSelectEffectPack;

// only for downloaded sticker apply
- (void)sendSignal_applySticker:(IESEffectModel * _Nullable)sticker;

// for prop picker component update
- (void)sendSignal_shouldUpdatePickerSticker:(IESEffectModel * _Nullable)sticker;
- (void)sendSignal_willApplySticker:(IESEffectModel * _Nullable)sticker;
- (void)sendSignal_didApplyLocalSticker:(IESEffectModel * _Nullable)sticker;
- (void)sendSignal_didApplySticker:(IESEffectModel * _Nullable)sticker success:(BOOL)success;
- (void)sendSignal_didSetCurrentSticker:(IESEffectModel * _Nullable)sticker oldSticker:(IESEffectModel * _Nullable)oldSticker;

@end

//prop panel
typedef NS_ENUM(NSUInteger, ACCPropPanelDisplayStatus) {
    ACCPropPanelDisplayStatusNone = 0,
    ACCPropPanelDisplayStatusDismiss,
    ACCPropPanelDisplayStatusShow
};

@protocol ACCPropPanelProvideProtocol <NSObject>
@property (nonatomic, strong, readonly) RACSignal *panelDisplayStatusSignal;
@property (nonatomic, strong, readonly) RACSignal *selectTabSignal;
@property (nonatomic, strong, readonly) RACSignal *changeTabSignal;
@property (nonatomic, strong, readonly) RACSignal *didFinishLoadEffectListSignal;

- (void)sendSignal_propPanelDisplayStatus:(ACCPropPanelDisplayStatus)status;
- (void)sendSignal_propPanelDidSelectTabAtIndex:(NSInteger)index;
- (void)sendSignal_propPanelDidTapToChangeTabAtIndex:(NSInteger)index;
- (void)sendSignal_didFinishLoadEffectListWithFirstHotSticker:(IESEffectModel *)sticker;

@end

//music
typedef RACThreeTuple<id<ACCMusicModelProtocol>, NSNumber *, NSError *> *ACCPickForceBindMusicPack;

@protocol ACCEffectMusicProvideProtocol <NSObject>
@property (nonatomic, strong, readonly) RACSignal<ACCPickForceBindMusicPack> *pickForceBindMusicSignal;
@property (nonatomic, strong, readonly) RACSignal *cancelForceBindMusicSignal;
//hold value when mount
@property (nonatomic, strong, readonly) ACCPickForceBindMusicPack pickForceBindMusicPack;
//for bubble
@property (nonatomic, assign) AWEForceBindMusicBubbleStatus musicBubbleStatus;
@property (nonatomic, strong) NSString *lastAppliedStickerIdentifier;

- (void)sendSignal_didPickForceBindMusic:(id<ACCMusicModelProtocol> _Nullable)musicModel isForceBind:(BOOL)isForceBind error:(NSError * _Nullable)musicError;
- (void)sendSignal_didCancelForceBindMusic:(id<ACCMusicModelProtocol> _Nullable)musicModel;
@end



@protocol ACCEffectProvideProtocol <ACCEffectApplyProvideProtocol,ACCPropPanelProvideProtocol,ACCEffectMusicProvideProtocol>

@property (nonatomic, copy, readonly) AWEStickerDataManager * stickerDataManager;
@property (nonatomic, copy, readonly) AWEStickerFeatureManager * stickerFeatureManager;
@property (nonatomic, copy, readonly) IESEffectModel * currentSticker;

/// Current selected sticker, may be downloading
@property (nonatomic, strong, nullable, readonly) IESEffectModel * lastClickedEffectModel;
@property (nonatomic, strong) IESEffectModel *currentApplyCompleteSticker;

- (void)setCurrentSticker:(IESEffectModel * _Nullable)currentSticker;

@end

@class ACCStickerGroupedApplyPredicate;

@protocol ACCPropPredicate <NSObject>

@property (nonatomic, strong, readonly) ACCStickerGroupedApplyPredicate *groupedPredicate;

@property (nonatomic, strong, readonly) ACCGroupedPredicate<IESEffectModel *, NSNumber *> *isSpecialPropForVideoGuide;
@property (nonatomic, strong, readonly) ACCGroupedPredicate<IESEffectModel *, id> *shouldFilterProp;
@property (nonatomic, assign, readonly) BOOL shouldFilterStickePickerCallback;

@end

@interface ACCPropViewModel : ACCRecorderViewModel <ACCEffectProvideProtocol, ACCPropPredicate>

@property (nonatomic, strong, readonly) NSMutableArray<AWETimeRange *> *activityTimerange;
@property (nonatomic, strong, readonly) RACSignal *swapCameraForStickerSignal;
@property (nonatomic, strong, readonly) RACSignal<ACCPropSelection *> *propSelectionSignal;
@property (nonatomic, strong, readonly) ACCPropSelection *propSelection;
@property (nonatomic, strong, readonly) RACSignal *applyLocalStickerSignal;
@property (nonatomic, assign, readonly) ACCPropPanelDisplayStatus propPanelStatus;

//hold value when mount
@property (nonatomic, strong, readonly) void (^swapCameraBlock)(void);

@property (nonatomic, copy, nullable) NSString *currentCategoryKey;

- (void)sendSignal_swapCameraForSticker:(void (^)(void))disableBlock;

- (void)updatePropSelection:(ACCPropSelection *)selection;
- (void)updateLastClickedEffectModel:(nullable IESEffectModel *)effectModel;
- (NSInteger)currentDateInteger;

- (void)resetStickerWithStickerID:(NSString * _Nullable)stickerID forCategory:(IESCategoryModel * _Nullable)category;

- (void)insertStickers:(NSArray<IESEffectModel *> * _Nullable)insertStickers forCategory:(IESCategoryModel * _Nullable)category;

#pragma mark - Tracker

- (void)updateTrackInfo:(NSDictionary *)dict;

- (void)trackCommerceStickerExperienceDuration:(NSTimeInterval)duration;

- (void)trackCommerceStickerInfo;

/// 移除道具特效上报
- (void)trackClickRemovePropTab;

/// 道具收藏上报
- (void)trackPropSaveWithEffectIdentifier:(NSString *)effectIdentifier;
- (void)applyLocalSticker:(IESEffectModel *)sticker;

#pragma mark - TC

- (BOOL)shouldShowGuide:(IESEffectModel *)effect;
- (void)updateShowGuideCount:(IESEffectModel *)effect;
- (void)trackGuideShowWithEffectId:(NSString *)effectId;
- (void)trackGuideSkipWithEffectId:(NSString *)effectId;

#pragma mark - new prop panel tracker

- (void)trackPropClickEventWithCameraService:(id<ACCCameraService>)cameraService
                                     sticker:(IESEffectModel *)sticker
                                categoryName:(NSString *)categoryName
                                 atIndexPath:(NSIndexPath *)indexPath
                                 isPhotoMode:(BOOL)isPhotoMode
                                 isThemeMode:(BOOL)isThemeMode
                            additionalParams:(NSMutableDictionary *)additionalParams;
- (void)trackPropShowEventWithSticker:(IESEffectModel *)sticker
                         categoryName:(NSString *)categoryName
                          atIndexPath:(NSIndexPath *)indexPath
                          isPhotoMode:(BOOL)isPhotoMode
                     additionalParams:(NSMutableDictionary *)additionalParams;
- (void)trackClickPropTabEventWithCategoryName:(NSString *)categoryName
                                         value:(NSString *)value
                                   isPhotoMode:(BOOL)isPhotoMode
                                   isThemeMode:(BOOL)isThemeMode;

- (void)trackWillApplySticker:(IESEffectModel *)sticker;
- (void)trackUserCancelUseSticker;
- (void)trackUserDidTapSticker:(IESEffectModel *)sticker;
- (void)trackDidFailedDownloadSticker:(IESEffectModel *)sticker withError:(NSError *)error;
- (void)trackDownloadPerformanceWithSticker:(IESEffectModel *)sticker
                                  startTime:(CFTimeInterval)startTime
                                    success:(BOOL)success
                                      error:(NSError * _Nullable)error;
- (void)trackStickerPanelLoadPerformanceWithStatus:(NSInteger)status
                                         isLoading:(BOOL)isLoading
                                   dismissTrackStr:(NSString * _Nullable)dismissTrackStr;
- (void)trackToolPerformanceAPIWithType:(NSString *)type
                               duration:(CFTimeInterval)duration
                                  error:(NSError * _Nullable)error;
- (void)trackSearchWithEventName:(NSString *)eventName
                          params:(NSMutableDictionary *)params;
- (void)trackComfirmPropSettingEvent;
- (NSDictionary *)trackingInfoDictionary;

#pragma mark - new prop panel monitor

- (void)monitorStartStickerPanelLoadingDuration;
- (void)monitorCancelStickerPanelLoadingDuration;

- (void)monitorTrackServiceEffectListError:(NSError * _Nullable)error
                                 panelName:(NSString *)panelName
                                  duration:(NSNumber *)duration
                                needUpdate:(BOOL)needUpdate;

@end


NS_ASSUME_NONNULL_END
