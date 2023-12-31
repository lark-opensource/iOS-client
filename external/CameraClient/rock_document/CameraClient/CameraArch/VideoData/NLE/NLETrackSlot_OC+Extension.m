//
//  NLETrackSlot_OC+Extension.m
//  CameraClient-Pods-Aweme
//
//  Created by geekxing on 2021/1/19.
//

#import "NLETrackSlot_OC+Extension.h"
#import "NLEResourceAV_OC+Extension.h"
#import <NLEPlatform/NLESegmentSubtitleSticker+iOS.h>
#import <NLEPlatform/NLESegmentInfoSticker+iOS.h>
#import <NLEPlatform/NLEStyleText+iOS.h>
#import <NLEPlatform/NLESegmentMV+iOS.h>
#import <NLEPlatform/NLEModel+iOS.h>
#import <NLEPlatform/NLESegmentImageVideoAnimation+iOS.h>

#import <TTVideoEditor/IESMMVideoTransformInfo.h>
#import <TTVideoEditor/IESMMVideoDataClipRange.h>
#import <TTVideoEditor/IESMMMVModel.h>
#import <TTVideoEditor/IESMMBlankResource.h>
#import <TTVideoEditor/IESMediaInfo.h>
#import <TTVideoEditor/IESMMCanvasConfig.h>
#import <TTVideoEditor/IESMMCanvasSource.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/NSData+ACCAdditions.h>
#import <CreationKitArch/ACCEditAndPublishConstants.h>
#import <CreationKitInfra/ACCLogProtocol.h>

#import "IESInfoSticker+ACCAdditions.h"
#import "AWEAssetModel.h"

static NSString *kMovieInputFillTypeKey = @"acc_ios_movieInputFillType";
static NSString *kAssetRotationInfoKey = @"acc_ios_assetRotationInfo";
static NSString *kBingoKey = @"acc_ios_bingoKey";
const CGFloat kACCMVDefaultSecond = 3.0;

static uint32_t ACCColorToUint32(UIColor *color){
    CGFloat red, green, blue, alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    
    uint32_t uintAlpha = alpha * 0xFF;
    uint32_t uintRed = red * 0xFF;
    uint32_t uintGreen = green * 0xFF;
    uint32_t uintBlue = blue * 0xFF;
    return (uintAlpha << 24) | (uintRed << 16) | (uintGreen << 8) | (uintBlue << 0);
}

static UIColor * ACCUint32ToColor(uint32_t color){
    return [UIColor colorWithRed:(color >> 16 & 0xFF) / 255.0
                           green:(color >> 8 & 0xFF) / 255.0
                            blue:(color & 0xFF) / 255.0
                           alpha:(color >> 24 & 0xFF) / 255.0];;
}

inline CMTime ACCCMTimeMakeSeconds(float seconds) {
    return CMTimeMake(seconds * USEC_PER_SEC, USEC_PER_SEC);
}

@implementation NLETrackSlot_OC (Extension)

+ (instancetype)videoTrackSlotWithAsset:(AVAsset *)asset nle:(NLEInterface_OC *)nle
{
    NLEResourceAV_OC *resource = [NLEResourceAV_OC videoResourceWithAsset:asset nle:nle];
    NLESegmentVideo_OC *videoSegment = [[NLESegmentVideo_OC alloc] init];
    videoSegment.videoFile = resource;
    videoSegment.timeClipStart = kCMTimeZero;
    videoSegment.timeClipEnd = resource.duration;
    
    NLETrackSlot_OC *trackSlot = [[NLETrackSlot_OC alloc] init];
    [trackSlot setSegmentVideo:videoSegment];
    [trackSlot resetVideoClipRange];
    return trackSlot;
}

+ (instancetype)videoTrackSlotWithPictureURL:(NSURL *)pictureURL nle:(NLEInterface_OC *)nle
{
    AVAsset *blankAsset = [IESMMBlankResource getEmptyAVAsset];
    blankAsset.frameImageURL = pictureURL;
    return [self videoTrackSlotWithAsset:blankAsset nle:nle];
}

+ (instancetype)videoTrackSlotWithPictureURL:(NSURL *)pictureURL duration:(CGFloat)duration nle:(NLEInterface_OC *)nle
{
    AVAsset *blankAsset = [IESMMBlankResource getBlackVideoAsset];
    blankAsset.frameImageURL = pictureURL;
    NLETrackSlot_OC *trackSlot = [self videoTrackSlotWithAsset:blankAsset nle:nle];
    trackSlot.videoSegment.timeClipEnd = ACCCMTimeMakeSeconds(duration);
    return trackSlot;
}

+ (instancetype)audioTrackSlotWithAsset:(AVAsset *)asset nle:(NLEInterface_OC *)nle
{
    NLEResourceAV_OC *resource = [NLEResourceAV_OC audioResourceWithAsset:asset nle:nle];
    NLESegmentAudio_OC *audioSegment = [[NLESegmentAudio_OC alloc] init];
    audioSegment.audioFile = resource;

    NLETrackSlot_OC *slot = [[NLETrackSlot_OC alloc] init];
    [slot setSegmentAudio:audioSegment];
    [slot resetAudioClipRange];
    return slot;
}

- (BOOL)isRelatedWithVideoAsset:(AVAsset *)asset
{
    if (![asset isKindOfClass:[AVURLAsset class]]) {
        return NO;
    }
    
    if (self.videoSegment.videoFile.resourceType == NLEResourceTypeImage) {
        return [self.videoSegment.videoFile isRelatedPath:((AVURLAsset *)asset).frameImageURL.path];
    } else {
        return [self.videoSegment.videoFile isRelatedPath:((AVURLAsset *)asset).URL.path];
    }
}

- (BOOL)isRelatedWithAudioAsset:(AVAsset *)asset
{
    if (![asset isKindOfClass:[AVURLAsset class]]) {
        return NO;
    }
    return [self.audioSegment.audioFile isRelatedPath:((AVURLAsset *)asset).URL.path];
}

- (void)resetAudioClipRange
{
    if (self.audioSegment == nil) {
        return;
    }
    
    self.audioSegment.repeatCount = 1;
    self.audioSegment.timeClipStart = kCMTimeZero;
    self.audioSegment.timeClipEnd = [[self audioSegment] audioFile].duration;
}

- (void)setAudioClipRange:(IESMMVideoDataClipRange *)clipRange
{
    if ([self audioSegment] == nil) {
        return;
    }
    
    if (clipRange == nil) {
        [self resetAudioClipRange];
        return;
    }
    
    self.startTime = ACCCMTimeMakeSeconds(clipRange.attachSeconds);
    self.audioSegment.repeatCount = clipRange.repeatCount;
    self.audioSegment.timeClipStart = ACCCMTimeMakeSeconds(clipRange.startSeconds);
    self.audioSegment.timeClipEnd = ACCCMTimeMakeSeconds(clipRange.endSeconds);
    self.audioSegment.enable = !clipRange.isDisable;
}

- (IESMMVideoDataClipRange *)audioClipRange
{
    if (self.audioSegment == nil) {
        return nil;
    }
    
    IESMMVideoDataClipRange *clipRange = [[IESMMVideoDataClipRange alloc] init];
    clipRange.attachSeconds = CMTimeGetSeconds(self.startTime);
    clipRange.startSeconds = CMTimeGetSeconds(self.audioSegment.timeClipStart);
    clipRange.durationSeconds = CMTimeGetSeconds(self.audioSegment.timeClipEnd) - CMTimeGetSeconds(self.audioSegment.timeClipStart);
    clipRange.repeatCount = self.audioSegment.repeatCount;
    clipRange.isDisable = !self.audioSegment.isEnable;
    return clipRange;
}

- (void)resetVideoClipRange
{
    if (self.videoSegment == nil) {
        return;
    }
    
    self.videoSegment.repeatCount = 1;
    self.videoSegment.timeClipStart = kCMTimeZero;
    self.videoSegment.timeClipEnd = [[self videoSegment] audioFile].duration;
}

- (void)setVideoClipRange:(IESMMVideoDataClipRange *)clipRange
{
    if (self.videoSegment == nil) {
        return;
    }
    
    if (clipRange == nil) {
        [self resetVideoClipRange];
        return;
    }
    
    self.videoSegment.timeClipStart = ACCCMTimeMakeSeconds(clipRange.startSeconds);
    self.videoSegment.timeClipEnd = ACCCMTimeMakeSeconds(clipRange.endSeconds);
    self.enable = !clipRange.isDisable;
}

- (IESMMVideoDataClipRange *)videoClipRange
{
    if (self.videoSegment == nil) {
        return nil;
    }
    
    IESMMVideoDataClipRange *clipRange = [[IESMMVideoDataClipRange alloc] init];
    clipRange.startSeconds = CMTimeGetSeconds(self.videoSegment.timeClipStart);
    clipRange.durationSeconds = CMTimeGetSeconds(self.videoSegment.timeClipEnd) - CMTimeGetSeconds(self.videoSegment.timeClipStart);
    clipRange.isDisable = !self.isEnable;
    return clipRange;
}

- (void)setVideoTransform:(IESMMVideoTransformInfo *)videoTransform
{
    // 只提供给照片电影使用
    if (self.videoSegment.getResNode.resourceType != NLEResourceTypeImage) {
        return;
    }
    
    if (videoTransform == nil) {
        [self clearVideoAnim];
        return;
    }
    
    NLESegmentImageVideoAnimation_OC *anim = [[NLESegmentImageVideoAnimation_OC alloc] init];
    [anim setBeginScale:videoTransform.startTrasformInfo.xScale];
    [anim setEndScale:videoTransform.endTransformInfo.xScale];
    anim.animationDuration = ACCCMTimeMakeSeconds(videoTransform.duration);
    
    NLEVideoAnimation_OC *videoAnimation = [[NLEVideoAnimation_OC alloc] init];
    videoAnimation.segmentVideoAnimation = anim;
    videoAnimation.startTime = ACCCMTimeMakeSeconds(videoTransform.startTime);
    
    [self clearVideoAnim];
    [self addVideoAnim:videoAnimation];
}

- (IESMMVideoTransformInfo *)videoTransform
{
    if (self.videoSegment.getResNode.resourceType != NLEResourceTypeImage) {
        return nil;
    }
    
    NLEVideoAnimation_OC *videoAnimation = [[self getVideoAnims] firstObject];
    NLESegmentImageVideoAnimation_OC *animation = nil;
    if ([videoAnimation.segmentVideoAnimation isKindOfClass:NLESegmentImageVideoAnimation_OC.class]) {
        animation = (NLESegmentImageVideoAnimation_OC *)[videoAnimation segmentVideoAnimation];
    }
    
    if (!animation) {
        return nil;
    }
    
    IESMMVideoTransformInfo *transformInfo = [[IESMMVideoTransformInfo alloc] init];
    transformInfo.duration = CMTimeGetSeconds(animation.animationDuration);
    transformInfo.startTime = CMTimeGetSeconds(videoAnimation.startTime);
    
    transformInfo.startTrasformInfo = [[IESMMVideoTransformBaseInfo alloc] init];
    transformInfo.startTrasformInfo.xScale = animation.beginScale;
    transformInfo.startTrasformInfo.yScale = animation.beginScale;
    transformInfo.endTransformInfo = [[IESMMVideoTransformBaseInfo alloc] init];
    transformInfo.endTransformInfo.xScale = animation.endScale;
    transformInfo.endTransformInfo.yScale = animation.endScale;
    
    return transformInfo;
}

- (IESMediaFilterInfo *)videoTransition
{
    if (!self.endTransition) {
        return nil;
    }
    
    switch (self.endTransition.mediaTransType) {
        case NLEMediaTransTypeNone:
            return nil;
            break;
        case NLEMediaTransTypePath:
        {
            IESMediaFilterInfo *filterInfo = [[IESMediaFilterInfo alloc]initWithResourcePath:self.endTransition.effectSDKTransition.resourceFile isOverlap:self.endTransition.overlap];
            filterInfo.duration = CMTimeGetSeconds(self.endTransition.transitionDuration);
            return filterInfo;
        }
            break;
        case NLEMediaTransTypeZoom:
        {
            IESMediaFilterInfo *filterInfo = [[IESMediaFilterInfo alloc] initWithType:IESMediaTransType_Zoom];
            filterInfo.isOverlap = self.endTransition.overlap;
            filterInfo.duration = CMTimeGetSeconds(self.endTransition.transitionDuration);
            return filterInfo;
        }
            break;
    }
}

- (void)setVideoTransition:(IESMediaFilterInfo *)videoTransition
{
    if (videoTransition == nil) {
        self.endTransition = nil;
        return;
    }
    
    NLESegmentTransition_OC *transitionSegment = [[NLESegmentTransition_OC alloc] init];
    transitionSegment.overlap = videoTransition.isOverlap;
    transitionSegment.transitionDuration = ACCCMTimeMakeSeconds(videoTransition.duration);
    
    switch (videoTransition.filterType) {
        case IESMediaTransType_Path:
        {
            transitionSegment.mediaTransType = NLEMediaTransTypePath;
            
            NLEResourceNode_OC *resouce = [[NLEResourceNode_OC alloc] init];
            resouce.resourceType = NLEResourceTypeTransition;
            resouce.resourceFile = videoTransition.resourcePath;
            
            self.endTransition = transitionSegment;
            self.endTransition.effectSDKTransition = resouce;
        }
            break;
        case IESMediaTransType_Zoom:
        {
            transitionSegment.mediaTransType = NLEMediaTransTypeZoom;
            self.endTransition = transitionSegment;
        }
            break;
        default:
            // 暂时不支持其他类型转场动画
            break;
    }
}

- (NLESegmentVideo_OC *)videoSegment
{
    return (NLESegmentVideo_OC *)[self segmentWithClass:NLESegmentVideo_OC.class];
}

- (NLESegmentAudio_OC *)audioSegment
{
    return (NLESegmentAudio_OC *)[self segmentWithClass:NLESegmentAudio_OC.class];
}

- (NLESegmentEffect_OC *)effectSegment
{
    return (NLESegmentEffect_OC *)[self segmentWithClass:NLESegmentEffect_OC.class];
}

- (NLESegmentTimeEffect_OC *)timeEffect
{
    return (NLESegmentTimeEffect_OC *)[self segmentWithClass:NLESegmentTimeEffect_OC.class];
}

#pragma mark - Clip

- (NSNumber *)movieInputFillType
{
    NSString *movieInputFillTypeExtra = [self getExtraForKey:kMovieInputFillTypeKey];
    if (!movieInputFillTypeExtra) {
        return nil;
    }
    return [NSNumber numberWithFloat:movieInputFillTypeExtra.floatValue];
}

- (void)setMovieInputFillType:(NSNumber *)movieInputFillType
{
    [self setExtra:movieInputFillType.stringValue forKey:kMovieInputFillTypeKey];
}

- (NSNumber *)assetRotationInfo
{
    NSString *assetRotationInfoExtra = [self getExtraForKey:kAssetRotationInfoKey];
    if (!assetRotationInfoExtra) {
        return nil;
    }
    return [NSNumber numberWithFloat:assetRotationInfoExtra.floatValue];
}

- (void)setAssetRotationInfo:(NSNumber *)assetRotationInfo
{
    [self setExtra:assetRotationInfo.stringValue forKey:kAssetRotationInfoKey];
}

- (NSString *)bingoKey
{
    return [self getExtraForKey:kBingoKey];
}

- (void)setBingoKey:(NSString *)bingoKey
{
    [self setExtra:bingoKey forKey:kBingoKey];
}

#pragma mark - Canvas

- (IESMMCanvasConfig *)canvasConfig
{
    if (self.videoSegment.canvasStyle == nil) {
        return nil;
    }
    
    NLEStyCanvas_OC *canvas = self.videoSegment.canvasStyle;
    IESMMCanvasConfig *config = [[IESMMCanvasConfig alloc] init];
    switch (canvas.canvasType) {
        case NLECanvasColor:
        {
            config.canvasType = IESMMCanvasColor;
            config.canvasColor = ACCUint32ToColor(canvas.color);
        }
            break;
        case NLECanvasVideoFrame:
        {
            config.canvasType = IESMMCanvasBlur;
            config.blurRaidus = canvas.blurRadius;
        }
            break;
        case NLECanvasImage:
        {
            config.canvasType = IESMMCanvasImage;
            config.canvasImagePath = [canvas.imageSource acc_path];
        }
            break;
        case NLECanvasGradientColor:
        {
            config.canvasType = IESMMCanvasGradientColor;
            config.canvasGradientTopColor = ACCUint32ToColor(canvas.startColor);
            config.canvasGradientBotColor = ACCUint32ToColor(canvas.endColor);
        }
            break;
    }
    return config;
}

- (void)setCanvasConfig:(IESMMCanvasConfig *)canvasConfig draftFolder:(NSString *)draftFolder
{
    if (self.videoSegment == nil) {
        return;
    }
    
    if (canvasConfig == nil) {
        self.videoSegment.canvasStyle = nil;
        return;
    }
    
    NLEStyCanvas_OC *canvas = self.videoSegment.canvasStyle;
    if (!canvas) {
        canvas = [[NLEStyCanvas_OC alloc] init];
    }
    
    switch (canvasConfig.canvasType) {
        case IESMMCanvasNone:
        {
            canvas = nil;
            return;
        }
            break;
        case IESMMCanvasBlur:
        {
            canvas.canvasType = NLECanvasVideoFrame;
            canvas.blurRadius = canvasConfig.blurRaidus;
        }
            break;
        case IESMMCanvasImage:
        {
            canvas.canvasType = NLECanvasImage;
            
            NLEResourceNode_OC *imageNode = [[NLEResourceNode_OC alloc] init];
            imageNode.resourceType = NLEResourceTypeImage;
            [imageNode acc_setPrivateResouceWithURL:[NSURL URLWithString:canvasConfig.canvasImagePath] draftFolder:draftFolder];
            canvas.imageSource = imageNode;
        }
            break;
        case IESMMCanvasColor:
        {
            canvas.canvasType = NLECanvasColor;
            canvas.color = ACCColorToUint32(canvasConfig.canvasColor);
        }
            break;
        case IESMMCanvasGradientColor:
        {
            canvas.startColor = ACCColorToUint32(canvasConfig.canvasGradientTopColor);
            canvas.endColor = ACCColorToUint32(canvasConfig.canvasGradientBotColor);
            canvas.canvasType = NLECanvasGradientColor;
        }
            break;
    }
    
    self.videoSegment.canvasStyle = canvas;
}

- (IESMMCanvasSource *)canvasSource
{
    if (self.videoSegment.canvasStyle == nil) {
        return nil;
    }
    
    IESMMCanvasSource *source = [[IESMMCanvasSource alloc] init];
    source.centerPos = CGPointMake(self.transformX, self.transformY);
    source.scale = self.scale;
    source.rotateAngle = -self.rotation;
    source.flipX = self.Mirror_X;
    source.flipY = self.Mirror_Y;
    source.alpha = self.videoSegment.alpha;
    source.borderWidth = (NSInteger)self.videoSegment.canvasStyle.borderWidth;
    source.borderColor = ACCUint32ToColor(self.videoSegment.canvasStyle.borderColor);
    source.enableAntiAliasing = self.videoSegment.canvasStyle.antialiasing;
    
    return source;
}

- (void)setCanvasSource:(IESMMCanvasSource *)canvasSource
{
    if (self.videoSegment == nil) {
        return;
    }
    
    if (self.videoSegment.canvasStyle == nil ||
        canvasSource == nil) {
        return;
    }
    
    self.transformX = canvasSource.centerPos.x;
    self.transformY = canvasSource.centerPos.y;
    self.scale = canvasSource.scale;
    self.rotation = -canvasSource.rotateAngle;
    self.Mirror_X = canvasSource.flipX;
    self.Mirror_Y = canvasSource.flipY;
    self.videoSegment.alpha = canvasSource.alpha;
    
    // 设置 CanvasSource
    NLEStyCanvas_OC *canvas = self.videoSegment.canvasStyle;
    if (!canvas) {
        canvas = [[NLEStyCanvas_OC alloc] init];
    }
    canvas.borderWidth = (uint32_t)canvasSource.borderWidth;
    canvas.borderColor = ACCColorToUint32(canvasSource.borderColor);
    canvas.antialiasing = canvasSource.enableAntiAliasing;
    self.videoSegment.canvasStyle = canvas;
    // TODO: NLE-缺少属性
//    canvasSource.rotateMode;
//    canvasSource.videoTrackID;
}

#pragma mark - Sticker

+ (nullable instancetype)stickerTrackSlotWithSticker:(IESInfoSticker *)sticker draftFolder:(NSString *)draftFolder
{
    NSString *resoucePath = [self p_fixVEResoucePath:sticker.resourcePath draftFolder:draftFolder];
    
    NLETrackSlot_OC *trackSlot = nil;
    switch (sticker.acc_stickerType) {
        // 这些都是通过图片功能实现的
        case ACCEditEmbeddedStickerTypeText:
        case ACCEditEmbeddedStickerTypeNearbyHashtag:
        case ACCEditEmbeddedStickerTypeSocial:
        case ACCEditEmbeddedStickerTypeCustom:
        case ACCEditEmbeddedStickerTypeVideoComment:
        case ACCEditEmbeddedStickerTypeGroot:
        case ACCEditEmbeddedStickerTypeWish:
        {
            trackSlot = [self imageStickerWithResoucePath:resoucePath
                                               effectInfo:sticker.effectInfo
                                                 userInfo:sticker.userinfo
                                              draftFolder:draftFolder];
        }
            break;
        // 新 POI 使用文字贴纸实现
        case ACCEditEmbeddedStickerTypeModrenPOI:
        {
            trackSlot = [self textStickerTrackSlot];
            [trackSlot setTextStickerTextParams:sticker.textParam];
        }
            break;
        // 歌词贴纸
        case ACCEditEmbeddedStickerTypeLyrics:
        {
            trackSlot = [self p_lyricsTrackSlotWithSticker:sticker
                                               resoucePath:resoucePath
                                               draftFolder:draftFolder];
        }
            break;
        // 这些都是普通信息化贴纸
        case ACCEditEmbeddedStickerTypeMagnifier:
        case ACCEditEmbeddedStickerTypeDaily:
        case ACCEditEmbeddedStickerTypeInfo:
        {
            trackSlot = [self infoStickerWithResoucePath:resoucePath
                                              effectInfo:sticker.effectInfo
                                                userInfo:sticker.userinfo
                                             draftFolder:draftFolder];
        }
            break;
        case ACCEditEmbeddedStickerTypeKaraoke:
        {
            switch (sticker.acc_karaokeType) {
                case ACCKaraokeStickerTypeLyric:
                {
                    trackSlot = [self p_lyricsTrackSlotWithSticker:sticker
                                                       resoucePath:resoucePath
                                                       draftFolder:draftFolder];
                }
                    break;
                case ACCKaraokeStickerTypeLyricTitle:
                case ACCKaraokeStickerTypeLyricSubTitle:
                {
                    trackSlot = [self textStickerTrackSlot];
                    [trackSlot setTextStickerTextParams:sticker.textParam];
                }
                    break;
            }
        }
            break;
        // 自动字幕/UIImage 贴纸不存草稿，不转换 NLE
        case ACCEditEmbeddedStickerTypeUIImage:
        case ACCEditEmbeddedStickerTypeCaption:
            return nil;
            break;
    }
    
    // pin
    if (sticker.pinResultPath.length > 0) {
        NSString *pinResultPath = [self p_fixVEResoucePath:sticker.pinResultPath draftFolder:draftFolder];
        NLEResourceNode_OC *node = [[NLEResourceNode_OC alloc] init];
        node.resourceType = NLEResourceTypePIN;
        [node acc_setPrivateResouceWithURL:[NSURL URLWithString:pinResultPath]
                               draftFolder:draftFolder];
        trackSlot.pinAlgorithmFile = node;
    }
    
    // sticker animation
    [sticker.animParams acc_forEach:^(IESInfoStickerAnimParam * _Nonnull obj) {
        NSString *animPath = [self p_fixVEResoucePath:obj.animPath draftFolder:draftFolder];
        [trackSlot setStickerAnimationType:obj.animType
                                  filePath:animPath
                               draftFolder:draftFolder
                                  duration:obj.animDuration];
    }];
    
    // 坐标信息
    trackSlot.transformX = sticker.param.offsetX;
    trackSlot.transformY = sticker.param.offsetY;
    trackSlot.rotation = sticker.param.radian;
    trackSlot.scale = sticker.param.scale;
    trackSlot.layer = sticker.layer;
    trackSlot.startTime = ACCCMTimeMakeSeconds(sticker.startTime);
    
    // 贴纸设置时长为 -1 会被 VE 处理为 100000s，这里需要恢复原始值
    CGFloat duration = sticker.duration == 100000 ? -1 : sticker.duration;
    trackSlot.duration = ACCCMTimeMakeSeconds(duration);
    return trackSlot;
}

+ (NLETrackSlot_OC *)p_lyricsTrackSlotWithSticker:(IESInfoSticker *)sticker
                                      resoucePath:(NSString *)resoucePath
                                      draftFolder:(NSString *)draftFolder
{
    NLETrackSlot_OC *trackSlot = [self lyricsStickerWithResoucePath:resoucePath
                                                         effectInfo:sticker.effectInfo
                                                           userInfo:sticker.userinfo
                                                        draftFolder:draftFolder];
    [trackSlot setSrtString:sticker.param.srt draftFolder:draftFolder];
    // 歌词贴纸其他信息
    NLESegmentSubtitleSticker_OC *lyricSticker = [trackSlot lyricSticker];
    lyricSticker.timeClipStart = ACCCMTimeMakeSeconds(sticker.param.srtTrimIn);
    lyricSticker.timeClipEnd = ACCCMTimeMakeSeconds(sticker.param.srtDuration + sticker.param.srtTrimIn);
    lyricSticker.stickerAnimation.loop = sticker.param.isAudioCycle;
    
    if (sticker.param.srtColor) {
        [trackSlot setSrtColorWithR:sticker.param.srtColor.red
                                  g:sticker.param.srtColor.green
                                  b:sticker.param.srtColor.blue
                                  a:sticker.param.srtColor.alpha];
    }
    
    if (sticker.param.srtFontPath.length > 0) {
        NSString *srtFontPath = [self p_fixVEResoucePath:sticker.param.srtFontPath draftFolder:draftFolder];
        [lyricSticker.style.font acc_setPrivateResouceWithURL:[NSURL URLWithString:srtFontPath]
                                                  draftFolder:draftFolder];
    }
    return trackSlot;
}

+ (instancetype)captionStickerTrackSlot
{
    NLESegmentSubtitleSticker_OC *sticker = [[NLESegmentSubtitleSticker_OC alloc] init];
    NLEResourceNode_OC *node = [[NLEResourceNode_OC alloc] init];
    node.resourceType = NLEResourceTypeAutoSubTitle;
    sticker.effectSDKFile = node;
    
    NLETrackSlot_OC *trackSlot = [[NLETrackSlot_OC alloc] init];
    trackSlot.segment = sticker;
    return trackSlot;
}

+ (instancetype)textStickerTrackSlot
{
    NLESegmentTextSticker_OC *textSticker = [[NLESegmentTextSticker_OC alloc] init];
    textSticker.style = [[NLEStyleText_OC alloc] init];
    textSticker.style.font = [[NLEResourceNode_OC alloc] init];
    textSticker.stickerAnimation = [[NLEStyStickerAnimation_OC alloc] init];
    
    NLETrackSlot_OC *slot = [[NLETrackSlot_OC alloc] init];
    slot.segment = textSticker;
    return slot;
}

+ (instancetype)lyricsStickerWithResoucePath:(NSString *)resoucePath
                                  effectInfo:(NSArray *)effectInfo
                                    userInfo:(NSDictionary *)userInfo
                                 draftFolder:(NSString *)draftFolder
{
    NLEResourceNode_OC *node = [[NLEResourceNode_OC alloc] init];
    node.resourceId = userInfo[kACCStickerIDKey];
    [node acc_setPrivateResouceWithURL:[NSURL URLWithString:resoucePath]
                           draftFolder:draftFolder];
    node.resourceType = NLEResourceTypeSubTitleSticker;
    
    NLESegmentSubtitleSticker_OC *lyricSticker = [[NLESegmentSubtitleSticker_OC alloc] init];
    lyricSticker.srtFile = [[NLEResourceNode_OC alloc] init];
    lyricSticker.srtFile.resourceType = NLEResourceTypeSrt;
    lyricSticker.effectSDKFile = node;
    lyricSticker.style = [[NLEStyleText_OC alloc] init];
    lyricSticker.style.font = [[NLEResourceNode_OC alloc] init];
    lyricSticker.style.font.resourceType = NLEResourceTypeFont;
    lyricSticker.style.textColor = 0xFFFFFFFF;
    lyricSticker.stickerAnimation = [[NLEStyStickerAnimation_OC alloc] init];
    [lyricSticker setInfoStringList:[effectInfo mutableCopy]];
    
    NLETrackSlot_OC *slot = [[NLETrackSlot_OC alloc] init];
    slot.segment = lyricSticker;
    return slot;
}

+ (instancetype)imageStickerWithResoucePath:(NSString *)resoucePath
                                 effectInfo:(NSArray *)effectInfo
                                   userInfo:(NSDictionary *)userInfo
                                draftFolder:(NSString *)draftFolder
{
    NLEResourceNode_OC *node = [[NLEResourceNode_OC alloc] init];
    node.resourceId = node.UUID;
    [node acc_setPrivateResouceWithURL:[NSURL URLWithString:resoucePath]
                           draftFolder:draftFolder];
    node.resourceType = NLEResourceTypeImageSticker;
    
    NLESegmentImageSticker_OC *imageSticker = [[NLESegmentImageSticker_OC alloc] init];
    imageSticker.imageFile = node;
    imageSticker.stickerAnimation = [[NLEStyStickerAnimation_OC alloc] init];
    [imageSticker setInfoStringList:[effectInfo mutableCopy]];
    
    NLETrackSlot_OC *slot = [[NLETrackSlot_OC alloc] init];
    slot.segment = imageSticker;
    return slot;
}

+ (instancetype)infoStickerWithResoucePath:(NSString *)resoucePath
                                effectInfo:(NSArray *)effectInfo
                                  userInfo:(NSDictionary *)userInfo
                               draftFolder:(NSString *)draftFolder
{
    NLEResourceNode_OC *node = [[NLEResourceNode_OC alloc] init];
    node.resourceId = node.UUID;
    [node acc_setPrivateResouceWithURL:[NSURL URLWithString:resoucePath]
                           draftFolder:draftFolder];
    node.resourceType = NLEResourceTypeInfoSticker;
    
    NLESegmentInfoSticker_OC *infoSticker = [[NLESegmentInfoSticker_OC alloc] init];
    infoSticker.effectSDKFile = node;
    infoSticker.stickerAnimation = [[NLEStyStickerAnimation_OC alloc] init];
    [infoSticker setInfoStringList:[effectInfo mutableCopy]];
    
    NLETrackSlot_OC *slot = [[NLETrackSlot_OC alloc] init];
    slot.segment = infoSticker;
    return slot;
}

#pragma mark - Sticker Properties

- (NLESegmentSticker_OC *)sticker {
    return (NLESegmentSticker_OC *)[self segmentWithClass:NLESegmentSticker_OC.class];
}

- (NLESegmentImageSticker_OC *)imageSticker {
    return (NLESegmentImageSticker_OC *)[self segmentWithClass:NLESegmentImageSticker_OC.class];
}

- (NLESegmentSubtitleSticker_OC *)lyricSticker {
    NLESegmentSubtitleSticker_OC *sticker = (NLESegmentSubtitleSticker_OC *)[self segmentWithClass:NLESegmentSubtitleSticker_OC.class];
    if (sticker.effectSDKFile.resourceType != NLEResourceTypeSubTitleSticker) {
        return nil;
    }
    return sticker;
}

- (NLESegmentSubtitleSticker_OC *)captionSticker {
    NLESegmentSubtitleSticker_OC *sticker = (NLESegmentSubtitleSticker_OC *)[self segmentWithClass:NLESegmentSubtitleSticker_OC.class];
    if (sticker.effectSDKFile.resourceType != NLEResourceTypeAutoSubTitle) {
        return nil;
    }
    return sticker;
}

- (NLESegmentTextSticker_OC *)textSticker {
    return (NLESegmentTextSticker_OC *)[self segmentWithClass:NLESegmentTextSticker_OC.class];
}

- (NLESegmentInfoSticker_OC *)infoSticker {
    return (NLESegmentInfoSticker_OC *)[self segmentWithClass:NLESegmentInfoSticker_OC.class];
}

- (void)setStickerOffset:(CGPoint)offset normalizeConverter:(CGPoint(^)(CGPoint))normalizeConverter
{
    if (![self sticker]) {
        return;
    }
    
    CGPoint normalizedOffset = normalizeConverter(offset);
    self.transformX = normalizedOffset.x;
    self.transformY = normalizedOffset.y;
}

- (void)setStickerAboveWithNLEModel:(NLEModel_OC *)nleModel
{
    int32_t maxLayer = [nleModel getLayerMax];
    if (self.layer < maxLayer) {
        self.layer = maxLayer + 1;
    }
}

- (void)setSrtString:(NSString *)srtString draftFolder:(NSString *)draftFolder
{
    if (self.lyricSticker == nil) {
        return;
    }
    
    NSData *srtData = [srtString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *relativePath = [NSString stringWithFormat:@"%@.srt", [srtData acc_md5String]];
    NSString *srtPath = [draftFolder stringByAppendingPathComponent:relativePath];
    if([[NSFileManager defaultManager] fileExistsAtPath:srtPath]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:srtPath error:&error];
        AWELogToolError(AWELogToolTagMV, @"remove item error: %@", error);
    }
    BOOL b = [srtData writeToFile:srtPath atomically:YES];
    if (b) {
        [self.lyricSticker.srtFile acc_setPrivateResouceWithURL:[NSURL URLWithString:srtPath]
                                                    draftFolder:draftFolder];
    } else {
        AWELogToolError(AWELogToolTagEdit, @"Save srt to %@ fail", srtPath);
    }
}

- (void)setSrtColorWithR:(CGFloat)r g:(CGFloat)g b:(CGFloat)b a:(CGFloat)a
{
    if ([self lyricSticker] == nil) {
        return;
    }
    
    if(a >= 0) {
        uint32_t
        alpha = a * 0xFF,
        red = r * 0xFF,
        green = g * 0xFF,
        blue = b * 0xFF;
        [self lyricSticker].style.textColor = (alpha << 24) | (red << 16) | (green << 8) | blue;
    } else {
        // 没有颜色情况下alpha == -1，此时强制赋值为白色
        [self lyricSticker].style.textColor = 0xFFFFFFFF;
    }
}

- (UIColor *)getSrtColor
{
    if ([self lyricSticker] == nil) {
        return nil;
    }
    
    return ACCUint32ToColor(self.lyricSticker.style.textColor);
}

- (NSInteger)setStickerAnimationType:(NSInteger)animationType
                            filePath:(NSString *)filePath
                         draftFolder:(NSString *)draftFolder
                            duration:(CGFloat)duration
{
    if (!self.sticker) {
        return 0;
    }
    
    NLEResourceNode_OC *resouce = [[NLEResourceNode_OC alloc] init];
    if (filePath.length > 0) {
        [resouce acc_setPrivateResouceWithURL:[NSURL URLWithString:filePath]
                                  draftFolder:draftFolder];
    }
    if (animationType == 0) {
        // inAnimation
        [self sticker].stickerAnimation.inAnimation = resouce;
        [self sticker].stickerAnimation.inDuration = CMTimeMakeWithSeconds(duration, USEC_PER_SEC);
    }
    else if (animationType == 1) {
        // outAnimation
        [self sticker].stickerAnimation.outAnimation = resouce;
        [self sticker].stickerAnimation.outDuration = CMTimeMakeWithSeconds(duration, USEC_PER_SEC);
    }
    else if (animationType == 3) {
        // loop
        [self sticker].stickerAnimation.loop = YES;
        [self sticker].stickerAnimation.inAnimation = resouce;
        [self sticker].stickerAnimation.inDuration = CMTimeMakeWithSeconds(duration, USEC_PER_SEC);
    }
    
    return 0;
}

- (void)setTextStickerTextParams:(NSString *)textParams
{
    if (!self.textSticker) {
        return;
    }
    
    [self.textSticker setEffectSDKJSONString:textParams];
    [self.textSticker setExtra:textParams forKey:@"text_param"];
}

#pragma mark - MV

+ (instancetype)mvTrackSlotWithResouce:(IESMMMVResource *)resource
                           draftFolder:(NSString *)draftFolder
{
    NLEResourceNode_OC *resouceNode = [[NLEResourceNode_OC alloc] init];
    [resouceNode acc_setPrivateResouceWithURL:[NSURL URLWithString:resource.resourceContent]
                                  draftFolder:draftFolder];
    resouceNode.resourceId = resource.rid;
    
    NLESegmentMVResourceType resourceType = NLESegmentMVResourceTypeNone;
    switch (resource.resourceType) {
        case IESMMMVResourcesType_img:
            resouceNode.resourceType = NLEResourceTypeImage;
            resourceType = NLESegmentMVResourceTypeImage;
            break;
        case IESMMMVResourcesType_video:
            resouceNode.resourceType = NLEResourceTypeVideo;
            resourceType = NLESegmentMVResourceTypeVideo;
            break;
        case IESMMMVResourcesType_mp3:
            resouceNode.resourceType = NLEResourceTypeAudio;
            resourceType = NLESegmentMVResourceTypeAudio;
            break;
        case IESMMMVResourcesType_text:
            resourceType = NLESegmentMVResourceTypeText;
            break;
        case IESMMMVResourcesType_gif:
            resourceType = NLESegmentMVResourceTypeGif;
            break;
        case IESMMMVResourcesType_bgimg:
            resourceType = NLESegmentMVResourceTypeBgimg;
            break;
        default:
            NSAssert(NO, @"暂不支持此类型");
            break;
    }
    
    NLESegmentMV_OC *segmentMV = [[NLESegmentMV_OC alloc] init];
    segmentMV.sourceFile = resouceNode;
    segmentMV.sourceFileType = resourceType;
    segmentMV.start = kCMTimeZero;
    segmentMV.end = ACCCMTimeMakeSeconds(kACCMVDefaultSecond);
    
    NLETrackSlot_OC *trackSlot = [[NLETrackSlot_OC alloc] init];
    trackSlot.segment = segmentMV;
    trackSlot.startTime = kCMTimeZero;
    trackSlot.duration = CMTimeSubtract(segmentMV.end, segmentMV.start);
    return trackSlot;
}

+ (instancetype)slotWithBeatsTracking:(IESMMAudioBeatTracking *)beatsTracking
                          draftFolder:(NSString *)draftFolder
{
    NLEResourceAV_OC *resouceNode = [[NLEResourceAV_OC alloc] init];
    [resouceNode acc_setPrivateResouceWithURL:beatsTracking.audioURL draftFolder:draftFolder];
    resouceNode.resourceType = NLEResourceTypeAlgorithmMVAudio;
    
    NLESegmentAudio_OC *audio = [[NLESegmentAudio_OC alloc] init];
    audio.audioFile = resouceNode;
    audio.timeClipStart = ACCCMTimeMakeSeconds(beatsTracking.dstStart);
    audio.timeClipEnd = ACCCMTimeMakeSeconds(beatsTracking.dstStart + beatsTracking.dstDuration);
    
    NLETrackSlot_OC *trackSlot = [[NLETrackSlot_OC alloc] init];
    trackSlot.segment = audio;
    return trackSlot;
}

+ (instancetype)mvMusicSlotWithMusicPath:(NSString *)musicPath
                          audioClipRange:(IESMMVideoDataClipRange *)audioClipRange
                             draftFolder:(NSString *)draftFolder
{
    NLEResourceAV_OC *resouceNode = [[NLEResourceAV_OC alloc] init];
    [resouceNode acc_setPrivateResouceWithURL:[NSURL fileURLWithPath:musicPath] draftFolder:draftFolder];
    resouceNode.resourceType = NLEResourceTypeMusicMVAudio;
    
    NLESegmentAudio_OC *audio = [[NLESegmentAudio_OC alloc] init];
    audio.audioFile = resouceNode;
    audio.timeClipStart = ACCCMTimeMakeSeconds(audioClipRange.startSeconds);
    audio.timeClipEnd = ACCCMTimeMakeSeconds(audioClipRange.durationSeconds);
    
    NLETrackSlot_OC *trackSlot = [[NLETrackSlot_OC alloc] init];
    trackSlot.segment = audio;
    trackSlot.audioClipRange = audioClipRange;
    return trackSlot;
}

+ (instancetype)placeHolderAudioSlotForResourceType:(NLEResourceType)resourceType {
    NLEResourceAV_OC *resouceNode = [[NLEResourceAV_OC alloc] init];
    // 这里由nle内部消费全路径，所以不能配置draftFolder
    [resouceNode acc_setPrivateResouceWithURL:[NSURL fileURLWithPath:@""] draftFolder:@""];
    resouceNode.resourceType = resourceType;
    
    NLESegmentAudio_OC *audio = [[NLESegmentAudio_OC alloc] init];
    audio.audioFile = resouceNode;
    
    NLETrackSlot_OC *trackSlot = [[NLETrackSlot_OC alloc] init];
    trackSlot.segment = audio;
    return trackSlot;
}

- (NLESegmentMV_OC *)mv
{
    return (NLESegmentMV_OC *)[self segmentWithClass:[NLESegmentMV_OC class]];
}

- (IESMMMVResource *)mvResouce
{
    if ([self mv] == nil) {
        return nil;
    }
    
    IESMMMVResource *resouce = [[IESMMMVResource alloc] init];
    resouce.resourceContent = [[[self mv] sourceFile] acc_path];
    resouce.rid = [[self mv] sourceFile].resourceId;
    switch ([[self mv] sourceFileType]) {
        case NLESegmentMVResourceTypeImage:
            resouce.resourceType = IESMMMVResourcesType_img;
            break;
        case NLESegmentMVResourceTypeAudio:
            resouce.resourceType = IESMMMVResourcesType_mp3;
            break;
        case NLESegmentMVResourceTypeVideo:
            resouce.resourceType = IESMMMVResourcesType_video;
            break;
        case NLESegmentMVResourceTypeBgimg:
            resouce.resourceType = IESMMMVResourcesType_bgimg;
            break;
        case NLESegmentMVResourceTypeText:
            resouce.resourceType = IESMMMVResourcesType_text;
            break;
        case NLESegmentMVResourceTypeGif:
            resouce.resourceType = IESMMMVResourcesType_gif;
            break;
        default:
            NSAssert(NO, @"暂不支持此类型");
            break;
    }
    return resouce;
}

#pragma mark - Basic Utils

+ (NSString *)p_fixVEResoucePath:(NSString *)resoucePath draftFolder:(NSString *)draftFolder
{
    if (resoucePath.length == 0) {
        return resoucePath;
    }
    
    // 如果是 root 目录，直接返回 nil
    if ([resoucePath isEqualToString:NSHomeDirectory()] ||
        [resoucePath isEqualToString:[NSHomeDirectory() stringByAppendingString:@"/"]]) {
        return nil;
    }
    
    // 文件存在就直接返回了
    if ([[NSFileManager defaultManager] fileExistsAtPath:resoucePath]) {
        return resoucePath;
    }
    
    NSMutableArray<NSString *> *pathComponents =
    [[[resoucePath componentsSeparatedByString:@"/"] acc_filter:^BOOL(NSString * _Nonnull item) {
        return item.length > 0;
    }] mutableCopy];
    
    NSInteger index = [pathComponents indexOfObject:@"Documents"];
    NSString *sandboxRegex = @"^/var/mobile/Containers/Data/Application/[0-9a-zA-Z-]+/";
    if (index != NSNotFound) {
        // 沙盒相对路径：Documents/drafts/xxxx
        [pathComponents removeObjectsInRange:NSMakeRange(0, index)];
        [pathComponents insertObject:NSHomeDirectory() atIndex:0];
    } else if ([resoucePath rangeOfString:sandboxRegex options:NSRegularExpressionSearch].location == NSNotFound){
        // 草稿目录相对路径：xxxx
        [pathComponents insertObject:draftFolder atIndex:0];
    }
    
    NSString *fixedPath = [pathComponents componentsJoinedByString:@"/"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:fixedPath]) {
        return fixedPath;
    } else {
        NSAssert(NO, @"file path is invalid");
        return resoucePath;
    }
}

- (NLESegment_OC *_Nullable)segmentWithClass:(Class)clz
{
    if ([self.segment isKindOfClass:clz]) {
        return self.segment;
    }
    return nil;
}

@end
