//
//  ACCEditEffectWraper.m
//  CameraClient
//
//  Created by haoyipeng on 2020/9/8.
//

#import "ACCEditEffectWraper.h"
#import "ACCEditVideoDataDowngrading.h"
#import <TTVideoEditor/VEEditorSession+Effect.h>
#import <TTVideoEditor/VECurveTransUtils.h>

@interface ACCEditEffectWraper () <ACCEditBuildListener>

@property (nonatomic, weak) VEEditorSession *player;

@end

@implementation ACCEditEffectWraper

- (void)setEditSessionProvider:(id<ACCEditSessionProvider>)editSessionProvider
{
    [editSessionProvider addEditSessionListener:self];
}

#pragma mark - ACCEditBuildListener

- (void)onEditSessionInit:(ACCEditSessionWrapper *)editSession
{
    self.player = editSession.videoEditSession;
}

- (void)setTimeMachineReady:(BOOL)timeMachineReady
{
    self.player.timeMachineReady = timeMachineReady;
}

- (BOOL)timeMachineReady
{
    return self.player.timeMachineReady;
}

- (id<IVEEffectProcess>)getVideoProcess
{
    return [self.player getVideoProcess];
}

- (void)removeAllEffect
{
    [self.player removeAllEffect];
}

- (void)clearReverseAsset
{
    [self.player clearReverseAsset];
}

- (void)setEffectPathBlock:(effectPathBlock _Nonnull)block
{
    [self.player setEffectPathBlock:block];
}

- (void)applyTimeMachineWithConfig:(IESMMTimeMachineConfig *)timeMachineConfig
{
    [self.player applyTimeMachineWithConfig:timeMachineConfig];
}

- (void)setBrushCanvasAlpha:(CGFloat)alpha
{
    [self.player setBrushCanvasAlpha:alpha];
}

- (NSInteger)currentBrushNumber
{
    return [self.player currentBrushNumber];
}

- (void)setEffectLoadStatusBlock:(IESStickerStatusBlock)stickerStatusBlock
{
    [self.player setEffectLoadStatusBlock:stickerStatusBlock];
}

- (void)stopEffectwithTime:(CGFloat)stopTime
{
    [self.player stopEffectwithTime:stopTime];
}

- (void)restartReverseAsset:(VEReverseCompleteBlock)complete
{
    [self.player restartReverseAsset:complete];
}

- (CGFloat)removeEffectWithRangeID:(NSString *_Nonnull)rangeID
{
    return [self.player removeEffectWithRangeID:rangeID];
}

- (void)startEffectWithPathId:(NSString *_Nonnull)pathId withTime:(CGFloat)startTime
{
    [self.player startEffectWithPathId:pathId withTime:startTime];
}

- (void)setEffectWidthPathID:(NSString *)pathID withStartTime:(CGFloat)startTime andStopTime:(CGFloat)stopTime
{
    if (stopTime == CGFLOAT_MAX) { // prevent overflow in vesdk
        stopTime = 1000000000;
    }
    [self.player setEffectWithPathId:pathID withStartTime:startTime andStopTime:stopTime];
}

- (CGFloat)getTimeMachineBegineTime:(HTSPlayerTimeMachineType)type
{
    return [self.player getTimeMachineBegineTime:type];
}

- (BOOL)brushStart
{
    return [self.player brushStart];
}

- (BOOL)brushEnd {
    return [self.player brushEnd];
}


- (void)removeLastBrush {
    [self.player removeLastBrush];
}


- (void)setBrushColorWithRed:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b alpah:(CGFloat)a {
    [self.player setBrushColorWithRed:r green:g blue:b alpah:a];
}


- (void)setBrushSize:(CGFloat)size {
    [self.player setBrushSize:size];
}

- (BOOL)handlePanEventWithTranslation:(CGPoint)translation location:(CGPoint)location {
    return [self.player handlePanEventWithTranslation:translation location:location];
}


- (BOOL)handleTouchDown:(CGPoint)location withType:(IESMMGestureType)type {
    return [self.player handleTouchDown:location withType:type];
}


- (BOOL)handleTouchEvent:(CGPoint)location {
    return [self.player handleTouchEvent:location];
}


- (BOOL)handleTouchUp:(CGPoint)location withType:(IESMMGestureType)type {
    return [self.player handleTouchUp:location withType:type];
}

- (nonnull effectPathBlock)effectPathBlock { 
    return NULL;
}
- (IESComposerJudgeResult *)judgeComposerPriority:(NSString *)newNodePath tag:(NSString *)tag
{
    return [self.player judgeComposerPriority:newNodePath tag:tag];
}

- (void)appendComposerNodes:(NSArray<VEComposerInfo *> *)nodes videoData:(ACCEditVideoData *)videoData
{
    [self.player appendComposerNodesWithTags:nodes];
    [self.player dumpComposerNodes:acc_videodata_take_hts(videoData)];
}

- (void)removeComposerNodes
{
    [self.player operateComposerNodesWithTags:@[] operation:IESMMComposerNodesOperationSet];
}

- (void)changeSpeedWithVideoData:(ACCEditVideoData *)videoData xPoints:(NSArray <NSNumber *>*)xPoints yPoints:(NSArray <NSNumber *>*)yPoints assetIndex:(NSInteger)assetIndex
{
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
    videoData.maxTrackDuration = [videoData totalVideoDuration];
}

@end
