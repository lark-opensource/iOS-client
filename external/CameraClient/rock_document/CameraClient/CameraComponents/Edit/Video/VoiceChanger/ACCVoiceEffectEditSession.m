//
//  ACCVoiceEffectEditSession.m
//  Pods
//
//  Created by Shen Chen on 2020/7/20.
//

#import "ACCVoiceEffectEditSession.h"
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import "AWERepoVideoInfoModel.h"

static CGFloat const kACCVoiceEffectPlayerPreciseGap = 0.05;

@interface ACCVoiceEffectEditSession() <ACCEditPreviewMessageProtocol>

@property (nonatomic, strong) IESEffectModel *currentEffect;
@property (nonatomic, assign) NSTimeInterval applyStartTime;
@property (nonatomic, assign) NSTimeInterval previewStopTime;
@property (nonatomic, copy) void (^previewCompletion)(void);
@property (nonatomic, strong) id<ACCEditServiceProtocol> editService;
@property (nonatomic, strong) AWEVideoPublishViewModel *publishViewModel;
@property (nonatomic, strong) NSMutableArray<ACCVoiceEffectSegment *> *segments;
@property (nonatomic, assign) NSInteger initialSegmentCount;
@property (nonatomic, assign) ACCVoiceEffectEditSessionState state;
@property (nonatomic, strong) ACCSegmentBlender *segmentBlender;
@end

@implementation ACCVoiceEffectEditSession

- (instancetype)initWithEditService:(id<ACCEditServiceProtocol>)editService
                   publishViewModel:(AWEVideoPublishViewModel *)publishViewModel
{
    self = [super init];
    if (self) {
        self.editService = editService;
        self.state = ACCVoiceEffectEditSessionStateIdle;
        self.publishViewModel = publishViewModel;
        self.segments = [NSMutableArray array];
    }
    return self;
}

- (ACCSegmentBlender *)segmentBlender
{
    if (!_segmentBlender) {
        _segmentBlender = [[ACCSegmentBlender alloc] init];
    }
    return _segmentBlender;
}

- (void)loadSegments:(NSArray<ACCVoiceEffectSegment *> *)segments
{
    self.initialSegmentCount = segments.count;
    self.segments = segments.count > 0 ? [segments mutableCopy] : [NSMutableArray array];
}

- (NSArray<ACCVoiceEffectSegment *> *)currentSegments
{
    return self.segments.copy;
}

- (NSArray<ACCVoiceEffectSegment *> *)currentNonOverlappingSegments
{
    NSArray<ACCVoiceEffectSegment *> *segments = (NSArray<ACCVoiceEffectSegment *> *)[self.segmentBlender blendItems:self.segments];
    NSMutableArray<ACCVoiceEffectSegment *> *final = [NSMutableArray array];
    [segments enumerateObjectsUsingBlock:^(ACCVoiceEffectSegment * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.effectId.length) {
            [final addObject:obj];
        }
    }];
    return final;
}

- (void)startPreviewEffect:(IESEffectModel *)effect duration:(NSTimeInterval)duration completion:(void (^)(void))completion
{
    if (self.state == ACCVoiceEffectEditSessionStateInPreview) {
        @weakify(self);
        [self stopPreviewWithCompletion: ^{
            @strongify(self);
            [self startPreviewEffect:effect duration:duration completion:completion];
        }];
    } else if (self.state != ACCVoiceEffectEditSessionStateIdle) {
        return;
    }
    self.state = ACCVoiceEffectEditSessionStateInPreview;
    self.applyStartTime = self.editService.preview.currentPlayerTime;
    self.previewStopTime = self.applyStartTime + duration;
    self.previewCompletion = completion;
    [self.editService.preview addSubscriber:self];
    [self startTemporaryEffect:effect];
}

- (void)stopPreviewWithCompletion:(void (^_Nullable)(void))completion
{
    [self stopTemporaryEffect];
    @weakify(self);
    [self.editService.preview seekToTime:CMTimeMakeWithSeconds(self.applyStartTime, USEC_PER_SEC) completionHandler:^(BOOL finished) {
        @strongify(self);
        self.state = ACCVoiceEffectEditSessionStateIdle;
        if (completion) {
            completion();
        }
    }];
}

- (void)startApplyEffect:(IESEffectModel *)effect
{
    if (self.state != ACCVoiceEffectEditSessionStateIdle) {
        return;
    }
    self.state = ACCVoiceEffectEditSessionStateApplying;
    self.applyStartTime = self.editService.preview.currentPlayerTime;
    self.currentEffect = effect;
    [self startTemporaryEffect:effect];
}

- (void)stopApplyEffectWithCompletion:(void (^_Nullable)(void))completion
{
    if (self.state != ACCVoiceEffectEditSessionStateApplying) {
        return;
    }
    [self stopTemporaryEffect];
    
    //apply real filter
    NSTimeInterval currentTime = self.editService.preview.currentPlayerTime;
    NSTimeInterval totalVideoDuration = [self.publishViewModel.repoVideoInfo.video totalVideoDuration];
    if (currentTime + kACCVoiceEffectPlayerPreciseGap > totalVideoDuration) {
        currentTime = totalVideoDuration;
    }
    if (currentTime > self.applyStartTime) {
        ACCVoiceEffectSegment *segment = [[ACCVoiceEffectSegment alloc] initWithStartTime:self.applyStartTime duration:currentTime - self.applyStartTime effect:self.currentEffect];
        [self.segments addObject:segment];
    }
    
    @weakify(self);
    [self updateVoiceEffectsWithCompletion:^{
        @strongify(self);
        self.state = ACCVoiceEffectEditSessionStateIdle;
        if (completion) {
            completion();
        }
    }];
}

- (void)updateVoiceEffectsWithCompletion:(void (^_Nullable)(void))completion
{
    // get effective audio filters
    NSMutableArray<IESMMAudioFilter *> *audioFilters = [NSMutableArray array];
    NSMutableArray<IESEffectModel *> *effects = [NSMutableArray array];
    for (ACCVoiceEffectSegment *segment in self.segments) {
        [audioFilters addObject:[self audioFilterForEffectSegment:segment]];
        if (segment.effect) {
            [effects addObject:segment.effect];
        }
    }
    NSArray<IESMMAudioFilter *> *effectiveFilters = [IESMMAudioFilterUtils caculateEffectiveFilters:audioFilters];
    [self.editService.audioEffect updateAudioFilters:effectiveFilters withEffects:effects forVideoAssetsWithcompletion:completion];
}

- (void)cancelActionsAndSeekBackCompletion:(void (^_Nullable)(void))completion
{
    if (self.state != ACCVoiceEffectEditSessionStateIdle) {
        [self stopTemporaryEffect];
        @weakify(self);
        [self.editService.preview seekToTime:CMTimeMakeWithSeconds(self.applyStartTime, USEC_PER_SEC) completionHandler:^(BOOL finished) {
            @strongify(self);
            if (self.state == ACCVoiceEffectEditSessionStateInPreview && self.previewCompletion != nil) {
                self.previewCompletion();
            }
            self.state = ACCVoiceEffectEditSessionStateIdle;
            self.previewCompletion = nil;
            if (completion) {
                completion();
            }
        }];
    } else {
        if (completion) {
            completion();
        }
    }
}

- (void)revokeLastEffect
{
    [self.segments removeLastObject];
    [self updateVoiceEffectsWithCompletion:nil];
}

- (BOOL)hasNewEdits
{
    return self.segments.count - self.initialSegmentCount != 0;
}

#pragma mark - Private

- (IESMMAudioFilter *)audioFilterForEffectSegment:(ACCVoiceEffectSegment *)segment
{
    IESMMAudioPitchConfigV2 *config = [IESMMAudioPitchConfigV2 new];
    config.effectPath = [self effectPathForEffect:segment.effect];
    IESMMAudioFilter *audioFilter = [IESMMAudioFilter new];
    audioFilter.config = config.effectPath.length > 0 ? config : nil;
    audioFilter.type = IESAudioFilterTypePitch;
    audioFilter.attachTime = CMTimeMakeWithSeconds(segment.startTime, USEC_PER_SEC);
    audioFilter.duration = CMTimeMakeWithSeconds(segment.duration, USEC_PER_SEC);
    return audioFilter;
}

- (NSString *)effectPathForEffect:(IESEffectModel *)effect
{
    if (effect.effectIdentifier) {
        if (effect.localUnCompressPath.length) {
            return effect.localUnCompressPath;
        } else if (effect.downloaded) {
            return effect.filePath;
        }
    }
    return nil;
}

- (void)startTemporaryEffect:(IESEffectModel *)effect
{
    [self.editService.preview pause];
    self.editService.preview.autoRepeatPlay = NO;
    @weakify(self)
    [self.editService.audioEffect startAudioFilterPreview:effect completion:^{
        @strongify(self)
            [self.editService.preview play];
    }];
}

- (void)stopTemporaryEffect
{
    [self.editService.audioEffect stopFiltersPreview];
    self.editService.preview.autoRepeatPlay = YES;
    [self.editService.preview pause];
}

- (void)movieDidChangePlaytime:(NSTimeInterval)time
{
    [self stopPreviewIfShould];
}

- (void)movieDidChangePlayStatus:(HTSPlayerStatus)status
{
    [self stopPreviewIfShould];
}

- (void)stopPreviewIfShould
{
    if (self.state == ACCVoiceEffectEditSessionStateInPreview && (self.editService.preview.currentPlayerTime >= self.previewStopTime || self.editService.preview.currentPlayerTime >= self.publishViewModel.repoVideoInfo.video.totalVideoDuration - kACCVoiceEffectPlayerPreciseGap)) {
        [self stopPreviewWithCompletion:self.previewCompletion];
    }
}

#pragma mark - ACCEditPreviewMessageProtocol

- (void)playerCurrentPlayTimeChanged:(NSTimeInterval)currentTime
{
    [self movieDidChangePlaytime:currentTime];
}

- (void)playStatusChanged:(HTSPlayerStatus)status
{
    [self stopPreviewIfShould];
}

@end
