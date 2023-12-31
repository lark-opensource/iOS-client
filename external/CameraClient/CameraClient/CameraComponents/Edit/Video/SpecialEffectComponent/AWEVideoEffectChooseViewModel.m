//
//  AWEVideoEffectChooseViewModel.m
//  CameraClient-Pods-Aweme
//
//  Created by xulei on 2020/2/6.
//

#import "AWERepoVideoInfoModel.h"
#import "AWERepoPropModel.h"
#import "AWEVideoEffectChooseViewModel.h"
#import <CreationKitArch/AWEVideoImageGenerator.h>
#import <CameraClient/ACCAssetImageGeneratorTracker.h>
#import <CreativeKit/ACCAPMProtocol.h>
#import <CameraClient/ACCDraftProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitArch/ACCVideoConfigProtocol.h>
#import <CreationKitArch/ACCChallengeModelProtocol.h>
#import <CreationKitArch/ACCModelFactoryServiceProtocol.h>
#import "ACCRepoRedPacketModel.h"
#import <CreationKitArch/IESEffectModel+ACCSticker.h>
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import "ACCRepoEditEffectModel.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CameraClient/AWERepoDraftModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import "AWERepoCutSameModel.h"
#import "AWEVideoFragmentInfo.h"
#import "ACCEditPreviewProtocolD.h"
#import <CreativeKit/ACCProtocolContainer.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CameraClient/UIImage+ACCUIKit.h>
#import <CreationKitArch/ACCRepoGameModel.h>
#import <CameraClientModel/ACCVideoCanvasType.h>

// 按照需求时间特效绑定的话题id放在本地 其他特效是平台下发
static NSString * const kTimeEffectChallengeBindItemId = @"1649897488839694";

@interface AWEVideoEffectChooseViewModel ()<AWEVideoEffectViewDelegate>

@property (nonatomic, strong) AWEEffectDataManager *effectDataManager;

@property (nonatomic, assign) CGFloat lastPlayProgress;

@property (nonatomic, assign) BOOL shouldStartReverse;

@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *effectIdAndCategoryDict; // 缓存 effectId 对应的 category
@property (nonatomic, copy) NSDictionary<NSString *, UIColor *> *effectIdAndColorDict; // 缓存 effectId 对应的 color

@property (nonatomic, assign) BOOL isApplyingEffect;
@property (nonatomic, assign) BOOL isToolEffectLoading;

@property (nonatomic, strong) UIImage *firstFrameImage;
@property (nonatomic, strong) AWEVideoImageGenerator *imageGenerator;

@end

@implementation AWEVideoEffectChooseViewModel

// init
- (instancetype)initWithModel:(AWEVideoPublishViewModel *)model editService:(id<ACCEditServiceProtocol>)editService
{
    if (self = [super init]) {
        self.publishViewModel = model;
        self.editService = editService;
        
        self.originVideoData = [model.repoVideoInfo.video copy];
        self.originDisplayTimeRanges = [self.publishViewModel.repoEditEffect.displayTimeRanges copy];
        
        //save origin data，show "Do not save" alert when quit if there is any change
        self.originalRangeIds = [self getRangeIdsFromTimeRangeArray:[self.originVideoData.effect_operationTimeRange copy]];
        
        self.shouldStartReverse = YES;
        
        self.timeEffectDefaultBeginTime = 0;
        self.timeEffectTimeRange = [[IESMMEffectTimeRange alloc] init];
        self.timeEffectTimeRange.startTime = 0;
        self.timeEffectDefaultDuration = MAX([model.repoVideoInfo.video totalVideoDuration]/5.0, 1.0);
        
        self.containLyricSticker = NO;
        [self.editService.sticker.infoStickers enumerateObjectsUsingBlock:^(IESInfoSticker * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.isSrtInfoSticker) {
                self.containLyricSticker = YES;
                *stop = YES;
            }
        }];
        
        self.effectDataManager = [[AWEEffectDataManager alloc] init];
        if (!self.originVideoData.effectFilterPathBlock) {
            self.originVideoData.effectFilterPathBlock = [self effectFilterPathBlock];
        }
    }
    return self;
}

// behavior of click on Tabview
- (void)clickedTabViewAtIndex:(NSInteger)tabNum
{
    //log
    NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:self.publishViewModel.repoTrack.referExtra];
    if (tabNum < self.effectCategories.count) {
        referExtra[@"tab_name"] = [self.effectCategories objectAtIndex:tabNum].categoryKey;
    } else {
        referExtra[@"tab_name"] = @"time_effect";
    }
    [ACCTracker() trackEvent:@"click_effect_tab" params:referExtra needStagingFlag:NO];
    
    if (tabNum < self.effectCategories.count) {
        NSString *categoryKey = [self.effectCategories objectAtIndex:tabNum].categoryKey;
        if ([categoryKey isEqualToString:@"trans"]) {
            self.currentEffectViewType = AWEVideoEffectViewTypeTransition;
        } else {
            self.currentEffectViewType = AWEVideoEffectViewTypeFilter;
        }
        if ([self.delegate respondsToSelector:@selector(clickedTabViewWithCategoryKey:isTimeTab:)]){
            [self.delegate clickedTabViewWithCategoryKey:categoryKey isTimeTab:NO];
        }
    } else {
        self.currentEffectViewType = AWEVideoEffectViewTypeTime;
        HTSPlayerTimeMachineType currentMachineType = self.publishViewModel.repoVideoInfo.video.effect_timeMachineType;
        
        if ([self.delegate respondsToSelector:@selector(clickedTabViewWithCategoryKey:isTimeTab:)]) {
            [self.delegate clickedTabViewWithCategoryKey:@"" isTimeTab:YES];
        }
        
       //apply timeMachine
        NSTimeInterval duration = self.publishViewModel.repoVideoInfo.video.effect_newTimeMachineDuration;
        if (duration <= 0) {
            duration = self.timeEffectDefaultDuration;
            NSTimeInterval beginTime = self.publishViewModel.repoVideoInfo.video.effect_timeMachineBeginTime;
            if (beginTime <= 0) {
                beginTime = self.timeEffectDefaultBeginTime; // 默认中间位置
            }
            if (currentMachineType == HTSPlayerTimeMachineReverse) {
              IESMMTimeMachineConfig *config = [[IESMMTimeMachineConfig alloc] init];
              config.beginTime = beginTime;
              config.startTime = 0;
              config.timeMachineType = currentMachineType;
              [self.editService.effect applyTimeMachineWithConfig:config];
            } else {
              IESMMTimeMachineConfig *config = [[IESMMTimeMachineConfig alloc] init];
              config.beginTime = beginTime;
              config.duration = duration;
              config.timeMachineType = currentMachineType;
              [self.editService.effect applyTimeMachineWithConfig:config];
            }
        }

        if (self.shouldStartReverse && self.publishViewModel.repoVideoInfo.video.effect_reverseAsset == nil) {
            self.shouldStartReverse = NO;
            @weakify(self);
            [self.editService.effect restartReverseAsset:^(BOOL success,AVAsset *reverseAsset, NSError * _Nullable error) {
                @strongify(self);
                if (error) {
                    AWELogToolError(AWELogToolTagEdit, @"restart reverse asset error:%@", error);
                }
                if (success && self.publishViewModel.repoVideoInfo.video.effect_timeMachineType == HTSPlayerTimeMachineReverse) {
                    IESMMTimeMachineConfig *config = [[IESMMTimeMachineConfig alloc] init];
                    config.beginTime = 0;
                    config.startTime = 0;
                    config.timeMachineType = HTSPlayerTimeMachineReverse;
                    [self.editService.effect applyTimeMachineWithConfig:config];
                    [self syncEffectTimeRange];
                    if ([self.delegate respondsToSelector:@selector(refreshEffectFragments)]) {
                        [self.delegate refreshEffectFragments];
                    }
                    [ACCGetProtocol(self.editService.preview, ACCEditPreviewProtocolD) updateVideoData:self.publishViewModel.repoVideoInfo.video updateType:VEVideoDataUpdateVideoEffect completeBlock:^(NSError * _Nonnull error) {
                        @strongify(self);
                        if (error) {
                            AWELogToolError(AWELogToolTagEdit, @"updateVideoData error:%@", error);
                        }
                        [self.editService.audioEffect refreshAudioPlayer];
                        [self.editService.preview play];
                        [self loadFirstPreviewFrameWithCompletion:^(NSMutableArray * _Nonnull imageArray) {
                            @strongify(self);
                            if ([self.delegate respondsToSelector:@selector(refreshBarWithImageArray:)]) {
                                [self.delegate refreshBarWithImageArray:imageArray];
                            }
                        }];
                    }];
                }
            }];
        }
    }
}

// config play with block
- (void)configPlayerWithCompletionBlock:(void (^)(void))mixPlayerCompleteBlock
{
    @weakify(self);
    [self.editService.preview setMixPlayerCompleteBlock:^{
        @strongify(self);
        if (self.currentEffectViewType == AWEVideoEffectViewTypeTime || self.currentEffectViewType == AWEVideoEffectViewTypeTransition) {
            //Execute at the end of the play
            self.isPlaying = NO;
            [self.editService.preview seekToTime:CMTimeMakeWithSeconds(self.lastPlayProgress * [self.publishViewModel.repoVideoInfo.video totalVideoDuration], 1000000) completionHandler:nil];
            if (mixPlayerCompleteBlock) {
                mixPlayerCompleteBlock();
            }
        }
    }];

    [self.editService.effect setEffectLoadStatusBlock:^(IESStickerStatus status,NSInteger stickerID, NSString * _Nullable resName) {
        @strongify(self);
        if (status == IESStickerStatusValid) {
            if (self.isToolEffectLoading) {
                [self performSelector:@selector(p_didApplyToolEffectSticker:) withObject:[@(stickerID) stringValue] afterDelay:0.3];
            }
        }
    }];

    [self.editService.effect setEffectPathBlock:[self effectFilterPathBlock]];
}

#pragma mark - AWEVideoEffectViewDelegate
- (BOOL)checkEffectIsDownloaded:(IESEffectModel *)effect {
    AWEEffectDownloadStatus status = [self.effectDataManager downloadStatusOfEffect:effect];
    if (status == AWEEffectDownloadStatusUndownloaded) { // trigger download manually
        [self.effectDataManager addEffectToDownloadQueue:effect];
        return NO;
    } else if (status == AWEEffectDownloadStatusDownloading) {
        return NO;
    }
    return YES;
}

- (void)videoEffectView:(AWEVideoEffectView *)effectView beginLongPressWithType:(IESEffectModel *)effect
{
    //begin long press
    if (![self checkEffectIsDownloaded:effect]) {
        AWELogToolError(AWELogToolTagEdit, @"apply effect error, not downloaded, effect id:%@, effect name:%@",effect.effectIdentifier,effect.effectName);
        return;
    }
    [self applyEffect:effect];
}

- (void)applyEffect:(IESEffectModel *)effect {
    self.isApplyingEffect = YES;
    CGFloat beginTime = self.editService.preview.currentPlayerTime;
    self.isPlaying = YES;
    [self.editService.effect startEffectWithPathId:effect.effectIdentifier withTime:beginTime];
    if (![effect.filePath length]) {
        AWELogToolError(AWELogToolTagEdit, @"apply effect error, effect id:%@, effect name:%@",effect.effectIdentifier,effect.effectName);
    } else {
        AWELogToolVerbose(AWELogToolTagEdit, @"apply effect, effect id:%@, effect name:%@, begin time:%.2f",effect.effectIdentifier,effect.effectName,beginTime);
    }
    
    IESMMEffectTimeRange *effectRange = [IESMMEffectTimeRange new];
    effectRange.effectPathId = effect.effectIdentifier;
    effectRange.startTime = beginTime;
    effectRange.endTime = beginTime;

    [self.delegate setCurrentEffectTimeRange:effectRange];
    
    [ACCTracker() trackEvent:@"fx_click"
                                      label:effect.effectName
                                      value:nil
                                      extra:nil
                                 attributes:self.publishViewModel.repoTrack.referExtra];
    
    NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:self.publishViewModel.repoTrack.referExtra];
    referExtra[@"tab_name"] = [self effectCategoryWithEffectId:effect.effectIdentifier];
    referExtra[@"effect_id"] = effect.effectIdentifier;
    referExtra[@"effect_name"] = effect.effectName;
    [ACCTracker() trackEvent:@"effect_click" params:referExtra needStagingFlag:NO];
}

- (void)videoEffectView:(AWEVideoEffectView *)effectView beingLongPressWithType:(IESEffectModel *)effect
{
    if (![self checkEffectIsDownloaded:effect]) {
        AWELogToolError(AWELogToolTagEdit, @"apply effect error, not downloaded, effect id:%@, effect name:%@",effect.effectIdentifier,effect.effectName);
        return;
    }
    if (!self.isApplyingEffect) { // apply effect if download completed during long press
        [self applyEffect:effect];
    }
}

- (void)videoEffectView:(AWEVideoEffectView *)effectView didFinishLongPressWithType:(IESEffectModel *)effect
{
    //长按结束
    self.isApplyingEffect = NO;
    CGFloat dur = 0.1;
    CGFloat currentTime = self.editService.preview.currentPlayerTime;
    if ((currentTime - [self.delegate currentEffectTimeRange].startTime) < dur){
        NSDate *date = [NSDate dateWithTimeIntervalSinceNow:dur - (currentTime - [self.delegate currentEffectTimeRange].startTime)];
        [[NSRunLoop currentRunLoop] runUntilDate:date];
    }
    
    // Update Display Range
    const CGFloat startTime = [self.delegate currentEffectTimeRange].startTime;
    CGFloat endTime = self.editService.preview.currentPlayerTime;
    const CGFloat videoDuration = [self.publishViewModel.repoVideoInfo.video totalVideoDuration];
    if (endTime - startTime > 0) {
        if (ACC_FLOAT_LESS_THAN(videoDuration - endTime, 0.05f)) {
            /// FIX CAPTAIN-6160, 单段视频下最后的播放进度和总时长会有微小的差距(0.05s以内)，在这个范围内做一个吸附效果，以解决最后一小小小段视频无法添加特效的问题
            /// @seealso CAPTAIN-6080 另外开启跨平台 多段视频有较大差距的，则由视频@zhou yi那边对齐视频时长和播放那个进度
            endTime = videoDuration;
        }
    }
    [self.editService.effect stopEffectwithTime:endTime];
    [self syncEffectTimeRange];
    
    self.isPlaying = NO;
    [self.delegate setCurrentEffectTimeRange:nil];
    if ([self.delegate respondsToSelector:@selector(refreshEffectFragments)]) {
        [self.delegate refreshEffectFragments];
    }
    
    if ([self.delegate respondsToSelector:@selector(refreshRevokeButton)]) {
        [self.delegate refreshRevokeButton];
    }
}

- (void)videoEffectView:(AWEVideoEffectView *)effectView didCancelLongPressWithType:(IESEffectModel *)effect
{
    [self videoEffectView:effectView didFinishLongPressWithType:effect];
}

//click revoke button
- (void)videoEffectView:(AWEVideoEffectView *)effectView didClickedRevokeBtn:(UIButton *)btn;
{
    if (!effectView.effectCategory) {
        AWELogToolError(AWELogToolTagEdit, @"revoke effect error, effectView.effectCategory empty");
        return;
    }
    
    if (self.isPlaying) {
        if ([self.delegate respondsToSelector:@selector(didClickStopAndPlay)]){
            [self.delegate didClickStopAndPlay];
        }
    }
    
    __block IESMMEffectTimeRange *effectRange = nil;
    NSArray<IESMMEffectTimeRange *> *effectRanges = [self.publishViewModel.repoVideoInfo.video.effect_operationTimeRange copy];
    [effectRanges enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(IESMMEffectTimeRange * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *rangeCategory = [self effectCategoryWithEffectId:obj.effectPathId];
        if ([rangeCategory isEqualToString:effectView.effectCategory] && obj.timeMachineStatus != TIMERANGE_TIMEMACHINE_ADD) {
            effectRange = obj;
            *stop = YES;
        }
    }];
    
    IESEffectModel *lastEffect = [self normalEffectWithID:effectRange.effectPathId];
    if (effectRange) {
        [ACCTracker() trackEvent:@"cancel_fx"
                                          label:lastEffect.effectName
                                          value:nil
                                          extra:nil
                                     attributes:nil];
        [ACCTracker() trackEvent:@"click_effect_undo"
                          params:@{
                              @"effect_id" : lastEffect.effectIdentifier ?: @"",
                              @"shoot_way" : self.publishViewModel.repoTrack.referString ?: @"",
                              @"content_source" : [self.publishViewModel.repoTrack referExtra][@"content_source"] ?: @"",
                              @"content_type" : [self.publishViewModel.repoTrack referExtra][@"content_type"] ?: @"",
                              @"is_multi_content" : self.publishViewModel.repoTrack.mediaCountInfo[@"is_multi_content"] ?: @"",
                              @"mix_type" : [self.publishViewModel.repoTrack referExtra][@"mix_type"] ?: @"",
                              @"creation_id" : self.publishViewModel.repoContext.createId ?: @"",
                          }];
    
        CGFloat lastStartTime =  [self.editService.effect removeEffectWithRangeID:effectRange.rangeID];
        [self.editService.preview seekToTime:CMTimeMakeWithSeconds(lastStartTime, 1000000)];
        
        // Update Display Range
        [self syncEffectTimeRange];
        if ([self.delegate respondsToSelector:@selector(refreshEffectFragments)]) {
            [self.delegate refreshEffectFragments];
        }
        
        if ([self.delegate respondsToSelector:@selector(refreshRevokeButton)]) {
            [self.delegate refreshRevokeButton];
        }
        
        if ([self.delegate respondsToSelector:@selector(refreshMovingView:)]) {
            [self.delegate refreshMovingView:lastStartTime];
        }
    } else {
        AWELogToolError(AWELogToolTagEdit, @"revoke effect error, effect id:%@, effect name:%@",lastEffect.effectIdentifier,lastEffect.effectName);
    }
}

//click transition effect
- (void)videoEffectView:(AWEVideoEffectView *)effectView clickedCellWithTransitionEffect:(IESEffectModel *)effect {
    [ACCTracker() trackEvent:@"fx_click"
                                      label:effect.effectName
                                      value:nil
                                      extra:nil
                                 attributes:self.publishViewModel.repoTrack.referExtra];
    
    NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:self.publishViewModel.repoTrack.referExtra];
    referExtra[@"tab_name"] = [self effectCategoryWithEffectId:effect.effectIdentifier];
    referExtra[@"effect_id"] = effect.effectIdentifier;
    referExtra[@"effect_name"] = effect.effectName;
    [ACCTracker() trackEvent:@"effect_click" params:referExtra needStagingFlag:NO];
    
    CGFloat totalVideoDuration = self.publishViewModel.repoVideoInfo.video.totalVideoDuration;
    if (totalVideoDuration > 0) {
        const CGFloat beginTime = self.editService.preview.currentPlayerTime;
        CGFloat effectDuration = [self.effectDataManager effectDurationForNormalEffect:effect];
        if (beginTime + effectDuration > totalVideoDuration) {
            effectDuration = totalVideoDuration - beginTime;
        }
        
        if (effectDuration > 0) {
            // Apply effect
            NSString *effectId = effect.effectIdentifier;
            CGFloat startTime = floor(beginTime * 1000) / 1000;
            CGFloat endTime = floor((beginTime + effectDuration) * 1000) / 1000;
            
            [self.editService.effect setEffectWidthPathID:effectId withStartTime:startTime andStopTime:endTime];
                
            // Play
            if (!self.isPlaying) {
                if ([self.delegate respondsToSelector:@selector(didClickStopAndPlay)]) {
                    [self.delegate didClickStopAndPlay];
                }
            }
            
            self.editService.preview.autoRepeatPlay = NO;
            
            // Update Display Range
            [self syncEffectTimeRange];
            
            // Update UI
            if ([self.delegate respondsToSelector:@selector(refreshEffectFragments)]) {
                [self.delegate refreshEffectFragments];
            }
            
            if ([self.delegate respondsToSelector:@selector(refreshRevokeButton)]) {
                [self.delegate refreshRevokeButton];
            }
        } else {
            AWELogToolError(AWELogToolTagEdit, @"apply transition effect error, effectDuration <=0, effect id:%@ effect name:%@",
                            effect.effectIdentifier,effect.effectName);
        }
    } else {
        AWELogToolError(AWELogToolTagEdit, @"apply transition effect error, totalVideoDuration <=0, effect id:%@, effect name:%@",
                        effect.effectIdentifier,effect.effectName);
    }
}

//select tool effect
- (void)videoEffectView:(AWEVideoEffectView *)effectView didSelectToolEffect:(IESEffectModel *)effect
{
    // Track
    [ACCTracker() trackEvent:@"fx_click"
                                      label:effect.effectName
                                      value:nil
                                      extra:nil
                                 attributes:self.publishViewModel.repoTrack.referExtra];
    
    NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:self.publishViewModel.repoTrack.referExtra];
    referExtra[@"tab_name"] = [self effectCategoryWithEffectId:effect.effectIdentifier];
    referExtra[@"effect_id"] = effect.effectIdentifier;
    referExtra[@"effect_name"] = effect.effectName;
    [ACCTracker() trackEvent:@"effect_click" params:referExtra needStagingFlag:NO];
    
    // // apply tool effect
    CGFloat totalVideoDuration = self.publishViewModel.repoVideoInfo.video.totalVideoDuration;
    if (totalVideoDuration > 0) {
        // 删除其它的道具特效，单次只能使用一个效果
        __block IESMMEffectTimeRange *effectRange = nil;
        NSArray<IESMMEffectTimeRange *> *effectRanges = [self.publishViewModel.repoVideoInfo.video.effect_operationTimeRange copy];
        [effectRanges enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(IESMMEffectTimeRange * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *rangeCategory = [self effectCategoryWithEffectId:obj.effectPathId];
            if ([rangeCategory isEqualToString:effectView.effectCategory] && obj.timeMachineStatus != TIMERANGE_TIMEMACHINE_ADD) {
                effectRange = obj;
                *stop = YES;
            }
        }];
        if (effectRange) {
            [self.editService.effect removeEffectWithRangeID:effectRange.rangeID];
        }
        
        // tool effect log
        [ACCAPM() attachInfo:effect.effectIdentifier forKey:@"last_sticker_id"];
        AWELogToolInfo(AWELogToolTagEdit, @"%@", [NSString stringWithFormat:@"[Edit] sticker id:%@ md5:%@", effect.effectIdentifier, effect.md5]);
        
        NSString *effectId = effect.effectIdentifier;
        CGFloat startTime = floor(0 * 1000) / 1000;
        CGFloat endTime = floor((totalVideoDuration) * 1000) / 1000;
        [self.editService.effect setEffectWidthPathID:effectId withStartTime:startTime andStopTime:endTime];

        [self p_startApplyToolEffect:effectId]; // start Loading

        if (self.isPlaying) {
            if ([self.delegate respondsToSelector:@selector(didClickStopAndPlay)]){
                [self.delegate didClickStopAndPlay];
            }
        }
        @weakify(self);
        [self.editService.preview seekToTime:CMTimeMakeWithSeconds(0, NSEC_PER_SEC) completionHandler:^(BOOL finished) {
            @strongify(self);
            if ([self.delegate respondsToSelector:@selector(didClickStopAndPlay)]){
                [self.delegate didClickStopAndPlay];
            }
        }];

        // Update Display Range
        [self syncEffectTimeRange];
    }
}

- (void)videoEffectView:(AWEVideoEffectView *)effectView didDeselectToolEffect:(IESEffectModel *)effect
{
    __block IESMMEffectTimeRange *effectRange = nil;
    NSArray<IESMMEffectTimeRange *> *effectRanges = [self.publishViewModel.repoVideoInfo.video.effect_operationTimeRange copy];
    [effectRanges enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(IESMMEffectTimeRange * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *rangeCategory = [self effectCategoryWithEffectId:obj.effectPathId];
        if ([rangeCategory isEqualToString:effectView.effectCategory] && obj.timeMachineStatus != TIMERANGE_TIMEMACHINE_ADD) {
            effectRange = obj;
            *stop = YES;
        }
    }];
    
    if (effectRange) {
        CGFloat lastStartTime =  [self.editService.effect removeEffectWithRangeID:effectRange.rangeID];
        [self.editService.preview seekToTime:CMTimeMakeWithSeconds(lastStartTime, 1000000)];
        
        // Update Display Range
        NSString *category = [self effectCategoryWithEffectId:effect.effectIdentifier];
        if (category) {
            [self syncEffectTimeRange];
        }
        
        if ([self.delegate respondsToSelector:@selector(refreshEffectFragments)]) {
            [self.delegate refreshEffectFragments];
        }
        
        if ([self.delegate respondsToSelector:@selector(refreshRevokeButton)]) {
            [self.delegate refreshRevokeButton];
        }
        if (category) {
            if ([self.delegate respondsToSelector:@selector(updateShowingToolEffectRangeViewIfNeededWithCategoryKey:effectSelected:)]){
                [self.delegate updateShowingToolEffectRangeViewIfNeededWithCategoryKey:category effectSelected:NO];
            }
        }
    } else {
        AWELogToolError(AWELogToolTagEdit, @"deselect tool effect error, effect id:%@, effect name:%@", effect.effectIdentifier,effect.effectName);
    }
}

- (void)videoEffectView:(AWEVideoEffectView *)effectVi clickedCellWithTimeEffect:(HTSVideoSepcialEffect *)effect showClickedStyle:(BOOL)showClickedStyle
{
    if (showClickedStyle) {
        [ACCTracker() trackEvent:@"fx_click"
                                              label:effect.name
                                              value:nil
                                              extra:nil
                                         attributes:self.publishViewModel.repoTrack.referExtra];
            
        NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:self.publishViewModel.repoTrack.referExtra];
        referExtra[@"tab_name"] = @"time_effect";
        referExtra[@"effect_name"] = effect.name;
        [ACCTracker() trackEvent:@"effect_click" params:referExtra needStagingFlag:NO];
        
        if ([self.delegate respondsToSelector:@selector(getPlayControlViewProgress)]) {
            self.lastPlayProgress = [self.delegate getPlayControlViewProgress];
        }

        NSTimeInterval beginTime = [self.editService.effect getTimeMachineBegineTime:effect.timeMachineType];
        if (beginTime <= 0) {
            beginTime = 0; // default is 0
        }
        effect.beginTime = beginTime;
        
        NSTimeInterval duration = [self.publishViewModel.repoVideoInfo.video effect_currentTimeMachineDurationWithType:effect.timeMachineType];
        if (duration <= 0) {
            beginTime = self.editService.preview.currentPlayerTime;
            duration = self.timeEffectDefaultDuration;
            if (beginTime + duration >= [self.publishViewModel.repoVideoInfo.video totalVideoDuration]) {
                beginTime = [self.publishViewModel.repoVideoInfo.video totalVideoDuration] - duration;
            }
        }
        
        if ([self.delegate respondsToSelector:@selector(switchToTimeMachineType:withBeginTime:duration:animation:)]) {
            [self.delegate switchToTimeMachineType:effect.timeMachineType withBeginTime:beginTime duration:duration animation:YES];
        }

        //reduce function call
        BOOL needRefreshUI = NO;
        if (effect.timeMachineType == HTSPlayerTimeMachineReverse || self.publishViewModel.repoVideoInfo.video.effect_timeMachineType == HTSPlayerTimeMachineReverse) {
            if (effect.timeMachineType != self.publishViewModel.repoVideoInfo.video.effect_timeMachineType) {
                needRefreshUI = YES;
            }
        }
        
        //apply time machine
        if (effect.timeMachineType == HTSPlayerTimeMachineReverse) {
            IESMMTimeMachineConfig *config = [[IESMMTimeMachineConfig alloc] init];
            config.beginTime = beginTime;
            config.startTime = 0;
            config.timeMachineType = effect.timeMachineType;
            [self.editService.effect applyTimeMachineWithConfig:config];
        } else {
            IESMMTimeMachineConfig *config = [[IESMMTimeMachineConfig alloc] init];
            config.beginTime = beginTime;
            config.duration = duration;
            config.timeMachineType = effect.timeMachineType;
            [self.editService.effect applyTimeMachineWithConfig:config];
        }
        
        if (effect.timeMachineType == HTSPlayerTimeMachineReverse && self.editService.effect.timeMachineReady == NO) {
            
        } else {
            @weakify(self);
            [ACCGetProtocol(self.editService.preview, ACCEditPreviewProtocolD) updateVideoData:self.publishViewModel.repoVideoInfo.video updateType:VEVideoDataUpdateVideoEffect completeBlock:^(NSError * _Nonnull error) {
                @strongify(self);
                if (error) {
                    AWELogToolError(AWELogToolTagEdit, @"updateVideoData error:%@", error);
                }
                [self.editService.preview play];
                if (needRefreshUI) {
                    [self loadFirstPreviewFrameWithCompletion:^(NSMutableArray * _Nonnull imageArray) {
                        @strongify(self);
                        if ([self.delegate respondsToSelector:@selector(refreshBarWithImageArray:)]) {
                            [self.delegate refreshBarWithImageArray:imageArray];
                        }
                    }];
                }
                
                [self clipMusic];
            }];
        }
        
        if (needRefreshUI) {
            //reverset timeRange startTime with endTime
            // 这里考虑ve的currTimeMachineType可能不能立即改变
            [self syncEffectTimeRange:effect];
            if ([self.delegate respondsToSelector:@selector(refreshEffectFragments)]) {
                [self.delegate refreshEffectFragments];
            }
        }
        
        if (!self.isPlaying) {
            if ([self.delegate respondsToSelector:@selector(didClickStopAndPlay)]) {
                [self.delegate didClickStopAndPlay];
            }
        }
        self.editService.preview.autoRepeatPlay = NO;
    } else {
        
    }
}

#pragma mark - AWEVideoEffectMixTimeBarDelegate
-(NSString *)effectIdWithEffectType:(IESEffectFilterType)type {
    if (!type) {
        return nil;
    }
    return [self.effectDataManager effectIdWithType:type];
}

- (NSString *)effectCategoryWithEffectId:(NSString *)effectId {
    if (!effectId) {
        return nil;
    }
    
    return [self.effectIdAndCategoryDict objectForKey:effectId];
}

- (UIColor *)effectColorWithEffectId:(NSString *)effectId {
    if (!effectId) {
        return nil;
    }
    
    return [self.effectIdAndColorDict objectForKey:effectId];
}


- (void)userDidMoveTimeBarControl:(AWEVideoPlayControl *)control progress:(double)progress
{
    [self.editService.preview seekToTime:CMTimeMakeWithSeconds(progress * [self.publishViewModel.repoVideoInfo.video totalVideoDuration],1000000)];
}

- (void)userDidFinishMoveTimeBarControl:(AWEVideoPlayControl *)control progress:(double)progress
{
    [ACCTracker() trackEvent:@"drag_time"
                        label:@"fx_page"
                        value:nil
                        extra:nil
                   attributes:nil];
}

//AWEVideoEffectScalableRangeView
- (void)userDidFinishChangeRangeViewEffectRange:(CGFloat)rangeFrom rangeTo:(CGFloat)rangeTo changeType:(AWEVideoEffectScalableRangeViewFrameChangeType)changeType inTimeEffectView:(BOOL)inTimeEffectView
{
    //judge whether the rangeView in tab "time" or not
    if (inTimeEffectView) {
        if ([self.delegate respondsToSelector:@selector(getPlayControlViewProgress)]) {
            self.lastPlayProgress = [self.delegate getPlayControlViewProgress];
        }
        
        double totalDuration = [self.publishViewModel.repoVideoInfo.video totalVideoDuration];
        HTSPlayerTimeMachineType effectType = self.publishViewModel.repoVideoInfo.video.effect_timeMachineType;
        IESMMTimeMachineConfig *config = [[IESMMTimeMachineConfig alloc] init];
        config.beginTime = floor(totalDuration * rangeFrom * 1000) / 1000;;
        config.duration = floor(totalDuration * (rangeTo - rangeFrom) * 1000) / 1000;
        config.timeMachineType = effectType;
        self.timeEffectTimeRange.startTime = floor(totalDuration * rangeFrom * 1000) / 1000;;
        self.timeEffectTimeRange.endTime = floor(totalDuration * rangeTo * 1000) / 1000;
        [self.editService.effect applyTimeMachineWithConfig:config];
        @weakify(self);
        [ACCGetProtocol(self.editService.preview, ACCEditPreviewProtocolD) updateVideoData:self.publishViewModel.repoVideoInfo.video updateType:VEVideoDataUpdateVideoEffect completeBlock:^(NSError * _Nonnull error) {
            if (error == nil) {
                @strongify(self);
                [self clipMusic];
            } else {
                AWELogToolError(AWELogToolTagEdit, @"updateVideoData error:%@", error);
            }
        }];
        
        if (!self.isPlaying) {
            if ([self.delegate respondsToSelector:@selector(didClickStopAndPlay)]) {
                [self.delegate didClickStopAndPlay];
            }
        }
        self.editService.preview.autoRepeatPlay = NO;
        NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:self.publishViewModel.repoTrack.referExtra];
        referExtra[@"tab_name"] = @"time_effect";
        referExtra[@"effect_id"] = [HTSVideoSepcialEffect effectWithType:effectType].timeEffectId ?:@"";
        referExtra[@"effect_name"] = [HTSVideoSepcialEffect effectWithType:effectType].name ?:@"";
        referExtra[@"duration"] = @(self.timeEffectTimeRange.endTime - self.timeEffectTimeRange.startTime);
        referExtra[@"enter_from"] = @"edit_effect_page";
        [ACCTracker() trackEvent:@"duration_adjust_complete" params:referExtra needStagingFlag:NO];
    } else {
        // apply tool effect
        CGFloat totalVideoDuration = self.publishViewModel.repoVideoInfo.video.totalVideoDuration;
        if (totalVideoDuration > 0) {
            //only use one tool effect at a time
            __block IESMMEffectTimeRange *effectRange = nil;
            NSArray<IESMMEffectTimeRange *> *effectRanges = [self.publishViewModel.repoVideoInfo.video.effect_operationTimeRange copy];
            [effectRanges enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(IESMMEffectTimeRange * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *rangeCategory = [self effectCategoryWithEffectId:obj.effectPathId];
                if ([self p_isStickerCategory:rangeCategory] && obj.timeMachineStatus != TIMERANGE_TIMEMACHINE_ADD) {
                    effectRange = obj;
                    *stop = YES;
                }
            }];
            if (effectRange) {
                [self.editService.effect removeEffectWithRangeID:effectRange.rangeID];
                [self syncEffectTimeRange];
            }
            
            // time reverse
            if (HTSPlayerTimeMachineReverse == self.publishViewModel.repoVideoInfo.video.effect_timeMachineType) {
                const CGFloat originFrom = rangeFrom;
                const CGFloat originTo = rangeTo;
                rangeFrom = 1.0f - originTo;
                rangeTo = 1.0f - originFrom;
            }
            
            NSString *effectId = effectRange.effectPathId;
            CGFloat startTime = floor(totalVideoDuration * rangeFrom * 1000) / 1000;
            CGFloat endTime = floor(totalVideoDuration * rangeTo * 1000) / 1000;
            [self.editService.effect setEffectWidthPathID:effectId withStartTime:startTime andStopTime:endTime];
            
            NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:self.publishViewModel.repoTrack.referExtra];
            
            IESEffectModel *effect = [self normalEffectWithID:effectId];
            if (effect) {
                referExtra[@"tab_name"] = [self effectCategoryWithEffectId:effectRange.effectPathId] ?:@"";
                referExtra[@"effect_id"] = effectId ?:@"";
                referExtra[@"effect_name"] = effect.effectName ?:@"";
                referExtra[@"duration"] = @(endTime - startTime);
                referExtra[@"enter_from"] = @"edit_effect_page";
                [ACCTracker() trackEvent:@"duration_adjust_complete" params:referExtra needStagingFlag:NO];

            }
                        
            //automatic play video after applied the time effect
            if (self.isPlaying) {
                if ([self.delegate respondsToSelector:@selector(didClickStopAndPlay)]) {
                    [self.delegate didClickStopAndPlay];
                }
            }
            if (HTSPlayerTimeMachineReverse != self.publishViewModel.repoVideoInfo.video.effect_timeMachineType) {
                [self.editService.preview seekToTime:CMTimeMakeWithSeconds(totalVideoDuration * rangeFrom, NSEC_PER_SEC)];
            } else {
                [self.editService.preview seekToTime:CMTimeMakeWithSeconds(totalVideoDuration * rangeTo, NSEC_PER_SEC)];
            }
            if (!self.isPlaying) {
                if ([self.delegate respondsToSelector:@selector(didClickStopAndPlay)]) {
                    [self.delegate didClickStopAndPlay];
                }
            }
            self.editService.preview.autoRepeatPlay = YES;
            
            // Update Display Range
            [self syncEffectTimeRange];
            
            // Update UI
            if ([self.delegate respondsToSelector:@selector(refreshEffectFragments)]) {
                [self.delegate refreshEffectFragments];
            }
            
            if ([self.delegate respondsToSelector:@selector(refreshRevokeButton)]) {
                [self.delegate refreshRevokeButton];
            }
        }
    }
}

#pragma mark - cancel and save action
- (void)didClickCancelBtn {
    [self.imageGenerator cancel];

    self.originVideoData.effect_reverseAsset = self.publishViewModel.repoVideoInfo.video.effect_reverseAsset;
    self.originVideoData.effectFilterPathBlock = [self effectFilterPathBlock];
    self.editService.preview.autoRepeatPlay = YES;

    [ACCGetProtocol(self.editService.preview, ACCEditPreviewProtocolD)
     updateVideoData:self.originVideoData
     updateType:VEVideoDataUpdateVideoEffect
     completeBlock:^(NSError * _Nonnull error) {
        if (error) {
            AWELogToolError(AWELogToolTagEdit, @"update videoData error:%@", error);
        }
    }];
    [self.editService.preview play];
    [self.publishViewModel.repoVideoInfo updateVideoData:self.originVideoData];
    
    //if cancel button clicked retrieve origin dsiplay Time Ranges
    [self.publishViewModel.repoEditEffect.displayTimeRanges removeAllObjects];
    if (self.originDisplayTimeRanges.count > 0) {
        [self.publishViewModel.repoEditEffect.displayTimeRanges addObjectsFromArray:self.originDisplayTimeRanges];
    }
    
    [self.editService.effect restartReverseAsset:^(BOOL success, AVAsset * _Nullable reverseAsset, NSError * _Nullable error) {
        if (error) {
            AWELogToolError(AWELogToolTagEdit, @"restart reverse asset error:%@", error);
        }
    }];
}

- (void)didClickSaveBtn {
    [self.imageGenerator cancel];

    //log
    [ACCTracker() trackEvent:@"fx_confirm"
                                      label:@"edit_page"
                                      value:nil
                                      extra:nil
                                 attributes:self.publishViewModel.repoTrack.referExtra];
    
    NSMutableArray *effects = [@[] mutableCopy];
    [self.publishViewModel.repoVideoInfo.video.effect_timeRange enumerateObjectsUsingBlock:^(IESMMEffectTimeRange * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *name = [self normalEffectWithID:obj.effectPathId].effectName;
        if (name) {
            [effects addObject:name];
        }
    }];
    NSString *timeEffectName = [self timeEffectWithType:self.publishViewModel.repoVideoInfo.video.effect_timeMachineType].name;
    if (timeEffectName) {
        [effects addObject:timeEffectName];
    }
    
    NSMutableDictionary *extraDict = [self.publishViewModel.repoTrack.referExtra mutableCopy];
    [extraDict addEntriesFromDictionary:@{@"effect_name" : [effects componentsJoinedByString:@","] ? : @""}];
    [ACCTracker() trackEvent:@"effect_confirm" params:extraDict needStagingFlag:NO];
    
    
    if (self.isPlaying) {
        if ([self.delegate respondsToSelector:@selector(didClickStopAndPlay)]) {
            [self.delegate didClickStopAndPlay];
        }
    }
    self.editService.preview.autoRepeatPlay = YES;
    [ACCGetProtocol(self.editService.preview, ACCEditPreviewProtocolD) updateVideoData:self.publishViewModel.repoVideoInfo.video
                                                                            updateType:VEVideoDataUpdateVideoEffect
                                                                         completeBlock:^(NSError * _Nonnull error) {
        if (error) {
            AWELogToolError(AWELogToolTagDraft, @"update videodata error:%@", error);
        }
    }];
    [self.editService.preview play];
    [self.publishViewModel.repoVideoInfo updateVideoData:self.publishViewModel.repoVideoInfo.video];
    // FIX AME-84465
    // 草稿模式下在发布页点击存草稿publishViewModel才需要被存储，否则在编辑页直接点返回不会被清除
    // 这还会导致 像图片贴纸等这种也被更新到草稿中
    if (!self.publishViewModel.repoDraft.isDraft) {
        [ACCDraft() saveDraftWithPublishViewModel:self.publishViewModel
                                            video:self.publishViewModel.repoVideoInfo.video
                                            backup:!self.publishViewModel.repoDraft.originalDraft
                                        completion:^(BOOL success, NSError *error) {
            if (error) {
                AWELogToolError(AWELogToolTagDraft, @"save draft error:%@", error);
            }
        }];
    }
}

#pragma mark - Display time ranges

- (void)syncEffectTimeRange {
    [self syncEffectTimeRange:nil];
}

- (void)syncEffectTimeRange:(HTSVideoSepcialEffect *_Nullable)effect {
    /// FIX【iOS】【导入】导入多视频进入音乐卡点，点击特效添加特效，撤回时，视频轨道上指针与视频效果被撤销，特效颜色覆盖依然存在
    /// ve逻辑琢磨不透，在视频结尾长按特效，不同机型下调用ve的添加接口，有些能加上，有些加不上..所以干脆从ve同步数据过来
    CGFloat videoDuration = self.publishViewModel.repoVideoInfo.video.effect_videoDuration;
    BOOL isReverse = self.publishViewModel.repoVideoInfo.video.effect_timeMachineType == HTSPlayerTimeMachineReverse || effect.timeMachineType == HTSPlayerTimeMachineReverse;
    NSMutableArray *timeRanges = @[].mutableCopy;
    for (IESMMEffectTimeRange *timeRange in self.publishViewModel.repoVideoInfo.video.effect_operationTimeRange.copy) {
        IESMMEffectTimeRange *range = [[IESMMEffectTimeRange alloc] init];
        range.effectPathId = timeRange.effectPathId;
        range.startTime = isReverse ? videoDuration - timeRange.endTime: timeRange.startTime;
        range.endTime = isReverse ? videoDuration - timeRange.startTime: timeRange.endTime;
        [timeRanges addObject:range];
    }
    [self.publishViewModel.repoEditEffect.displayTimeRanges removeAllObjects];
    [self.publishViewModel.repoEditEffect.displayTimeRanges addObjectsFromArray:timeRanges];
}

#pragma mark - helper

- (void)loadFirstPreviewFrameWithCompletion:(void (^)(NSMutableArray * _Nonnull))refreshBlock
{
    CGFloat scale = [UIScreen mainScreen].scale;
    @weakify(self);
    [self.editService.captureFrame getSourcePreviewImageAtTime:0 preferredSize:CGSizeMake(scale * [AWEVideoEffectMixTimeBar timeBarHeight], scale * [AWEVideoEffectMixTimeBar timeBarHeight] * 16 / 9) compeletion:^(UIImage * _Nonnull image, NSTimeInterval atTime) {
       dispatch_async(dispatch_get_main_queue(), ^{
           if (image) {
               @strongify(self);
               NSMutableArray *previewImageArray = @[].mutableCopy;
               UIImage *imageWithBlur = [self enlargeImageSizeAndSquare:[image acc_blurredImageWithRadius:15]];
               if (imageWithBlur) {
                    [previewImageArray addObject:imageWithBlur];
                     self.firstFrameImage = imageWithBlur;
                     if (refreshBlock) {
                         refreshBlock(previewImageArray);
                         [self reloadPreviewFrames:refreshBlock];
                     }
               }
           }
       });
    }];
}

- (void)reloadPreviewFrames:(void (^)(NSMutableArray *imageArray))refreshBlock
{
    if (!self.firstFrameImage) {
        return;
    }
    
    NSInteger count = ceil([UIScreen mainScreen].bounds.size.width / [AWEVideoEffectMixTimeBar timeBarHeight]);
    if (count == 0) {
        return;
    }
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGFloat totalDuration = [self.publishViewModel.repoVideoInfo.video totalVideoDuration];
    CGFloat step = totalDuration / count;
    NSMutableArray *previewImageDictArray = @[].mutableCopy;
    NSMutableArray *imageArray = @[].mutableCopy;
    for (NSInteger i = 0; i < count; i++) {
        [imageArray addObject:self.firstFrameImage];
    }
    
    NSTimeInterval imageGeneratorBegin = CFAbsoluteTimeGetCurrent();
    __weak typeof(self) weakSelf = self;
    [self.imageGenerator cancel];
    [self.imageGenerator requestImages:count
                                effect:self.publishViewModel.repoContext.videoType == AWEVideoTypeQuickStoryPicture || self.publishViewModel.repoVideoInfo.canvasType != ACCVideoCanvasTypeNone // CAPTAIN-7225: 此模式需要 withEffect
                                 index:0
                                  step:step
                                  size:CGSizeMake(scale * [AWEVideoEffectMixTimeBar timeBarHeight], scale * [AWEVideoEffectMixTimeBar timeBarHeight] * 16 / 9)
                                 array:previewImageDictArray
                           editService:self.editService
                    oneByOneImageBlock:^(UIImage *image, NSInteger index) {
                        if (image && index < imageArray.count) {
                            image = [self enlargeImageSizeAndSquare:image] ?: image;
                            [imageArray replaceObjectAtIndex:index withObject:image];
                        }
                        if (refreshBlock) {
                            refreshBlock(imageArray);
                        }
                    } completion:^{
                        NSMutableArray *previewImageArray = @[].mutableCopy;
                        [previewImageDictArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            [previewImageArray addObject:[self enlargeImageSizeAndSquare:obj[@"image"]]];
                        }];
                        if (refreshBlock) {
                            refreshBlock(imageArray);
                        }
                        
                        //performance track
                        [ACCAssetImageGeneratorTracker trackAssetImageGeneratorWithType:ACCAssetImageGeneratorTypeSpecialEffects frames:count
                                                                              beginTime:imageGeneratorBegin extra:weakSelf.publishViewModel.repoTrack.commonTrackInfoDic];
                    }];
}

- (UIImage *)enlargeImageSizeAndSquare:(UIImage *)image
{
    CGFloat width = image.size.width;
    CGFloat height = image.size.height;
    if (width > height) {
        CGFloat newWidth = width * width / height;
        height = width;
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(height, height), YES, [[UIScreen mainScreen] scale]);
        [image drawInRect:CGRectMake(-(newWidth - height) / 2, 0, newWidth, height)];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return image;
}

- (AWEVideoImageGenerator *)imageGenerator
{
    if (!_imageGenerator) {
        _imageGenerator = [AWEVideoImageGenerator new];
    }
    return _imageGenerator;
}

- (BOOL)isRedPacketVideo
{
    BOOL isRedPacketVideo = NO;
    for (AWEVideoFragmentInfo *fragInfo in self.publishViewModel.repoVideoInfo.fragmentInfo) {
        if (fragInfo.activityTimerange.count) {
            isRedPacketVideo = YES;
            break;
        }
    }

    return isRedPacketVideo;
}

- (BOOL)isMultiSegPropVideo
{
    return self.publishViewModel.repoProp.isMultiSegPropApplied;
}

- (void)p_startApplyToolEffect:(NSString *)stickerID
{
    self.isToolEffectLoading = YES;
    if ([self.delegate respondsToSelector:@selector(p_startApplyToolEffect:)]) {
        [self.delegate p_startApplyToolEffect:stickerID];
    }
    
    [self performSelector:@selector(p_applyToolEffectStickerTimeout:) withObject:stickerID afterDelay:3];
}

- (void)p_stopToolEffectLoadingIfNeeded
{
    if (!self.isToolEffectLoading) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(p_stopToolEffectLoadingIfNeeded)]) {
        [self.delegate p_stopToolEffectLoadingIfNeeded];
    }

    if (!self.isPlaying) {
        if ([self.delegate respondsToSelector:@selector(didClickStopAndPlay)]) {
            [self.delegate didClickStopAndPlay];
        }
    }
    self.editService.preview.autoRepeatPlay = YES;

    self.isToolEffectLoading = NO;
}

- (void)p_didApplyToolEffectSticker:(NSString *)stickerID
{
    [self p_stopToolEffectLoadingIfNeeded];

    [ACCMonitor() trackService:@"aweme_tool_effect_loading_timeout_rate"
                     status:0
                      extra:@{@"stickerId" : AWEStudioSafeString(stickerID)}];
}

- (void)p_applyToolEffectStickerTimeout:(NSString *)stickerID
{
    [self p_stopToolEffectLoadingIfNeeded];

    [ACCMonitor() trackService:@"aweme_tool_effect_loading_timeout_rate"
                     status:1
                      extra:@{@"stickerId" : AWEStudioSafeString(stickerID)}];
}


- (NSString *)getStickerEffectIdInDisplayTimeRanges
{
    NSString *stickerEffectId = nil;
    NSArray<IESMMEffectTimeRange *> *displayTimeRanges = [self.publishViewModel.repoEditEffect.displayTimeRanges copy];
    for (IESMMEffectTimeRange *range in displayTimeRanges) {
        NSString *rangeCategory = [self effectCategoryWithEffectId:range.effectPathId];
        if ([self p_isStickerCategory:rangeCategory]) {
            stickerEffectId = range.effectPathId;
            break;
        }
    }
    return stickerEffectId;
}

- (BOOL)p_isStickerCategory:(NSString *)categoryKey
{
    return [@"sticker" isEqualToString:categoryKey];
}

- (void)setIsPlaying:(BOOL)isPlaying
{
    _isPlaying = isPlaying;
    if ([self.delegate respondsToSelector:@selector(setIsPlaying:)]) {
        [self.delegate setIsPlaying:isPlaying];
    }
}

- (NSMutableString *)getRangeIdsFromTimeRangeArray:(NSArray<IESMMEffectTimeRange *> *)timeRanges{
    NSMutableString *rangeIds = [[NSMutableString alloc] init];
    for (IESMMEffectTimeRange *range in timeRanges) {
        if (range.rangeID) {
            [rangeIds appendString:range.rangeID];
        }
    }
    return rangeIds;
}


- (void)mapEffectIdForCategoryAndColorDict
{
    //cache category and color corresponded to effect id
    NSMutableDictionary *effectIdAndCategoryDict = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *effectIdAndColorDict = [[NSMutableDictionary alloc] init];
    for (IESCategoryModel *categoryModel in self.effectCategories) {
        for (IESEffectModel *effectModel in categoryModel.effects) {
            if (effectModel.effectIdentifier) {
                if (categoryModel.categoryKey) {
                    [effectIdAndCategoryDict setObject:categoryModel.categoryKey forKey:effectModel.effectIdentifier];
                }
                UIColor *effectColor = [self.effectDataManager maskColorForNormalEffect:effectModel];
                if (effectColor) {
                    [effectIdAndColorDict setObject:effectColor forKey:effectModel.effectIdentifier];
                }
            }
        }
    }
    for (IESEffectModel *effectModel in [self builtinNormalEffects]) {
        if (effectModel.effectIdentifier) {
            [effectIdAndCategoryDict setObject:@"filter" forKey:effectModel.effectIdentifier];
            UIColor *effectColor = [self.effectDataManager maskColorForNormalEffect:effectModel];
            if (effectColor) {
                [effectIdAndColorDict setObject:effectColor forKey:effectModel.effectIdentifier];
            }
        }
    }
    self.effectIdAndCategoryDict = effectIdAndCategoryDict;
    self.effectIdAndColorDict = effectIdAndColorDict;
}

#pragma mark - dataManager
- (void)getBottomTabViewDataWithNetworkRequestBlock:(void (^)(void))networkRequestBlock showCacheBlock:(void (^)(NSArray *categoryArr))showCacheBlock
{
    NSArray *effectCategories = [self normalEffectPlatformModel].categories;
    if (self.publishViewModel.repoCutSame.isNewCutSameOrSmartFilming) {
        NSMutableArray<IESCategoryModel *> *effectCategoriesCopy = [effectCategories mutableCopy];
        for (IESCategoryModel *model in effectCategoriesCopy) {
            if ([model.categoryName isEqual:@"分屏"]) {
                [effectCategoriesCopy removeObject:model];
                break;
            }
        }
        effectCategories = [effectCategoriesCopy copy];
    }
    
    if (effectCategories.count == 0) {
        if (!self.effectDataManager.isFetching) {
            [self.effectDataManager updateNormalEffects];
        }
        if (networkRequestBlock) {
            networkRequestBlock();
        }
    } else {
        if (self.publishViewModel.repoCutSame.isClassicalMV) {
            NSMutableArray *effectCategoriesCopy = [[NSMutableArray alloc] initWithArray:effectCategories];
            for (IESCategoryModel *categoryModel in effectCategories) {
                if ([self p_isStickerCategory:categoryModel.categoryKey]) {
                    [effectCategoriesCopy removeObject:categoryModel];
                    break;
                }
            }
            if (showCacheBlock) {
                showCacheBlock(effectCategoriesCopy);
            }
        } else {
            if (showCacheBlock) {
                showCacheBlock(effectCategories);
            }
        }
    }
}

- (NSArray *)allTimeEffects {
    return [self.effectDataManager allTimeEffects];
}

- (void)resetTimeForbiddenStyle {
    [self.effectDataManager resetTimeForbiddenStyle];
}

- (HTSVideoSepcialEffect *)timeEffectWithType:(HTSPlayerTimeMachineType)type {
    return [self.effectDataManager timeEffectWithType:type];
}

- (UIColor *)timeEffectColorWithType:(HTSPlayerTimeMachineType)type {
    return [self.effectDataManager timeEffectColorWithType:type];
}

- (NSString *)timeEffectDescriptionWithType:(HTSPlayerTimeMachineType)type {
    return [self.effectDataManager timeEffectDescriptionWithType:type];
}

- (AWEEffectFilterPathBlock)effectFilterPathBlock {
    return [self.effectDataManager effectFilterPathBlock];
}

- (IESEffectModel *)normalEffectWithID:(NSString *)effectPathID {
    return [self.effectDataManager normalEffectWithID:effectPathID];
}

- (NSArray<IESEffectModel *> *)builtinNormalEffects; {
    return [self.effectDataManager builtinNormalEffects];
}

- (IESEffectPlatformResponseModel *)normalEffectPlatformModel {
    return [self.effectDataManager normalEffectPlatformModel];
}

#pragma mark - other operation except effect
- (void)clipMusic{
    id<ACCMusicModelProtocol> music = self.publishViewModel.repoMusic.music;
    Float64 duration = CMTimeGetSeconds(self.publishViewModel.repoMusic.bgmAsset.duration);

    let config = IESAutoInline(ACCBaseServiceProvider(), ACCVideoConfigProtocol);
    if (music.shootDuration && [music.shootDuration floatValue] > config.videoMinSeconds) {
        if (ABS(duration - [music.shootDuration integerValue]) >= 1) {
            duration = MIN(duration, [music.shootDuration floatValue]);
        }
    } else {
        if (config.musicMaxSeconds > 0 && duration > config.musicMaxSeconds) {
            duration = config.musicMaxSeconds;
        }
    }

    HTSAudioRange range;

    range.location = 0;
    IESMMVideoDataClipRange *clipRange = self.publishViewModel.repoVideoInfo.video.audioTimeClipInfo[self.publishViewModel.repoMusic.bgmAsset];

    if (clipRange) {
       range.location = clipRange.startSeconds;
    }
    CGFloat totalVideoDuration = [self.publishViewModel.repoVideoInfo.video totalVideoDuration];
    if (self.publishViewModel.repoVideoInfo.video.effect_timeMachineType != HTSPlayerTimeMachineNormal) {
        totalVideoDuration = [self.publishViewModel.repoVideoInfo.video totalVideoDurationAddTimeMachine];
    }
    
    if (self.publishViewModel.repoGame.gameType != ACCGameTypeNone || self.publishViewModel.repoContext.isMVVideo) {
        range.length = MIN(duration, totalVideoDuration);
    } else {
        CGFloat videoMaxDuration = config.videoMaxSeconds;
        if (self.publishViewModel.repoContext.videoSource == AWEVideoSourceAlbum) {
            videoMaxDuration = config.videoUploadMaxSeconds;
        }

        range.length = MIN(MIN(videoMaxDuration, duration), totalVideoDuration);
    }

    IESMMVideoDataClipRange *nClipRange = [IESMMVideoDataClipRange new];
    nClipRange.startSeconds = range.location;
    nClipRange.durationSeconds = range.length;
    // 设置-1代表沿用原range.repeatCount
    nClipRange.repeatCount = -1;
    [self.editService.audioEffect setAudioClipRange:nClipRange forAudioAsset:self.publishViewModel.repoMusic.bgmAsset];
    self.publishViewModel.repoMusic.bgmClipRange = nClipRange;
}

- (NSArray<id<ACCChallengeModelProtocol>> *)currentBindChallenges
{
    NSMutableArray <id<ACCChallengeModelProtocol>> *challenges = [NSMutableArray array];
    
    // 特效平台下发的特效
    [self.publishViewModel.repoVideoInfo.video.effect_timeRange enumerateObjectsUsingBlock:^(IESMMEffectTimeRange * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        IESEffectModel *effectModel = [self normalEffectWithID:obj.effectPathId];
        NSString *challengeId = [effectModel challengeID];
        if (!ACC_isEmptyString(challengeId)) {
            id<ACCChallengeModelProtocol> challenge = [IESAutoInline(ACCBaseServiceProvider(), ACCModelFactoryServiceProtocol) createChallengeModelWithItemID:challengeId challengeName:nil];
            [challenges acc_addObject:challenge];
        }
    }];
    
    // 时间特效
    if (self.publishViewModel.repoVideoInfo.video.effect_timeMachineType != HTSPlayerTimeMachineNormal) {
        id<ACCChallengeModelProtocol> challenge = [IESAutoInline(ACCBaseServiceProvider(), ACCModelFactoryServiceProtocol) createChallengeModelWithItemID:kTimeEffectChallengeBindItemId challengeName:nil];
        [challenges acc_addObject:challenge];
    }
    
    return [challenges copy];
}

@end
