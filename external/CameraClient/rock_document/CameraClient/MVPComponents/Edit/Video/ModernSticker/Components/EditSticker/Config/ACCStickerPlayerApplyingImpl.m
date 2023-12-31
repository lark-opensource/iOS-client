//
//  ACCStickerPlayerApplyingImpl.m
//  CameraClient-Pods-Aweme
//
//  Created by aloes on 2020/8/25.
//

#import "AWERepoVideoInfoModel.h"
#import "AWERepoContextModel.h"
#import "AWERepoStickerModel.h"
#import "ACCStickerPlayerApplyingImpl.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import "ACCStickerServiceProtocol.h"
#import "ACCEditPreviewProtocolD.h"
#import <CreativeKit/ACCProtocolContainer.h>
#import <CameraClient/AWEInteractionStickerModel+DAddition.h>
#import <CameraClient/ACCEditVideoDataDowngrading.h>
#import <CameraClientModel/ACCVideoCanvasType.h>

static CGFloat const kAWEStickerTotalDuration = -1;

@interface ACCStickerPlayerApplyingImpl () <ACCEditPreviewMessageProtocol>

@property (nonatomic, assign, readwrite) CGFloat currentPlayerTime;

@end

@implementation ACCStickerPlayerApplyingImpl

- (CGFloat)currentPlayerTime
{
    return [self.editService.preview currentPlayerTime];
}

- (ACCEditVideoData *)videoData
{
    return self.repository.repoVideoInfo.video;
}

- (CGFloat)stickerInitialEndTime
{
    CGFloat seconds = self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeSinglePhoto ? 9999.0 : self.repository.repoVideoInfo.video.totalVideoDuration;
    return seconds * 1000;
}

- (CGRect)playerFrame
{
    return self.repository.repoVideoInfo.playerFrame;
}

- (void)setHighFrameRateRender:(BOOL)enalbe
{
    [self.editService.preview setHighFrameRateRender:enalbe];
}

- (void)setStickerEditMode:(BOOL)mode
{
    [self.editService.preview setStickerEditMode:mode];
}

- (void)resetPlayerWithViews:(NSArray<UIView *> *)views
{
    [self.editService.preview resetPlayerWithViews:views];
}

- (void)updateVideoData:(ACCEditVideoData *_Nonnull)videoData mvModel:(ACCEditMVModel *_Nonnull)mvModel completeBlock:(void (^_Nullable)(NSError *_Nullable error))completeBlock
{
    [ACCGetProtocol(self.editService.preview, ACCEditPreviewProtocolD) updateVideoData:videoData mvModel:mvModel completeBlock:completeBlock];
}
#pragma mark - Sticker

- (void)getStickerId:(NSInteger)stickerId props:(IESInfoStickerProps *)props
{
    [self.editService.sticker getStickerId:stickerId props:props];
}

- (CGSize)getInfoStickerSize:(NSInteger)stickerId
{
    return [self.editService.sticker getInfoStickerSize:stickerId];
}

- (CGSize)getstickerEditBoxSize:(NSInteger)stickerId
{
    return [self.editService.sticker getstickerEditBoxSize:stickerId];
}

- (void)setStickerAbove:(NSInteger)stickerId
{
    [self.editService.sticker setStickerAbove:stickerId];
}

//代码结构很稳定，不要乱动！！！
//视频大小变化的时候，修正StickerLocation信息，防止跟feed页交互出现误差
- (AWEInteractionStickerLocationModel * _Nullable)resetStickerLocation:(AWEInteractionStickerLocationModel * _Nullable)location isRecover:(BOOL)isRecover
{
    if (!location) {
        return nil;
    }
    
    CGSize oldSize = self.editService.mediaContainerView.originalPlayerFrame.size;
    CGSize newSize = self.editService.mediaContainerView.editPlayerFrame.size;
    BOOL ifHasSrtInfoSticker = NO;
    
    // 歌词贴纸当前会直接改变横屏视频的分辨率，先对该情况做特殊处理
    for (IESInfoSticker *stickerView in self.editService.sticker.infoStickers) {
        if (stickerView.isSrtInfoSticker == YES) {
            ifHasSrtInfoSticker = YES;
        }
    }

    if ((self.repository.repoSticker.adjustTo9V16EditFrame &&
        newSize.width > 0 && newSize.height > 0) || ifHasSrtInfoSticker == YES) {
        CGFloat oldHeight = isRecover ? newSize.width * 16.f/9.f : newSize.height;
        CGFloat newHeight = isRecover ? newSize.height : newSize.width * 16.f/9.f;
        // 有黑边并且黑边有贴纸的视频，视频是9:16的，但是可编辑区域不是9:16，需要坐标转换
        AWEInteractionStickerLocationModel *targetLocation = [location copy];
        CGFloat y = [location.y floatValue];
        CGFloat height = [location.height floatValue];
        y = (y * oldHeight - (oldHeight - newHeight) / 2.0) / newHeight;
        height = height * oldHeight / newHeight;
        targetLocation.y = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", y]];
        targetLocation.height = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", height]];
        return targetLocation;
    }
    
    if ((!self.isIMRecord && [self.stickerService isAllStickersInPlayer]) || isRecover) {
        AWEInteractionStickerLocationModel *targetLocation = [location copy];
        
        CGFloat x = [location.x floatValue];
        CGFloat y = [location.y floatValue];
        CGFloat width = [location.width floatValue];
        CGFloat height = [location.height floatValue];
        if (isRecover) {
            oldSize = self.editService.mediaContainerView.editPlayerFrame.size;
            newSize = self.editService.mediaContainerView.originalPlayerFrame.size;
        }
        
        if (oldSize.width == 0 || oldSize.height == 0) {
            return targetLocation;
        }
        
        x = (x * newSize.width - (newSize.width - oldSize.width) / 2.0) / oldSize.width;
        y = (y * newSize.height - (newSize.height - oldSize.height) / 2.0) / oldSize.height;
        width = width * newSize.width / oldSize.width;
        height = height * newSize.height / oldSize.height;
        
        targetLocation.x = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", x]];
        targetLocation.y = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", y]];
        targetLocation.width = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", width]];
        targetLocation.height = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", height]];
        targetLocation.startTime = location.startTime;
        targetLocation.endTime = location.endTime;
        targetLocation.isRatioCoord = location.isRatioCoord;
        
        return targetLocation;
    }
    return location;
}

- (NSInteger)addInfoSticker:(NSString *)path withEffectInfo:(NSArray *)effectInfo userInfo:(NSDictionary *)userInfo
{
    return [self.editService.sticker addInfoSticker:path withEffectInfo:effectInfo userInfo:userInfo];
}

- (NSInteger)addTextStickerWithUserInfo:(NSDictionary *)userInfo
{
    return [self.editService.sticker addTextStickerWithUserInfo:userInfo];
}

- (void)setSticker:(NSInteger)stickerId startTime:(CGFloat)startTime duration:(CGFloat)duration
{
    // 尝试解决 AME-23902：贴纸偶现闪一下消失
    if (ACC_FLOAT_LESS_THAN(duration, 1.0)) {
        duration = kAWEStickerTotalDuration;
    }
    if (ACC_FLOAT_EQUAL_TO(duration, self.repository.repoVideoInfo.video.totalVideoDuration)) {
        duration = kAWEStickerTotalDuration;
    }
    [self.editService.sticker setSticker:stickerId startTime:startTime duration:duration];
}

- (void)setSticker:(NSInteger)stickerId offsetX:(CGFloat)offsetX offsetY:(CGFloat)offsetY angle:(CGFloat)angle scale:(CGFloat)scale
{
    [self.editService.sticker setSticker:stickerId offsetX:offsetX offsetY:offsetY angle:angle scale:scale];
}

- (void)setSticker:(NSInteger)stickerId offsetX:(CGFloat)offsetX offsetY:(CGFloat)offsetY
{
    [self.editService.sticker setSticker:stickerId offsetX:offsetX offsetY:offsetY];
}

- (void)setSticker:(NSInteger)stickerId angle:(CGFloat)angle
{
    [self.editService.sticker setStickerAngle:stickerId angle:angle];
}

- (void)setStickerScale:(NSInteger)stickerId scale:(CGFloat)scale
{
    [self.editService.sticker setStickerScale:stickerId scale:scale];
}

- (void)setStickerLayer:(NSInteger)stickerId layer:(NSInteger)layer
{
    [self.editService.sticker setStickerLayer:stickerId layer:layer];
}

- (void)setSticker:(NSInteger)stickerId alpha:(CGFloat)alpha
{
    [self.editService.sticker setSticker:stickerId alpha:alpha];
}

- (void)setTextSticker:(NSInteger)stickerId textParams:(NSString *)textParams
{
    [self.editService.sticker setTextStickerTextParams:stickerId textParams:textParams];
}

- (void)setFixTopInfoSticker:(NSInteger)stickerId
{
    self.editService.sticker.fixedTopInfoSticker = stickerId;
}

- (void)removeInfoSticker:(NSInteger)stickerId
{
    [self.editService.sticker removeInfoSticker:stickerId];
}

- (void)removeStickerWithType:(ACCEditEmbeddedStickerType)stickerType {
    [self.repository.repoVideoInfo.video.infoStickers enumerateObjectsUsingBlock:^(IESInfoSticker * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.acc_stickerType == stickerType) {
            [self.editService.sticker removeInfoSticker:obj.stickerId];
        }
    }];
}

#pragma mark - Text

- (void)setBrushCanvasAlpha:(CGFloat)alpha
{
    [self.editService.effect setBrushCanvasAlpha:alpha];
}

- (NSInteger)currentBrushNumber
{
    return [self.editService.effect currentBrushNumber];
}

#pragma mark - player

- (BOOL)needAdaptPlayer
{
    return [self.stickerService needAdaptPlayer] || [self.stickerService needAdapterTo9V16FrameForPublish];
}

- (void)resetPlayerWithView:(NSArray<UIView *> *)views
{
    [self.editService.preview resetPlayerWithViews:views];
}

- (void)play
{
    [self.editService.preview play];
}

- (void)continuePlay
{
    [self.editService.preview continuePlay];
}

- (void)pause
{
    [self.editService.preview pause];
}

- (void)seekToTime:(CMTime)time
{
    [self.editService.preview seekToTime:time];
}

- (void)seekToTimeAndRender:(CMTime)time
{
    [self.editService.preview seekToTime:time];
}

- (void)seekToTimeAndRender:(CMTime)time completionHandler:(nullable void (^)(BOOL finished))completionHandler
{
    [self.editService.preview seekToTime:time completionHandler:completionHandler];
}

#pragma mark - Preview Image

- (void)getSourcePreviewImageAtTime:(NSTimeInterval)atTime preferredSize:(CGSize)size compeletion:(void(^)(UIImage *image, NSTimeInterval atTime))compeletion
{
    [self.editService.captureFrame getSourcePreviewImageAtTime:atTime preferredSize:size compeletion:compeletion];
}

- (IESVideoAddEdgeData *)previewEdge
{
    return self.editService.preview.previewEdge;
}

#pragma mark - Audio

- (void)setAudioClipRange:(IESMMVideoDataClipRange *)range forAudioAsset:(AVAsset *)asset {
    [self.editService.audioEffect setAudioClipRange:range forAudioAsset:asset];
}

#pragma mark -

- (void)setEditService:(id<ACCEditServiceProtocol>)editService
{
    _editService = editService;
    
    
    [self.editService.preview addSubscriber:self];
}

#pragma mark - ACCEditPreviewMessageProtocol

- (void)playerCurrentPlayTimeChanged:(NSTimeInterval)currentTime
{
    self.currentPlayerTime = currentTime;
}

@end
