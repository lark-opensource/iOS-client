//
//  AWEVideoEffectChooseViewModel.h
//  CameraClient-Pods-Aweme
//
//  Created by xulei on 2020/2/6.
//

#import <Foundation/Foundation.h>
// in order to use AWEVideoEffectViewDelegate
#import "AWEVideoEffectView.h"
// in order to use AWEEffectMixTimeBarDelegate
#import "AWEVideoEffectMixTimeBar.h"
#import <CreationKitArch/ACCChallengeModelProtocol.h>
#import "AWEEffectDataManager.h"
#import "ACCEditVideoData.h"

NS_ASSUME_NONNULL_BEGIN

extern const CGFloat kAWEVideoEffectMixTimeBarHeight;

@protocol AWEVideoEffectChooseViewModelDelegate <NSObject>
@required
@property (nonatomic, strong, nullable) IESMMEffectTimeRange *currentEffectTimeRange;//record current filter Effect

@optional
- (void)clickedTabViewWithCategoryKey:(NSString *)categoryKey isTimeTab:(BOOL)isTimeTab;
- (void)switchToTimeMachineType:(HTSPlayerTimeMachineType)type withBeginTime:(NSTimeInterval)beginTime duration:(NSTimeInterval)duration animation:(BOOL)animation;

- (void)setIsPlaying:(BOOL)isPlaying;
- (void)didClickStopAndPlay;

- (void)p_startApplyToolEffect:(NSString *)stickerID;
- (void)p_stopToolEffectLoadingIfNeeded;

- (void)refreshEffectFragments;
- (void)refreshRevokeButton;
- (void)refreshMovingView:(CGFloat)lastTime;

- (void)refreshBarWithImageArray:(NSArray<UIImage *> *)imageArray;
- (void)updateShowingToolEffectRangeViewIfNeededWithCategoryKey:(NSString *)categoryKey effectSelected:(BOOL)selected;
- (CGFloat)getPlayControlViewProgress;
@end

@class AWEVideoPublishViewModel,IESCategoryModel,AWEVideoImageGenerator;

@protocol ACCEditServiceProtocol;

@interface AWEVideoEffectChooseViewModel : NSObject<AWEVideoEffectMixTimeBarDelegate, AWEVideoEffectViewDelegate>

@property (nonatomic, weak) id<AWEVideoEffectChooseViewModelDelegate> delegate;

@property (nonatomic, strong) id<ACCEditServiceProtocol> editService;

@property (nonatomic, strong) AWEVideoPublishViewModel *publishViewModel;

@property (nonatomic, copy) NSArray<IESCategoryModel *> *effectCategories;

@property (nonatomic, strong) IESMMEffectTimeRange *timeEffectTimeRange;
@property (nonatomic, assign) NSTimeInterval timeEffectDefaultDuration;
@property (nonatomic, assign) NSTimeInterval timeEffectDefaultBeginTime;

@property (nonatomic, strong) ACCEditVideoData *originVideoData;
@property (nonatomic, copy) NSArray *originDisplayTimeRanges;
@property (nonatomic, copy) NSString *originalRangeIds;

@property (nonatomic, assign) BOOL isPlaying;

@property (nonatomic, assign) AWEVideoEffectViewType currentEffectViewType;

@property (nonatomic, assign) BOOL containLyricSticker;

- (instancetype)initWithModel:(AWEVideoPublishViewModel *)model editService:(id<ACCEditServiceProtocol>)editService;

- (void)clickedTabViewAtIndex:(NSInteger)tabNum;

- (void)configPlayerWithCompletionBlock:(void (^)(void))mixPlayerCompleteBlock;

- (void)loadFirstPreviewFrameWithCompletion:(void (^)(NSMutableArray *imageArray))refreshBlock;
- (void)mapEffectIdForCategoryAndColorDict;
- (BOOL)checkEffectIsDownloaded:(IESEffectModel *)effect;
- (NSString *)getStickerEffectIdInDisplayTimeRanges;
- (BOOL)p_isStickerCategory:(NSString *)categoryKey;
- (NSMutableString *)getRangeIdsFromTimeRangeArray:(NSArray<IESMMEffectTimeRange *> *)timeRanges;
- (BOOL)isRedPacketVideo;
- (BOOL)isMultiSegPropVideo;

//action
- (void)didClickCancelBtn;
- (void)didClickSaveBtn;

//get bottomTabView data
- (void)getBottomTabViewDataWithNetworkRequestBlock:(void (^)(void))networkRequestBlock showCacheBlock:(void (^)(NSArray *categoryArr))showCacheBlock;

//time effect methods
- (NSArray *)allTimeEffects;
- (void)resetTimeForbiddenStyle;
- (HTSVideoSepcialEffect *)timeEffectWithType:(HTSPlayerTimeMachineType)type;
- (UIColor *)timeEffectColorWithType:(HTSPlayerTimeMachineType)type;
- (NSString *)timeEffectDescriptionWithType:(HTSPlayerTimeMachineType)type;

//noram effect methods
- (AWEEffectFilterPathBlock)effectFilterPathBlock;
- (IESEffectModel *)normalEffectWithID:(NSString *)effectPathID;
- (NSArray<IESEffectModel *> *)builtinNormalEffects;
- (IESEffectPlatformResponseModel *)normalEffectPlatformModel;
- (NSArray <id<ACCChallengeModelProtocol>> *_Nullable)currentBindChallenges;
@end

NS_ASSUME_NONNULL_END
