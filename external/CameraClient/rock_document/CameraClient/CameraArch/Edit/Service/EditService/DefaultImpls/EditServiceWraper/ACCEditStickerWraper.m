//
//  ACCEditStickerWraper.m
//  CameraClient
//
//  Created by haoyipeng on 2020/8/13.
//

#import "ACCEditStickerWraper.h"
#import "VEEditorSession+ACCSticker.h"
#import "ACCConfigKeyDefines.h"

#import <CreationKitInfra/ACCLogHelper.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <ReactiveObjC/RACSubject.h>

@interface ACCEditStickerWraper () <ACCEditBuildListener>

@property (nonatomic, weak) VEEditorSession *player;
@property (nonatomic, strong) RACSubject<RACTwoTuple<NSNumber *, NSNumber *> *> *stickerRegenerateSignal;

@end

@implementation ACCEditStickerWraper

- (void)dealloc
{
    [_stickerRegenerateSignal sendCompleted];
}

- (void)setEditSessionProvider:(id<ACCEditSessionProvider>)editSessionProvider
{
    [editSessionProvider addEditSessionListener:self];
}

#pragma mark - ACCEditBuildListener

- (void)onEditSessionInit:(ACCEditSessionWrapper *)editorSession
{
    self.player = editorSession.videoEditSession;
}

#pragma mark - ACCEditStickerProtocol

#pragma mark - lyric sticker

- (void)setFixedTopInfoSticker:(NSInteger)fixedTopInfoSticker
{
    self.player.acc_fixedTopInfoSticker = fixedTopInfoSticker;
}

- (NSInteger)fixedTopInfoSticker
{
    return self.player.acc_fixedTopInfoSticker;
}

- (NSInteger)addSubtitleSticker
{
    return [self.player addSubtitleSticker];
}

- (nonnull UIColor *)filterMusicLyricColor
{
    return [self.player acc_filterMusicLyricColor];
}

- (nonnull NSString *)filterMusicLyricEffectId
{
    return [self.player acc_filterMusicLyricEffectId];
}

- (nonnull NSNumber *)filterMusicLyricStickerId
{
    return [self.player acc_filterMusicLyricStickerId];
}

- (void)setSrtAudioInfo:(NSInteger)stickerId seqIn:(NSTimeInterval)seqIn trimIn:(NSTimeInterval)trimIn duration:(NSTimeInterval)duration audioCycle:(BOOL)audioCycle
{
    [self.player setSrtAudioInfo:stickerId seqIn:seqIn trimIn:trimIn duration:duration audioCycle:audioCycle];
}

- (void)setSrtColor:(NSInteger)stickerId red:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b alpha:(CGFloat)a
{
    [self.player setSrtColor:stickerId red:r green:g blue:b alpha:a];
}

- (void)setSrtFont:(NSInteger)stickerId fontPath:(nonnull NSString *)fontPath
{
    [self.player setSrtFont:stickerId fontPath:fontPath];
}

- (void)setSrtInfo:(NSInteger)stickerId srt:(nonnull NSString *)srt
{
    [self.player setSrtInfo:stickerId srt:srt];
}

- (void)setStickerScale:(NSInteger)stickerId scale:(CGFloat)scale
{
    [self.player setStickerScale:stickerId scale:scale];
}

- (void)updateSticker:(NSInteger)stickerId
{
    [self.player updateSticker:stickerId];
}

#pragma mark - Pin

- (void)preparePin
{
    [self.player preparePin];
}

- (void)startPin:(NSInteger)stickerIndex
    pinStartTime:(float)pinStartTime
     pinDuration:(float)duration
      completion:(nonnull void (^)(BOOL result, NSError *error))completion
{
    [self.player startPin:stickerIndex pinStartTime:pinStartTime pinDuration:duration completion:completion];
}

- (void)cancelPin:(NSInteger)stickerIndex
{
    [self.player cancelPin:stickerIndex];
}

- (CGFloat)getStickerRotation:(NSInteger)stickerIndex
{
    if (ACCConfigBool(kConfigBool_disable_sticker_ve_safeguard)) {
        return [self.player getStickerRotation:stickerIndex];
    }
    
    CGFloat value = [self.player getStickerRotation:stickerIndex];
    if (!isfinite(value)) {
        value = 0.0;
        
        AWELogToolError2(@"sticker_props_error", AWELogToolTagEdit, @"getStickerRotation, stickerID: %d", stickerIndex);
        [ACCMonitor() trackService:@"sticker_props_error"
                            status:1
                             extra:@{
                                 @"op_type": @"getStickerRotation",
                                 @"stickerID": @(stickerIndex)
                            }];
    }
    
    return value;
}

- (CGPoint)getStickerPosition:(NSInteger)stickerIndex
{
    if (ACCConfigBool(kConfigBool_disable_sticker_ve_safeguard)) {
        return [self.player getStickerPosition:stickerIndex];
    }
    
    CGPoint value = [self.player getStickerPosition:stickerIndex];
    if (!isfinite(value.x)) {
        value.x = 0;
        
        AWELogToolError2(@"sticker_props_error", AWELogToolTagEdit, @"getStickerPosition_x, stickerID: %d", stickerIndex);
        [ACCMonitor() trackService:@"sticker_props_error"
                            status:1
                             extra:@{
                                 @"op_type": @"getStickerPosition_x",
                                 @"stickerID": @(stickerIndex)
                            }];
    }
    if (!isfinite(value.y)) {
        value.y = 0;
        
        AWELogToolError2(@"sticker_props_error", AWELogToolTagEdit, @"getStickerPosition_y, stickerID: %d", stickerIndex);
        [ACCMonitor() trackService:@"sticker_props_error"
                            status:1
                             extra:@{
                                 @"op_type": @"getStickerPosition_y",
                                 @"stickerID": @(stickerIndex)
                            }];
    }
    
    return value;
}

- (VEStickerPinStatus)getStickerPinStatus:(NSInteger)stickerIndex
{
    return [self.player getStickerPinStatus:stickerIndex];
}

- (BOOL)getStickerVisible:(NSInteger)stickerIndex
{
    return [self.player getStickerVisible:stickerIndex];
}

- (void)setInfoStickerRestoreMode:(VEInfoStickerRestoreMode)mode
{
    [self.player setInfoStickerRestoreMode:mode];
}

#pragma mark - Sticker

- (void)addStickerbyUIImage:(UIImage *)image letterInfo:(nullable NSString*)letterInfo duration:(CGFloat)duration
{
    NSInteger stickerId = [self.player addStickerbyUIImage:image letterInfo:letterInfo];
    [self.player setSticker:stickerId startTime:0 duration:duration];
}

- (BOOL)isAnimationSticker:(NSInteger)stickerID
{
    return [self.player isAnimationSticker:stickerID];
}

- (NSInteger)addInfoSticker:(NSString *)path withEffectInfo:(nullable NSArray *)effectInfo userInfo:(NSDictionary *)userInfo
{
    return [self.player addInfoSticker:path withEffectInfo:effectInfo userInfo:userInfo];
}

- (NSInteger)setStickerAnimationWithStckerID:(NSInteger)stickerID animationType:(NSInteger)animationType filePath:(NSString *)filePath duration:(CGFloat)duration
{
    return [self.player setStickerAnim:stickerID animType:(int)animationType animPath:filePath duration:duration];
}

- (CGSize)getInfoStickerSize:(NSInteger)stickerId
{
    if (ACCConfigBool(kConfigBool_disable_sticker_ve_safeguard)) {
        return [self.player getInfoStickerSize:stickerId];
    }
    
    CGSize value = [self.player getInfoStickerSize:stickerId];
    if (!isfinite(value.width)) {
        value.width = 0;
        
        AWELogToolError2(@"sticker_props_error", AWELogToolTagEdit, @"getInfoStickerSize_width, stickerID: %d", stickerId);
        [ACCMonitor() trackService:@"sticker_props_error"
                            status:1
                             extra:@{
                                 @"op_type": @"getInfoStickerSize_width",
                                 @"stickerID": @(stickerId)
                            }];
    }
    if (!isfinite(value.height)) {
        value.height = 0;
        
        AWELogToolError2(@"sticker_props_error", AWELogToolTagEdit, @"getInfoStickerSize_height, stickerID: %d", stickerId);
        [ACCMonitor() trackService:@"sticker_props_error"
                            status:1
                             extra:@{
                                 @"op_type": @"getInfoStickerSize_height",
                                 @"stickerID": @(stickerId)
                            }];
    }
    
    return value;
}

- (CGSize)getstickerEditBoxSize:(NSInteger)stickerId
{
    if (ACCConfigBool(kConfigBool_disable_sticker_ve_safeguard)) {
        return [self.player getstickerEditBoxSize:stickerId];
    }
    
    CGSize value = [self.player getstickerEditBoxSize:stickerId];
    if (!isfinite(value.width)) {
        value.width = 0;
        
        AWELogToolError2(@"sticker_props_error", AWELogToolTagEdit, @"getstickerEditBoxSize_width, stickerID: %d", stickerId);
        [ACCMonitor() trackService:@"sticker_props_error"
                            status:1
                             extra:@{
                                 @"op_type": @"getstickerEditBoxSize_width",
                                 @"stickerID": @(stickerId)
                            }];
    }
    if (!isfinite(value.height)) {
        value.height = 0;
        
        AWELogToolError2(@"sticker_props_error", AWELogToolTagEdit, @"getstickerEditBoxSize_height, stickerID: %d", stickerId);
        [ACCMonitor() trackService:@"sticker_props_error"
                            status:1
                             extra:@{
                                 @"op_type": @"getstickerEditBoxSize_height",
                                 @"stickerID": @(stickerId)
                            }];
    }
    
    return value;
}

- (void)removeInfoSticker:(NSInteger)stickerId
{
    [self.player removeInfoSticker:stickerId];
}

- (void)setSticker:(NSInteger)stickerId offsetX:(CGFloat)offsetX offsetY:(CGFloat)offsetY angle:(CGFloat)angle scale:(CGFloat)scale
{
    [self.player acc_setSticker:stickerId offsetX:offsetX offsetY:offsetY angle:angle scale:scale];
}

- (void)setSticker:(NSInteger)stickerId offsetX:(CGFloat)offsetX offsetY:(CGFloat)offsetY
{
    [self.player setSticker:stickerId offsetX:offsetX offsetY:offsetY];
}

- (void)setTextStickerTextParams:(NSInteger)stickerId textParams:(NSString *)textParams
{
    [self.player setTextStickerTextParams:stickerId textParams:textParams];
}

- (void)setSticker:(NSInteger)stickerId alpha:(CGFloat)alpha
{
    [self.player setSticker:stickerId alpha:alpha];
}

- (void)setStickerAngle:(NSInteger)stickerId angle:(CGFloat)angle
{
    [self.player setStickerAngle:stickerId angle:angle];
}

- (void)setStickerLayer:(NSInteger)stickerId layer:(NSInteger)layer
{
    [self.player setStickerLayer:stickerId layer:layer];
}

- (void)setSticker:(NSInteger)stickerId startTime:(CGFloat)startTime duration:(CGFloat)duration
{
    [self.player setSticker:stickerId startTime:startTime duration:duration];
}

- (void)setStickerAbove:(NSInteger)stickerId
{
    [self.player setStickerAbove:stickerId];
}

- (void)setStickerAboveForInfoSticker:(NSInteger)stickerId
{
    [self.player acc_setStickerAboveForInfoSticker:stickerId];
}

- (void)getStickerId:(NSInteger)stickerId props:(IESInfoStickerProps *)props
{
    [self.player getStickerId:stickerId props:props];
    
    if (ACCConfigBool(kConfigBool_disable_sticker_ve_safeguard)) {
        return;
    }
    
    if (!isfinite(props.angle)) {
        props.angle = 0.0;
        
        AWELogToolError2(@"sticker_props_error", AWELogToolTagEdit, @"getStickerId_props_angle, stickerID: %d", stickerId);
        [ACCMonitor() trackService:@"sticker_props_error"
                            status:1
                             extra:@{
                                 @"op_type": @"getStickerId_props_angle",
                                 @"stickerID": @(stickerId)
                            }];
    }
    if (!isfinite(props.offsetX)) {
        props.offsetX = 0.0;
        
        AWELogToolError2(@"sticker_props_error", AWELogToolTagEdit, @"getStickerId_props_offsetX, stickerID: %d", stickerId);
        [ACCMonitor() trackService:@"sticker_props_error"
                            status:1
                             extra:@{
                                 @"op_type": @"getStickerId_props_offsetX",
                                 @"stickerID": @(stickerId)
                            }];
    }
    if (!isfinite(props.offsetY)) {
        props.offsetY = 0.0;
        
        AWELogToolError2(@"sticker_props_error", AWELogToolTagEdit, @"getStickerId_props_offsetY, stickerID: %d", stickerId);
        [ACCMonitor() trackService:@"sticker_props_error"
                            status:1
                             extra:@{
                                 @"op_type": @"getStickerId_props_offsetY",
                                 @"stickerID": @(stickerId)
                            }];
    }
    if (!isfinite(props.scale) ||
        props.scale <= CGFLOAT_MIN) {
        props.scale = 1.0;
        
        AWELogToolError2(@"sticker_props_error", AWELogToolTagEdit, @"getStickerId_props_scale, stickerID: %d", stickerId);
        [ACCMonitor() trackService:@"sticker_props_error"
                            status:1
                             extra:@{
                                 @"op_type": @"getStickerId_props_scale",
                                 @"stickerID": @(stickerId)
                            }];
    }
    if (!isfinite(props.alpha)) {
        props.alpha = 1.0;
        
        AWELogToolError2(@"sticker_props_error", AWELogToolTagEdit, @"getStickerId_props_alpha, stickerID: %d", stickerId);
        [ACCMonitor() trackService:@"sticker_props_error"
                            status:1
                             extra:@{
                                 @"op_type": @"getStickerId_props_alpha",
                                 @"stickerID": @(stickerId)
                            }];
    }
    if (!isfinite(props.startTime)) {
        props.startTime = 0.0;
        
        AWELogToolError2(@"sticker_props_error", AWELogToolTagEdit, @"getStickerId_props_startTime, stickerID: %d", stickerId);
        [ACCMonitor() trackService:@"sticker_props_error"
                            status:1
                             extra:@{
                                 @"op_type": @"getStickerId_props_startTime",
                                 @"stickerID": @(stickerId)
                            }];
    }
    if (!isfinite(props.duration)) {
        props.duration = 0.0;
        
        AWELogToolError2(@"sticker_props_error", AWELogToolTagEdit, @"getStickerId_props_duration, stickerID: %d", stickerId);
        [ACCMonitor() trackService:@"sticker_props_error"
                            status:1
                             extra:@{
                                 @"op_type": @"getStickerId_props_duration",
                                 @"stickerID": @(stickerId)
                            }];
    }
    if (!isfinite(props.srtStartTime)) {
        props.srtStartTime = 0.0;
        
        AWELogToolError2(@"sticker_props_error", AWELogToolTagEdit, @"getStickerId_props_srtStartTime, stickerID: %d", stickerId);
        [ACCMonitor() trackService:@"sticker_props_error"
                            status:1
                             extra:@{
                                 @"op_type": @"getStickerId_props_srtStartTime",
                                 @"stickerID": @(stickerId)
                            }];
    }
}

- (void)startChangeStickerDuration:(NSInteger)stickerId
{
    [self.player startChangeStickerDuration:stickerId];
}

- (void)stopChangeStickerDuration:(NSInteger)stickerId
{
    [self.player stopChangeStickerDuration:stickerId];
}

- (CGRect)getstickerEditBoundBox:(NSInteger)stickerId
{
    if (ACCConfigBool(kConfigBool_disable_sticker_ve_safeguard)) {
        return [self.player getstickerEditBoundBox:stickerId];
    }
    
    CGRect value = [self.player getstickerEditBoundBox:stickerId];
    if (!isfinite(value.origin.x)) {
        value.origin.x = 0;
        
        AWELogToolError2(@"sticker_props_error", AWELogToolTagEdit, @"getstickerEditBoundBox_x, stickerID: %d", stickerId);
        [ACCMonitor() trackService:@"sticker_props_error"
                            status:1
                             extra:@{
                                 @"op_type": @"getstickerEditBoundBox_x",
                                 @"stickerID": @(stickerId)
                            }];
    }
    if (!isfinite(value.origin.y)) {
        value.origin.y = 0;
        
        AWELogToolError2(@"sticker_props_error", AWELogToolTagEdit, @"getstickerEditBoundBox_y, stickerID: %d", stickerId);
        [ACCMonitor() trackService:@"sticker_props_error"
                            status:1
                             extra:@{
                                 @"op_type": @"getstickerEditBoundBox_y",
                                 @"stickerID": @(stickerId)
                            }];
    }
    if (!isfinite(value.size.width)) {
        value.size.width = 0;
        
        AWELogToolError2(@"sticker_props_error", AWELogToolTagEdit, @"getstickerEditBoundBox_width, stickerID: %d", stickerId);
        [ACCMonitor() trackService:@"sticker_props_error"
                            status:1
                             extra:@{
                                 @"op_type": @"getstickerEditBoundBox_width",
                                 @"stickerID": @(stickerId)
                            }];
    }
    if (!isfinite(value.size.height)) {
        value.size.height = 0;
        
        AWELogToolError2(@"sticker_props_error", AWELogToolTagEdit, @"getstickerEditBoundBox_height, stickerID: %d", stickerId);
        [ACCMonitor() trackService:@"sticker_props_error"
                            status:1
                             extra:@{
                                 @"op_type": @"getstickerEditBoundBox_height",
                                 @"stickerID": @(stickerId)
                            }];
    }
    
    return value;
}

- (void)removeAllInfoStickers
{
    [self.player removeAllInfoSticker];
}

- (void)removeAll2DStickers
{
    [self.player removeAll2DSticker];
}

- (NSInteger)addTextStickerWithUserInfo:(NSDictionary *)userInfo
{
    return [self.player addTextStickerWithUserInfo:userInfo];
}

- (NSArray<IESInfoSticker *> *)infoStickers
{
    return self.player.acc_infoStickers;
}

- (void)setCaptionStickerImageBlock:(VEStickerImageBlock)captionStickerImageBlock
{
    self.player.imageBlock = captionStickerImageBlock;
}

- (VEStickerImageBlock)captionStickerImageBlock
{
    return self.player.imageBlock;
}

- (NSInteger)addInfoSticker:(NSString *)path withEffectInfo:(NSArray *)effectInfo userInfo:(NSDictionary *)userInfo imageEditorIndex:(NSInteger)imageEditorIndex
{
    NSAssert(NO, @"image edit mode only");
    return [self addInfoSticker:path withEffectInfo:effectInfo userInfo:userInfo];
}

- (void)beginCurrentImageEditorBatchUpdate
{
    NSAssert(NO, @"image edit mode only");
}

 - (void)endCurrentImageEditorBatchUpdate
{
    NSAssert(NO, @"image edit mode only");
}

- (CGFloat)getImageEditorTextStickerVEScaleWithImage:(UIImage *)image imagePath:(NSString *)path userInfo:(NSDictionary *)userInfo
{
    NSAssert(NO, @"image edit mode only");
    return 0.f;
}

- (void)setSrtManipulate:(NSInteger)stickerId state:(BOOL)state {}

@synthesize infoStickers = _infoStickers;
@synthesize captionStickerImageBlock = _captionStickerImageBlock;
@synthesize fixedTopInfoSticker = _fixedTopInfoSticker;

- (RACSubject<RACTwoTuple<NSNumber *,NSNumber *> *> *)stickerRegenerateSignal {
    if (!_stickerRegenerateSignal) {
        _stickerRegenerateSignal = [RACSubject subject];
    }
    return _stickerRegenerateSignal;
}

#pragma mark - batch

- (void)setStickersAbove:(nonnull NSArray<NSNumber *> *)stickerIds offsetX:(CGFloat)offsetX offsetY:(CGFloat)offsetY angle:(CGFloat)angle scale:(CGFloat)scale {
    [stickerIds acc_forEach:^(NSNumber * _Nonnull obj) {
        [self setSticker:obj.integerValue offsetX:offsetX offsetY:offsetY angle:angle scale:scale];
        [self setStickerAbove:obj.integerValue];
    }];
}


- (void)setStickersScale:(nonnull NSArray<NSNumber *> *)stickerIds scale:(CGFloat)scale {
    [stickerIds acc_forEach:^(NSNumber * _Nonnull obj) {
        [self setStickerScale:obj.integerValue scale:scale];
    }];
}

- (void)setStickerAlphas:(NSArray<NSNumber *> *)stickerIds alpha:(CGFloat)alpha above:(BOOL)above
{
    [stickerIds acc_forEach:^(NSNumber * _Nonnull obj) {
        [self setSticker:obj.integerValue alpha:alpha];
        if (above) {
            [self setStickerAbove:obj.integerValue];
        }
    }];
}

@end
