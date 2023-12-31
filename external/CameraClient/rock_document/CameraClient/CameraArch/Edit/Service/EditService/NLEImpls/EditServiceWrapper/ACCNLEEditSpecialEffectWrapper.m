//
//  ACCNLEEditSpecialEffectWrapper.m
//  CameraClient-Pods-Aweme
//
//  Created by HuangHongsen on 2021/2/7.
//

#import "ACCNLEEditSpecialEffectWrapper.h"
#import "ACCEditVideoDataDowngrading.h"
#import "AWERepoVideoInfoModel.h"

#import <NLEPlatform/NLESegmentTimeEffect+iOS.h>
#import <NLEPlatform/NLEInterface.h>
#import <NLEPlatform/NLESegmentEffect+iOS.h>
#import <NLEPlatform/NLEExportSession.h>
#import <NLEPlatform/NLEEffectDrawer.h>

#import "NLEModel_OC+Extension.h"
#import "NLEEditor_OC+Extension.h"
#import "NLETrackSlot_OC+Extension.h"
#import <CreativeKit/ACCMacros.h>
#import <TTVideoEditor/VECurveTransUtils.h>

static NSString * const ACCNLEEditSpecialEffectAudioKey = @"ACCNLEEditSpecialEffectAudioKey";

@interface ACCNLEEditSpecialEffectWrapper ()<ACCEditBuildListener>

@property (nonatomic, weak) NLEInterface_OC *nle;
@property (nonatomic, weak) NLETrackSlot_OC *slot;

@property (nonatomic, strong) AVAsset *reverseAsset;
@property (nonatomic, assign) HTSPlayerTimeMachineType currentTimeMachineType;
@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;

@end

@implementation ACCNLEEditSpecialEffectWrapper

static CMTime ConvertToNLETime(float time) {
    return CMTimeMake(time * USEC_PER_SEC, USEC_PER_SEC);
}

- (void)dealloc
{
}

#pragma mark - ACCEditBuildListener

- (void)setupPublishViewModel:(AWEVideoPublishViewModel *)publishViewModel
{
    self.publishModel = publishViewModel;
}

- (void)onEditSessionInit:(ACCEditSessionWrapper *)editorSession {}

- (void)onNLEEditorInit:(NLEInterface_OC *)editor {
    self.nle = editor;
    NLETrackSlot_OC *timeSlot = [[self.nle.editor getModel] timeEffectTrack].slots.firstObject;
    self.currentTimeMachineType = [self htsTimeMachineTypeFromNLETimeEffectType:timeSlot.timeEffect.timeEffectType];
}

#pragma mark -

- (void)setEditSessionProvider:(nonnull id<ACCEditSessionProvider>)editSessionProvider {
    [editSessionProvider addEditSessionListener:self];
}

#pragma mark - Only use VE

- (BOOL)brushStart
{
    return [self.nle.effectDrawer brushStart];
}

- (BOOL)brushEnd {
    return [self.nle.effectDrawer brushEnd];
}

- (void)removeLastBrush {
    [self.nle.effectDrawer removeLastBrush];
}

- (void)setBrushColorWithRed:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b alpah:(CGFloat)a {
    [self.nle.effectDrawer setBrushColorWithRed:r green:g blue:b alpah:a];
}

- (void)setBrushCanvasAlpha:(CGFloat)alpha
{
    [self.nle.effectDrawer setBrushCanvasAlpha:alpha];
}

- (void)setBrushSize:(CGFloat)size {
    [self.nle.effectDrawer setBrushSize:size];
}

- (NSInteger)currentBrushNumber
{
    return [self.nle.effectDrawer currentBrushNumber];
}

- (CGFloat)getTimeMachineBegineTime:(HTSPlayerTimeMachineType)type
{
    return [self.nle.effectDrawer getTimeMachineBegineTime:type];
}

- (id<IVEEffectProcess>)getVideoProcess
{
    return [self.nle.effectDrawer getVideoProcess];
}

- (void)clearReverseAsset
{
    [self.nle clearEditoReverseAsset];
    self.reverseAsset = nil;
}

- (BOOL)handlePanEventWithTranslation:(CGPoint)translation location:(CGPoint)location {
    return [self.nle.effectDrawer handlePanEventWithTranslation:translation location:location];
}


- (BOOL)handleTouchDown:(CGPoint)location withType:(IESMMGestureType)type {
    return [self.nle.effectDrawer handleTouchDown:location withType:type];
}


- (BOOL)handleTouchEvent:(CGPoint)location {
    return [self.nle.effectDrawer handleTouchEvent:location];
}

- (BOOL)handleTouchUp:(CGPoint)location withType:(IESMMGestureType)type {
    return [self.nle.effectDrawer handleTouchUp:location withType:type];
}

#pragma mark -

- (void)applyTimeMachineWithConfig:(IESMMTimeMachineConfig * _Nonnull)timeMachineConfig {
    
    NLETrack_OC *timeEffectTrack = [[self.nle.editor getModel] timeEffectTrack];
    if (timeEffectTrack == nil) {
        return;
    }
    
    // 时间特效为倒放时，需要重新设置config中的时长(原VE内部初始化数据为3s)
    if (timeMachineConfig.timeMachineType == HTSPlayerTimeMachineReverse) {
        timeMachineConfig.duration = CMTimeGetSeconds([[self.nle.editor getModel] getMeasuredEndTime]);
    }
    
    // 配置时间特效信息
    NLESegmentTimeEffect_OC *timeEffect = [[NLESegmentTimeEffect_OC alloc] init];
    timeEffect.timeEffectType = [self nleTimeEffectTypeFromHtsTimeMachineType:timeMachineConfig.timeMachineType];
    
    // 特效配置
    NLETrackSlot_OC *timeSlot = timeEffectTrack.slots.firstObject;
    if (!timeSlot) {
        timeSlot = [[NLETrackSlot_OC alloc] init];
        [timeEffectTrack addSlot:timeSlot];
    }
    
    timeSlot.segment = timeEffect;
    timeSlot.startTime = ConvertToNLETime(timeMachineConfig.beginTime);
    timeSlot.duration = ConvertToNLETime(timeMachineConfig.duration);
    
    // 更新时间特效信息
    [self p_updateVideoTrackForTimeEffectType:timeMachineConfig.timeMachineType];
    
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)removeAllEffect {
    [[self.nle.editor getModel] removeAllSpecialEffects];
    [self.nle.editor acc_commitAndRender:nil];
}

- (CGFloat)removeEffectWithRangeID:(NSString * _Nonnull)rangeID {
    NSString* slotName = [self.nle slotNameForEffectRangID:rangeID];
    NLETrack_OC *oneTrack = [[self.nle.editor getModel] specialEffectTrack];
    
    CGFloat __block startTime = 0.0;
    [[oneTrack slots] enumerateObjectsUsingBlock:^(NLETrackSlot_OC * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([[obj getName] isEqualToString:slotName]) {
            startTime = CMTimeGetSeconds([obj startTime]);
            [oneTrack removeSlot:obj];
            *stop = YES;
        };
    }];
    
    [self.nle.editor acc_commitAndRender:nil];
    
    return startTime;
}

- (void)restartReverseAsset:(VEReverseCompleteBlock _Nonnull)complete {
    @weakify(self)
    [self.nle.exportSession restartCurrentEditorReverseAsset:^(BOOL success, AVAsset * _Nullable reverseAsset, NSError * _Nullable error) {
        @strongify(self)
        self.reverseAsset = reverseAsset;
        self.timeMachineReady = success;
        ACCBLOCK_INVOKE(complete, success, reverseAsset, error);
    }];
}

- (void)setEffectLoadStatusBlock:(IESStickerStatusBlock _Nonnull)stickerStatusBlock {
    [self.nle setEffectLoadStatusBlock:stickerStatusBlock];
}

- (void)setEffectWidthPathID:(nonnull NSString *)pathID withStartTime:(CGFloat)startTime andStopTime:(CGFloat)stopTime
{
    [self addEffectWithPathID:pathID withStartTime:startTime andStopTime:@(stopTime)];
}

- (void)startEffectWithPathId:(NSString * _Nonnull)pathId withTime:(CGFloat)startTime
{
    [self addEffectWithPathID:pathId withStartTime:startTime andStopTime:nil];
}

- (void)stopEffectwithTime:(CGFloat)stopTime {
    self.slot.endTime = ConvertToNLETime(stopTime);
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)addEffectWithPathID:(nonnull NSString *)pathID withStartTime:(CGFloat)startTime andStopTime:(nullable NSNumber *)stopTime
{
    NLETrack_OC *effectTrack = [[self.nle.editor getModel] specialEffectTrack];
    if (self.slot && CMTimeCompare(self.slot.endTime, kCMTimeZero) == 0) {
        // just delete last slot where end time == 0
        [effectTrack removeSlot:self.slot];
    }
    
    NLEResourceNode_OC *resourceNode_OC = [[NLEResourceNode_OC alloc] init];
    resourceNode_OC.resourceId = pathID;
    resourceNode_OC.resourceType = NLEResourceTypeEffect;
    
    NLESegmentEffect_OC *effectSegment = [[NLESegmentEffect_OC alloc] init];
    effectSegment.effectSDKEffect = resourceNode_OC;
    effectSegment.effectName = pathID;
    
    NLETrackSlot_OC *slot = [[NLETrackSlot_OC alloc] init];
    slot.segment = effectSegment;
    slot.layer = effectTrack.slots.count;
    slot.startTime = ConvertToNLETime(startTime);
    slot.speed = self.currentTimeMachineType == HTSPlayerTimeMachineReverse ? -1.f : 1.f;
    [effectTrack addSlot:slot];
    
    if (stopTime == nil) {
        self.slot = slot;
        slot.endTime = ConvertToNLETime(0.f);
    } else {
        // 规避NLE的判断特效长按的情况
        slot.endTime = ConvertToNLETime([stopTime floatValue]);
    }

    [self.nle.editor acc_commitAndRender:nil];
}

- (void)setTimeMachineReady:(BOOL)timeMachineReady
{
    self.nle.effectDrawer.timeMachineReady = timeMachineReady;
}

- (BOOL)timeMachineReady
{
    return self.nle.effectDrawer.timeMachineReady;
}

- (effectPathBlock)effectPathBlock
{
    return self.nle.effectPathBlock;
}

- (void)setEffectPathBlock:(effectPathBlock _Nonnull)block
{
    [self.nle setEffectPathBlock:block];
    self.publishModel.repoVideoInfo.video.effectFilterPathBlock = block;
}

- (IESComposerJudgeResult *)judgeComposerPriority:(NSString *)newNodePath tag:(NSString *)tag
{
    return [self.nle.effectDrawer judgeComposerPriority:newNodePath tag:tag];
}

- (void)appendComposerNodes:(nonnull NSArray<VEComposerInfo *> *)nodes videoData:(nonnull ACCEditVideoData *)videoData {
    [self.nle.effectDrawer appendComposerNodesWithTags:nodes];
}

- (void)changeSpeedWithVideoData:(nonnull ACCEditVideoData *)videoData xPoints:(nonnull NSArray<NSNumber *> *)xPoints yPoints:(nonnull NSArray<NSNumber *> *)yPoints assetIndex:(NSInteger)assetIndex {
    if (videoData.videoAssets.count <= assetIndex) {
        return;
    }
    
    AVAsset *asset = [videoData.videoAssets objectAtIndex:assetIndex];
    
    CGFloat srcDuration = CMTimeGetSeconds([videoData getVideoDuration:asset]);
    NSArray<NSNumber *> * real_xPoints = [VECurveTransUtils transferVideoPointXtoPlayPointX:xPoints curveSpeedPointY:yPoints];
        
    // 计算曲线变速控制点
    VECurveTransUtils* utils = [[VECurveTransUtils alloc] initWithPoints:real_xPoints yPoints:yPoints srcDuration:srcDuration];
        
    // 构造IESMMCurveSource
    IESMMCurveSource *source = [[IESMMCurveSource alloc] init];
    source.xPoints = xPoints;
    source.yPoints = yPoints;
    source.srcDuration = srcDuration * USEC_PER_SEC;
    source.avgRatio = utils.avgSpeedRatio;
    
    // 设定曲线变速
    [videoData updateVideoCurvesWithCurveSource:source asset:asset];
    [videoData updateVideoTimeScaleInfoWithScale:nil asset:asset]; // 有曲线变速后不应有普通变速
    
    [self.nle.editor acc_commitAndRender:nil];
}


- (void)removeComposerNodes {
    [self.nle.effectDrawer operateComposerNodesWithTags:@[] operation:IESMMComposerNodesOperationSet];
}

- (BOOL)p_updateVideoTrackForTimeEffectType:(HTSPlayerTimeMachineType)timeEffectType
{
    BOOL needUpdateEffectType = NO;
    if (self.currentTimeMachineType == HTSPlayerTimeMachineReverse && timeEffectType != HTSPlayerTimeMachineReverse) {
        needUpdateEffectType = YES;
    } else if (self.currentTimeMachineType != HTSPlayerTimeMachineReverse && timeEffectType == HTSPlayerTimeMachineReverse) {
        needUpdateEffectType = YES;
    }
    self.currentTimeMachineType = timeEffectType;
    return needUpdateEffectType;
}

- (IESMMTimeMachineConfig *)normalTimeMachineConfig
{
    IESMMTimeMachineConfig *normalTimeMachine = [[IESMMTimeMachineConfig alloc] init];
    normalTimeMachine.beginTime = 0.f;
    normalTimeMachine.timeMachineType = HTSPlayerTimeMachineNormal;
    normalTimeMachine.duration = self.nle.totalVideoDuration;
    return normalTimeMachine;
}

/// 是否已经应用上了时光倒流
- (BOOL)hasRewindTimeEffect
{
    NLETrackSlot_OC *timeSlot = [[self.nle.editor getModel] timeEffectTrack].slots.firstObject;
    return timeSlot.timeEffect.timeEffectType == NLESegmentTimeEffectTypeRewind;
}

- (HTSPlayerTimeMachineType)htsTimeMachineTypeFromNLETimeEffectType:(NLESegmentTimeEffectType)timeEffectType
{
    switch (timeEffectType) {
        case NLESegmentTimeEffectTypeNormal:
            return HTSPlayerTimeMachineNormal;
        case NLESegmentTimeEffectTypeRewind:
            return HTSPlayerTimeMachineReverse;
        case NLESegmentTimeEffectTypeSlow:
            return HTSPlayerTimeMachineRelativity;
        case NLESegmentTimeEffectTypeRepeat:
            return HTSPlayerTimeMachineTimeTrap;
        default:
            return HTSPlayerTimeMachineNormal;
    }
}

- (NLESegmentTimeEffectType)nleTimeEffectTypeFromHtsTimeMachineType:(HTSPlayerTimeMachineType)timeMachineType
{
    switch (timeMachineType) {
        case HTSPlayerTimeMachineNormal:
            return NLESegmentTimeEffectTypeNormal;
        case HTSPlayerTimeMachineReverse:
            return NLESegmentTimeEffectTypeRewind;
        case HTSPlayerTimeMachineRelativity:
            return NLESegmentTimeEffectTypeSlow;
        case HTSPlayerTimeMachineTimeTrap:
            return NLESegmentTimeEffectTypeRepeat;
        default:
            return NLESegmentTimeEffectTypeNormal;
    }
}

@end
