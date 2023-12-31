//
//  ACCRecordPropService.h
//  CameraClient
//
//  Created by zhangchengtao on 2020/12/14.
//

#import <Foundation/Foundation.h>
#import <CreationKitInfra/ACCModuleService.h>
#import <CreationKitArch/AWETimeRange.h>
#import "ACCPropRecommendMusicReponseModel.h"
#import "AWEStickerPicckerDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@class AWEStickerApplyHandlerContainer;
@class IESEffectModel, AWEVideoPublishViewModel;
@class ACCPropComponentV2;

FOUNDATION_EXPORT NSUInteger const ACCRecordPropPanelFlower;

@protocol ACCStickerApplyHandlerTemplate <NSObject>

- (NSArray<Class> *)handlerClasses:(ACCPropComponentV2 *)component;

@end

@protocol ACCMusicModelProtocol;

// 道具应用来源：
typedef NS_ENUM(NSInteger, ACCPropSource) {
    ACCPropSourceUnknown = 0, // 未知来源
    ACCPropSourceClassic,     // 普通道具面板（默认）classic
    ACCPropSourceCollection,  // 合集（关联）小面板 collection
    ACCPropSourceLocalProp,   // 拍同款（扫码等）localProp
    ACCPropSourceExposed,     // 道具外露 exposed
    ACCPropSourceReset,       // 切换mv、文字或直播重置 reset (被动重置), 以及多段道具不支持快拍的时候切快拍也会重置
    ACCPropSourceKeepWhenEdit, // 进编辑页重置，从编辑页返回恢复
    ACCPropSourceRecognition, // 识别逻辑
    ACCPropSourceLiteTheme, // 极速版红包主题
    ACCPropSourceFlower, // 春节道具外露面板
};

typedef NS_ENUM(NSInteger, ACCRecordPropChangeReason) {
    ACCRecordPropChangeReasonUnkwon = 0,
    ACCRecordPropChangeReasonOuter,
    ACCRecordPropChangeReasonUserSelect,
    ACCRecordPropChangeReasonUserSelectColletion,
    ACCRecordPropChangeReasonAutoSuggestion,
    ACCRecordPropChangeReasonUserCancel,
    ACCRecordPropChangeReasonKaraokeCancel,
    ACCRecordPropChangeReasonSwitchMode,
    ACCRecordPropChangeReasonRedpacketIntercept,
    ACCRecordPropChangeReasonMultiSegCancel,
    ACCRecordPropChangeReasonDuetPluginByUser,
    ACCRecordPropChangeReasonExitGame,
    ACCRecordPropChangeReasonThemeRecord,
    ACCRecordPropChangeReasonScanCancel,
    ACCRecordPropChangeReasonEnterRecognition
};

@protocol ACCRecordPropServiceSubscriber <NSObject>

@optional

/// 是否应该应用道具
- (BOOL)propServiceShouldApplyProp:(IESEffectModel * _Nullable)prop propSource:(ACCPropSource)propSource propIndexPath:(NSIndexPath * _Nullable)propIndexPath;

/// 即将应用道具到 camera
- (void)propServiceWillApplyProp:(IESEffectModel * _Nullable)prop propSource:(ACCPropSource)propSource;
- (void)propServiceWillApplyProp:(IESEffectModel * _Nullable)prop propSource:(ACCPropSource)propSource changeReason:(ACCRecordPropChangeReason)changeReason;

/// 已经应用道具到 camera，success 表示是否应用成功
- (void)propServiceDidApplyProp:(IESEffectModel * _Nullable)prop success:(BOOL)success;

/// 已经选择（或取消）道具强绑定音乐
- (void)propServiceDidSelectForceBindingMusic:(id<ACCMusicModelProtocol> _Nullable)music oldMusic:(id<ACCMusicModelProtocol> _Nullable)oldMusic;

/// 已经选择背景照片（单图）
- (void)propServiceDidSelectBgPhoto:(UIImage * _Nullable)bgPhoto photoSource:(NSString * _Nullable)photoSource;

/// Selected Background Photo (Multi-asset)
- (void)propServiceDidSelectBgPhotos:(NSArray<UIImage *> * _Nullable)bgPhotos;

/// 已经选择背景视频
- (void)propServiceDidSelectBgVideo:(NSURL * _Nullable)bgVideoURL videoSource:(NSString * _Nullable)videoSource;

/// 道具推荐音乐列表拉取成功回调
- (void)propServiceDidFinishFetchRecommendMusicListForPropID:(NSString *)propID;

/// 进入道具游戏模式
- (void)propServiceDidEnterGameMode;

/// 退出游戏道具模式
- (void)propServiceDidExitGameMode;

- (void)propServiceDidChangePropPickerDataSource:(AWEStickerPicckerDataSource *)dataSource;

- (void)propServiceDidChangePropPickerModel:(AWEStickerPickerModel *)model;

- (void)propServiceDidShowPanel:(UIView *)panel;

- (void)propServiceDidDismissPanel:(UIView *)panel;

/// 资源后置加载 面板强插道具至热门前排
- (void)propServiceRearDidSelectedInsertProps:(NSArray<IESEffectModel *> * _Nullable)effects;
- (void)propServiceRearFinishedDownloadProp:(IESEffectModel *_Nullable)effect parentProp:(IESEffectModel *_Nullable)parentEffect;

@end

@protocol ACCRecordPropService <NSObject>

/// repository
@property (nonatomic, readonly) AWEVideoPublishViewModel *repository;

/// 当前道具
@property (nonatomic, strong, nullable) IESEffectModel *prop;
/// 道具来源
@property (nonatomic, assign, readonly) ACCPropSource propSource;
/// 道具所在位置(根据来源使用)
@property (nonatomic, strong, readonly, nullable) NSIndexPath *propIndexPath;

/// prop 提示是否显示
@property (nonatomic, assign) BOOL isStickerHintViewShowing;

/// 绿幕背景照片
@property (nonatomic, strong, readonly, nullable) UIImage *bgPhoto;

/// 绿幕背景照片（多图）
@property (nonatomic, strong, readonly, nullable) NSArray<UIImage *> *bgPhotos;

@property (nonatomic, strong) AWEStickerPickerController *propPickerViewController;
@property (nonatomic, weak) AWEStickerApplyHandlerContainer *propApplyHanderContainer;
@property (nonatomic, strong) AWEStickerPicckerDataSource *propPickerDataSource;

/// 是否为自动应用的热门道具
@property (nonatomic, assign) BOOL isAutoUseProp;

/// 道具面板当前选中的分类的key和名称，埋点使用
@property (nonatomic, copy, nullable) NSString *categoryKey;
@property (nonatomic, copy, nullable) NSString *categoryName;
@property (nonatomic, assign, getter=isFavorite) BOOL favorite;

- (void)didShowPropPanel:(UIView *)propPanel;
- (void)didDismissPropPanel:(UIView *)propPanel;

/// 应用道具
- (void)applyProp:(IESEffectModel * _Nullable)prop propSource:(ACCPropSource)propSource;
- (void)applyProp:(IESEffectModel * _Nullable)prop propSource:(ACCPropSource)propSource propIndexPath:(NSIndexPath * _Nullable)propIndexPath;

- (void)applyProp:(IESEffectModel * _Nullable)prop propSource:(ACCPropSource)propSource byReason:(ACCRecordPropChangeReason)byReason;
- (void)applyProp:(IESEffectModel * _Nullable)prop propSource:(ACCPropSource)propSource propIndexPath:(NSIndexPath * _Nullable)propIndexPath byReason:(ACCRecordPropChangeReason)byReason;

/// 渲染背景照片
- (void)renderPic:(UIImage * _Nullable)photo forKey:(NSString *)key;
- (void)renderPic:(UIImage * _Nullable)photo forKey:(NSString *)key photoSource:(NSString * _Nullable)photoSource;

/**
 * @brief Render multiple images for pixaloop type prop.
 * @param photos    When applying images to the Effect layer, `photos` should contain instances of UIImage. When cancelling previouly rendered images, `photos` should contain instances of `NSNull`.
 */
- (void)renderPics:(NSArray * _Nullable)photos forKeys:(NSArray<NSString *> *)keys;

/// 渲染背景视频
- (void)setBgVideoWithURL:(NSURL * _Nullable)bgVideoURL;
- (void)setBgVideoWithURL:(NSURL * _Nullable)bgVideoURL videoSource:(NSString * _Nullable)videoSource;

- (void)addSubscriber:(id<ACCRecordPropServiceSubscriber>)subscriber;

- (BOOL)shouldStartAudio;
- (BOOL)shouldStopAudioCaptureWhenPause;
/// 是否已选中音乐
- (BOOL)isMusicSelected;
- (id<ACCMusicModelProtocol>)currentMusic;
/// 设置强绑定音乐 // TODO: 等 musicService 重构完成，移动到 musicService 更合适
- (void)setMusic:(id<ACCMusicModelProtocol> _Nullable)music;

/// 道具推荐音乐列表
- (void)setRecommendMusicList:(ACCPropRecommendMusicReponseModel *)recommendMusicList forPropID:(NSString *)propID;
- (nullable ACCPropRecommendMusicReponseModel *)recommemdMusicListForPropID:(NSString *)propID;

/// 设置或获取道具绑定挑战信息
- (nullable NSString *)hashTagNameForHashTagID:(NSString *)hashTagID;
- (void)setHashTagName:(NSString *)hashTagName forHashTagID:(NSString *)hashTagID;

/// 是否应该使用强绑定音乐
- (BOOL)shouldPickForceBindMusic;

- (BOOL)isDuet;
- (BOOL)isReshoot;

/// activityTimerange
- (void)addActivityTimeRange:(AWETimeRange *)activityTimeRange;
- (void)removeActivityTimeRange:(AWETimeRange *)activityTimeRange;
- (nullable NSArray<AWETimeRange *> *)activityTimeRanges;
- (void)removeAllActivityTimeRanges;

/// Game
- (void)enterGameMode;
- (void)exitGameMode;

/// Track
- (nullable NSDictionary *)trackReferExtra;
- (NSString *)createId;
- (NSString *)referString;

/// 资源后置 面板强插道具至热门前排
- (void)rearInsertAtHotTabWithProps:(NSArray<IESEffectModel *> * _Nullable)effects;
- (void)rearFinishedDownloadProp:(IESEffectModel *_Nullable)effect parentProp:(IESEffectModel *_Nullable)parentEffect;

@end

NS_ASSUME_NONNULL_END
