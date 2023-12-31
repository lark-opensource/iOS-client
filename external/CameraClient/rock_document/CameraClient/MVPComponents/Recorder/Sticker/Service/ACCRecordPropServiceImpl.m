//
//  ACCRecordPropServiceImpl.m
//  CameraClient
//
//  Created by zhangchengtao on 2020/12/14.
//

#import "AWERepoPropModel.h"
#import "ACCRecordPropServiceImpl.h"

#import <CreativeKit/NSArray+ACCAdditions.h>

#import <CreationKitRTProtocol/ACCCameraSubscription.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import "ACCRecordFrameSamplingServiceProtocol.h"
#import "ACCAudioAuthUtils.h"
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CreationKitArch/ACCRepoReshootModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitArch/ACCRepoVideoInfoModel.h>
#import <CreationKitArch/ACCRepoGameModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import "AWEStickerApplyHandlerContainer.h"

NSUInteger const ACCRecordPropPanelFlower = 0x2021;

@interface ACCRecordPropServiceImpl ()

@property (nonatomic, strong) ACCCameraSubscription *subscription;

@property (nonatomic, strong) NSMutableDictionary<NSString *, IESEffectModel *> *propMap;

@property (nonatomic, copy) IESStickerStatusBlock stickerStatusBlock;

@property (nonatomic, strong, nullable) id<ACCMusicModelProtocol> forceBindingMusic;

/// 存储道具推荐音乐列表
@property (nonatomic, strong) NSMutableDictionary<NSString *, ACCPropRecommendMusicReponseModel *> *recommendMusicList;

@property (nonatomic, strong) NSMutableArray<AWETimeRange *> *timeRanges;

@end

@implementation ACCRecordPropServiceImpl
@synthesize propPickerViewController = _propPickerViewController;
@synthesize propApplyHanderContainer = _propApplyHanderContainer;
@synthesize propPickerDataSource = _propPickerDataSource;

- (instancetype)init
{
    if (self = [super init]) {
        _propMap = [[NSMutableDictionary alloc] init];
        _recommendMusicList = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - ACCCameraSubscription

- (ACCCameraSubscription *)subscription
{
    if (!_subscription) {
        _subscription = [[ACCCameraSubscription alloc] init];
    }
    return _subscription;
}

- (void)addSubscriber:(id<ACCRecordPropServiceSubscriber>)subscriber
{
    [self.subscription addSubscriber:subscriber];
}

#pragma mark - Private

- (void)p_setupStickerStatusBlockIfNeeded {
    if (self.stickerStatusBlock) {
        return;
    }
    
    @weakify(self);
    self.stickerStatusBlock = ^(IESStickerStatus status, NSInteger stickerID, NSString * _Nullable resName) {
        @strongify(self);
        if (IESStickerStatusValid == status ||
            IESStickerStatusInvalid == status) {
            // 此回调在异步线程，需要dispatch到主线程执行。
            // status 为 IESStickerStatusValid 表示加载道具并应用成功。
            dispatch_async(dispatch_get_main_queue(), ^{
                @strongify(self);
                BOOL success = (status == IESStickerStatusValid);
                if (stickerID > 0 && resName.length > 0) {
                    // 根据 stickerID 查询到对应的 sticker
                    IESEffectModel *prop = self.propMap[@(stickerID).stringValue];
                    [self.subscription performEventSelector:@selector(propServiceDidApplyProp:success:) realPerformer:^(id<ACCRecordPropServiceSubscriber> subscriber) {
                        [subscriber propServiceDidApplyProp:prop success:success];
                    }];
                } else {
                    // 如果stickerID为0或者resName为空，表示camera取消应用道具。
                    [self.subscription performEventSelector:@selector(propServiceDidApplyProp:success:) realPerformer:^(id<ACCRecordPropServiceSubscriber> subscriber) {
                        [subscriber propServiceDidApplyProp:nil success:success];
                    }];
                }
            });
        }
    };
}

#pragma mark - Public

#pragma mark - Prop

- (void)didShowPropPanel:(UIView *)propPanel
{
    [self.subscription performEventSelector:@selector(propServiceDidShowPanel:) realPerformer:^(id<ACCRecordPropServiceSubscriber> subscriber) {
        [subscriber propServiceDidShowPanel:propPanel];
    }];
}

- (void)didDismissPropPanel:(UIView *)propPanel
{
    [self.subscription performEventSelector:@selector(propServiceDidDismissPanel:) realPerformer:^(id<ACCRecordPropServiceSubscriber> subscriber) {
        [subscriber propServiceDidDismissPanel:propPanel];
    }];
}

- (void)applyProp:(IESEffectModel *)prop
{
    [self applyProp:prop propSource:ACCPropSourceUnknown];
}

- (void)applyProp:(IESEffectModel *)prop propSource:(ACCPropSource)propSource
{
    [self applyProp:prop propSource:propSource propIndexPath:nil byReason:ACCRecordPropChangeReasonUnkwon];
}

- (void)applyProp:(IESEffectModel *)prop propSource:(ACCPropSource)propSource propIndexPath:(NSIndexPath * _Nullable)propIndexPath
{
    [self applyProp:prop propSource:propSource propIndexPath:propIndexPath byReason:ACCRecordPropChangeReasonUnkwon];
}

- (void)applyProp:(IESEffectModel *)prop byReason:(ACCRecordPropChangeReason)byReason
{
    [self applyProp:prop propSource:ACCPropSourceUnknown byReason:byReason];
}

- (void)applyProp:(IESEffectModel *)prop propSource:(ACCPropSource)propSource byReason:(ACCRecordPropChangeReason)byReason
{
    [self applyProp:prop propSource:propSource propIndexPath:nil byReason:byReason];
}

- (void)applyProp:(IESEffectModel *)prop propSource:(ACCPropSource)propSource propIndexPath:(NSIndexPath * _Nullable)propIndexPath byReason:(ACCRecordPropChangeReason)byReason
{
    // 问询是否可以应用道具
    __block BOOL shouldApply = YES;
    [self.subscription performEventSelector:@selector(propServiceShouldApplyProp:propSource:propIndexPath:) realPerformer:^(id<ACCRecordPropServiceSubscriber> subscriber) {
        if (![subscriber propServiceShouldApplyProp:prop propSource:propSource propIndexPath:propIndexPath]) {
            shouldApply = NO;
        }
    }];
    if (!shouldApply) {
        return;
    }
    
    self.prop = prop;
    
    self.propSource = propSource;
    self.propIndexPath = propIndexPath;
    
    // 应用道具前准备工作
    // 1. 记录道具id到 IESEffectModel 的映射，以便 stickerStatusBlock 回调可以根据id查询道具;
    if (prop && prop.effectIdentifier.length > 0) {
        self.propMap[prop.effectIdentifier] = prop;
    }
    // 2. 设置stickerStatusBlock。
    [self p_setupStickerStatusBlockIfNeeded];
    [self.cameraService.effect setEffectLoadStatusBlock:self.stickerStatusBlock];
    
    // Dispatch event that prop will apply.
    [self.subscription performEventSelector:@selector(propServiceWillApplyProp:propSource:changeReason:) realPerformer:^(id<ACCRecordPropServiceSubscriber> subscriber) {
        [subscriber propServiceWillApplyProp:prop propSource:propSource changeReason:byReason];
    }];
    [self.subscription performEventSelector:@selector(propServiceWillApplyProp:propSource:) realPerformer:^(id<ACCRecordPropServiceSubscriber> subscriber) {
        [subscriber propServiceWillApplyProp:prop propSource:propSource];
    }];
    if (prop == nil && (propSource == ACCPropSourceKeepWhenEdit || propSource == ACCPropSourceReset || propSource == ACCPropSourceLiteTheme)) {
        // clear prop recordenteredit
        [self.cameraService.effect acc_clearEffectRecordFinish]; 
    } else {
        // Actually apply the prop.
        [self.cameraService.effect acc_applyStickerEffect:prop];
    }
    
    [self.samplingService updateCurrentSticker:prop];
}

#pragma mark - BgPhoto

- (void)renderPic:(UIImage *)photo forKey:(NSString *)key
{
    [self renderPic:photo forKey:key photoSource:nil];
}

- (void)renderPic:(UIImage *)photo forKey:(NSString *)key photoSource:(NSString * _Nullable)photoSource
{
    [self.cameraService.effect renderPicImage:photo withKey:key];
    self.samplingService.bgPhoto = photo;
    
    [self.subscription performEventSelector:@selector(propServiceDidSelectBgPhoto:photoSource:) realPerformer:^(id<ACCRecordPropServiceSubscriber> subscriber) {
        [subscriber propServiceDidSelectBgPhoto:photo photoSource:photoSource];
    }];
}

- (void)renderPics:(NSArray *)photos forKeys:(NSArray<NSString *> *)keys
{
    [self.cameraService.effect renderPicImages:photos withKeys:keys];
    self.samplingService.bgPhotos = [photos acc_filter:^BOOL(id  _Nonnull item) {
        return [item isKindOfClass:[UIImage class]];
    }];
    [self.subscription performEventSelector:@selector(propServiceDidSelectBgPhotos:) realPerformer:^(id<ACCRecordPropServiceSubscriber> subscriber) {
        [subscriber propServiceDidSelectBgPhotos:photos];
    }];
}

- (void)setBgVideoWithURL:(NSURL *)bgVideoURL
{
    [self setBgVideoWithURL:bgVideoURL videoSource:nil];
}

- (void)setBgVideoWithURL:(NSURL *)bgVideoURL videoSource:(NSString * _Nullable)videoSource
{
    [self.subscription performEventSelector:@selector(propServiceDidSelectBgVideo:videoSource:) realPerformer:^(id<ACCRecordPropServiceSubscriber> subscriber) {
        [subscriber propServiceDidSelectBgVideo:bgVideoURL videoSource:videoSource];
    }];
}

- (UIImage *)bgPhoto
{
    return self.samplingService.bgPhoto;
}

- (NSArray<UIImage *> *)bgPhotos
{
    return self.samplingService.bgPhotos;
}

#pragma mark - Music

- (BOOL)shouldStartAudio
{
    return [ACCAudioAuthUtils shouldStartAudioCaptureWhenApplyProp:self.repository];
}

- (BOOL)shouldStopAudioCaptureWhenPause
{
    return [ACCAudioAuthUtils shouldStopAudioCaptureWhenPause:self.repository];
}

- (BOOL)isMusicSelected
{
    return self.repository.repoMusic.music != nil;
}

- (id<ACCMusicModelProtocol>)currentMusic
{
    return self.repository.repoMusic.music;
}

- (void)setMusic:(id<ACCMusicModelProtocol>)music
{
    id<ACCMusicModelProtocol> oldMusic = self.forceBindingMusic;
    self.forceBindingMusic = music;
    [self.subscription performEventSelector:@selector(propServiceDidSelectForceBindingMusic:oldMusic:) realPerformer:^(id<ACCRecordPropServiceSubscriber> subscriber) {
        [subscriber propServiceDidSelectForceBindingMusic:music oldMusic:oldMusic];
    }];
}

- (BOOL)shouldPickForceBindMusic
{
    if (self.repository.repoDuet.isDuet) {
        return NO;
    }
    
    if (self.repository.repoReshoot.isReshoot) {
        return NO;
    }
    
    ACCRepoMusicModel *music = self.repository.repoMusic;
    if (music.musicSelectFrom == AWERecordMusicSelectSourceOriginalVideo) { return NO; }
    if (music.musicSelectFrom == AWERecordMusicSelectSourceMusicSelectPage) { return NO; }
    if (music.musicSelectFrom == AWERecordMusicSelectSourceMusicDetail) { return NO; }
    if (music.musicSelectFrom == AWERecordMusicSelectSourceChallengeStrongBinded) { return NO; }
    if (music.musicSelectFrom == AWERecordMusicSelectSourceTaskStrongBinded) { return NO; }
    
    return YES;
}

#pragma mark - Recommend music list

- (void)setRecommendMusicList:(ACCPropRecommendMusicReponseModel *)recommendMusicList forPropID:(NSString *)propID
{
    if (recommendMusicList && propID.length > 0) {
        self.recommendMusicList[propID] = recommendMusicList;
        
        [self.subscription performEventSelector:@selector(propServiceDidFinishFetchRecommendMusicListForPropID:) realPerformer:^(id<ACCRecordPropServiceSubscriber> subscriber) {
            [subscriber propServiceDidFinishFetchRecommendMusicListForPropID:propID];
        }];
    }
}

- (ACCPropRecommendMusicReponseModel *)recommemdMusicListForPropID:(NSString *)propID
{
    if (propID) {
        return self.recommendMusicList[propID];
    }
    return nil;
}

#pragma mark - HashTag

- (NSString *)hashTagNameForHashTagID:(NSString *)hashTagID
{
    return self.repository.repoProp.cacheStickerChallengeNameDict[hashTagID];
}

- (void)setHashTagName:(NSString *)hashTagName forHashTagID:(NSString *)hashTagID
{
    self.repository.repoProp.cacheStickerChallengeNameDict[hashTagID] = hashTagName;
}

#pragma mark - Mode

- (BOOL)isDuet
{
    return self.repository.repoDuet.isDuet;
}

- (BOOL)isReshoot
{
    return self.repository.repoReshoot.isReshoot;
}

#pragma mark - ActivityTimeRanges

- (NSMutableArray<AWETimeRange *> *)timeRanges
{
    if (!_timeRanges) {
        _timeRanges = [[NSMutableArray alloc] init];
    }
    return _timeRanges;
}

- (void)addActivityTimeRange:(AWETimeRange *)activityTimeRange
{
    [self.timeRanges addObject:activityTimeRange];
}

- (void)removeActivityTimeRange:(AWETimeRange *)activityTimeRange
{
    [self.timeRanges removeObject:activityTimeRange];
}

- (nullable NSArray<AWETimeRange *> *)activityTimeRanges
{
    return [self.timeRanges copy];
}

- (void)removeAllActivityTimeRanges
{
    [self.timeRanges removeAllObjects];
}

#pragma mark - Game

- (void)enterGameMode
{
    self.repository.repoGame.gameType = ACCGameTypeEffectControlGame;
    
    [self.subscription performEventSelector:@selector(propServiceDidEnterGameMode) realPerformer:^(id<ACCRecordPropServiceSubscriber> subscriber) {
        [subscriber propServiceDidEnterGameMode];
    }];
}

- (void)exitGameMode
{
    self.repository.repoGame.gameType = ACCGameTypeNone;
    
    [self.subscription performEventSelector:@selector(propServiceDidExitGameMode) realPerformer:^(id<ACCRecordPropServiceSubscriber> subscriber) {
        [subscriber propServiceDidExitGameMode];
    }];
}

- (void)setPropPickerDataSource:(AWEStickerPicckerDataSource *)propPickerDataSource
{
    _propPickerDataSource = propPickerDataSource;
    [self.subscription performEventSelector:@selector(propServiceDidChangePropPickerDataSource:) realPerformer:^(id<ACCRecordPropServiceSubscriber> subscriber) {
        [subscriber propServiceDidChangePropPickerDataSource:propPickerDataSource];
    }];
}

- (void)setPropPickerViewController:(AWEStickerPickerController *)propPickerViewController
{
    _propPickerViewController = propPickerViewController;
    [self.subscription performEventSelector:@selector(propServiceDidChangePropPickerModel:) realPerformer:^(id<ACCRecordPropServiceSubscriber> subscriber) {
        [subscriber propServiceDidChangePropPickerModel:propPickerViewController.model];
    }];
}

#pragma mark - Track

- (NSDictionary *)trackReferExtra
{
    return self.repository.repoTrack.referExtra;
}

- (NSString *)createId
{
    return self.repository.repoContext.createId;
}

- (NSString *)referString
{
    return self.repository.repoTrack.referString;
}

/// 面板强插道具至热门前排
- (void)rearInsertAtHotTabWithProps:(NSArray<IESEffectModel *> * _Nullable)effects
{
    [self.subscription performEventSelector:@selector(propServiceRearDidSelectedInsertProps:) realPerformer:^(id<ACCRecordPropServiceSubscriber> subscriber) {
        [subscriber propServiceRearDidSelectedInsertProps:effects];
    }];
}


- (void)rearFinishedDownloadProp:(IESEffectModel *_Nullable)effect parentProp:(IESEffectModel *_Nullable)parentEffect
{
    [self.subscription performEventSelector:@selector(propServiceRearFinishedDownloadProp:parentProp:) realPerformer:^(id<ACCRecordPropServiceSubscriber> subscriber) {
        [subscriber propServiceRearFinishedDownloadProp:effect parentProp:parentEffect];
    }];
}
@end
