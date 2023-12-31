//
//  ACCImageAlbumEditStickerWraper.m
//  CameraClient-Pods-Aweme-CameraResource_douyin
//
//  Created by imqiuhang on 2020/12/23.
//

#import "ACCImageAlbumEditStickerWraper.h"
#import "ACCImageAlbumEditorSession.h"
#import "ACCImageAlbumStickerModel.h"
#import <TTVideoEditor/IESInfoSticker.h>
#import "ACCImageAlbumEditorDefine.h"
#import "ACCImageAlbumItemModel.h"
#import "ACCImageAlbumEditorDefine.h"
#import "ACCImageAlbumEditorGeometry.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <ReactiveObjC/RACSubject.h>

static CGFloat kTextStickerVEScaleStaticCache = 0.f;

@interface ACCImageAlbumEditStickerWraper() <ACCEditBuildListener>

@property (nonatomic, weak) id<ACCImageAlbumEditorSessionProtocol>player;

@property (nonatomic, assign) CGFloat textStickerVEScale;

@property (nonatomic, strong) RACSubject<RACTwoTuple<NSNumber *, NSNumber *> *> *stickerRegenerateSignal;

@end

@implementation ACCImageAlbumEditStickerWraper

- (void)dealloc
{
    [_stickerRegenerateSignal sendCompleted];
}

#pragma Mark - ACCEditBuildListener
- (void)setEditSessionProvider:(id<ACCEditSessionProvider>)editSessionProvider
{
    [editSessionProvider addEditSessionListener:self];
}

- (void)onEditSessionInit:(ACCEditSessionWrapper *)editSession
{
    self.player = editSession.imageEditSession;
}

@synthesize captionStickerImageBlock;
@synthesize fixedTopInfoSticker;
@synthesize infoStickers;

#pragma mark- add remove
- (void)removeInfoSticker:(NSInteger)stickerId
{
    [self.player removeInfoStickerWithUniqueId:stickerId];
}

- (NSInteger)addInfoSticker:(nonnull NSString *)path withEffectInfo:(nullable NSArray *)effectInfo userInfo:(nonnull NSDictionary *)userInfo
{
    return  [self addInfoSticker:path withEffectInfo:effectInfo userInfo:userInfo imageEditorIndex:self.player.currentIndex];
}

- (NSInteger)addInfoSticker:(NSString *)path withEffectInfo:(nullable NSArray *)effectInfo userInfo:(NSDictionary *)userInfo imageEditorIndex:(NSInteger)imageEditorIndex
{
    /// effectInfo是时间、天气等信息，图片模式下暂时不需要
    return [self.player addInfoStickerWithPath:path effectInfo:effectInfo userInfo:userInfo imageIndex:imageEditorIndex];
}

#pragma mark - update
- (void)setStickerAboveForInfoSticker:(NSInteger)stickerId
{
    [self setStickerAbove:stickerId];
}

- (void)setStickerAbove:(NSInteger)stickerId
{
    [self.player updateInfoStickerWithUniqueId:stickerId updateTypes:ACCImageAlbumEditorStickerUpdateTypeAbove props:nil];
}

- (void)setStickerAngle:(NSInteger)stickerId angle:(CGFloat)angle
{
    ACCImageAlbumStickerProps *props = [ACCImageAlbumStickerProps defaultProps];
    props.angle = [self p_imageAngleWithVideoInputScale:angle];
    [self.player updateInfoStickerWithUniqueId:stickerId updateTypes:ACCImageAlbumEditorStickerUpdateTypeRotation props:props];
}

- (void)setStickerScale:(NSInteger)stickerId scale:(CGFloat)scale
{
    ACCImageAlbumStickerProps *props = [ACCImageAlbumStickerProps defaultProps];
    props.scale = scale;
    [self.player updateInfoStickerWithUniqueId:stickerId updateTypes:ACCImageAlbumEditorStickerUpdateTypeScale props:props];
}

- (void)setSticker:(NSInteger)stickerId alpha:(CGFloat)alpha
{
    ACCImageAlbumStickerProps *props = [ACCImageAlbumStickerProps defaultProps];
    props.alpha = alpha;
    [self.player updateInfoStickerWithUniqueId:stickerId updateTypes:ACCImageAlbumEditorStickerUpdateTypeAlpha props:props];
}

- (void)setSticker:(NSInteger)stickerId offsetX:(CGFloat)offsetX offsetY:(CGFloat)offsetY
{
    NSValue *offsetValue = [self p_imagStickerOffsetWithVideoInputValueWithStickerId:stickerId offsetX:offsetX offsetY:offsetY];
    if (!offsetValue) {
        return;
    }
    ACCImageAlbumStickerProps *props = [ACCImageAlbumStickerProps defaultProps];
    [props updateOffset:[offsetValue CGPointValue]];
    [self.player updateInfoStickerWithUniqueId:stickerId updateTypes:ACCImageAlbumEditorStickerUpdateTypeOffset props:props];
}

- (void)setSticker:(NSInteger)stickerId offsetX:(CGFloat)offsetX offsetY:(CGFloat)offsetY angle:(CGFloat)angle scale:(CGFloat)scale
{
    [self beginCurrentImageEditorBatchUpdate];
    
    [self setStickerAngle:stickerId angle:angle];
    [self setStickerScale:stickerId scale:scale];
    [self setSticker:stickerId offsetX:offsetX offsetY:offsetY];
    
    [self endCurrentImageEditorBatchUpdate];

}

- (NSValue *)p_imagStickerOffsetWithVideoInputValueWithStickerId:(NSInteger)stickerId offsetX:(CGFloat)offsetX offsetY:(CGFloat)offsetY
{
    ACCImageAlbumStickerSearchResult *stickerWrap = [self.player stickerWithUniqueId:stickerId];
    if (!stickerWrap) {
        return nil;
    }
    // 计算的时候用整图的高度去计算 而不是裁剪后的
    CGSize playerImageLayerSize = [self.player imageLayerSizeAtIndex:stickerWrap.imageIndex needClip:NO];
    if (!ACCImageEditSizeIsValid(playerImageLayerSize)) {
        return nil;
    }

    CGPoint imageOffset = ACCImageEditorCovertVideoCenterAbsoluteOffsetToImageOffset(CGPointMake(offsetX, offsetY), playerImageLayerSize);
    return [NSValue valueWithCGPoint:imageOffset];
}

- (CGFloat)p_imageAngleWithVideoInputScale:(CGFloat)angle
{
    /// 图集旋转方向和视频的是相反的
    return -angle;
}

// 转换同见上方坐标系图示
- (CGPoint)p_covertImageOffsetToVideoOffset:(CGPoint)imageOffset imageSize:(CGSize)imageSize
{
    CGPoint videoRealPosition = CGPointMake(imageOffset.x * imageSize.width, imageOffset.y * imageSize.height);
    
    CGSize halfImageSize = CGSizeMake(imageSize.width/2, imageSize.height/2);
    
    CGFloat vx = videoRealPosition.x - halfImageSize.width;
    CGFloat vy = - (videoRealPosition.y - halfImageSize.height);
    return CGPointMake(vx, vy);
}


#pragma mark - getter
- (CGSize)getInfoStickerSize:(NSInteger)stickerId
{
    ACCImageAlbumStickerSearchResult *stickerWrap = [self.player stickerWithUniqueId:stickerId];
    if (!stickerWrap) {
        return CGSizeZero;
    }
    UIEdgeInsets boundingBox = [self.player getInfoStickerBoundingBoxWithUniqueId:stickerId];
    if (UIEdgeInsetsEqualToEdgeInsets(boundingBox, UIEdgeInsetsZero)) {
        return CGSizeZero;
    }
    CGSize relativeSize =  CGSizeMake(boundingBox.right - boundingBox.left, boundingBox.bottom - boundingBox.top);
    CGSize imageLayerSize = [self.player imageLayerSizeAtIndex:stickerWrap.imageIndex needClip:NO];
    return CGSizeMake(imageLayerSize.width * relativeSize.width , imageLayerSize.height * relativeSize.height);
}

- (CGSize)getstickerEditBoxSize:(NSInteger)stickerId
{
    return [self getInfoStickerSize:stickerId];
}

- (CGFloat)getStickerRotation:(NSInteger)stickerIndex
{
    /// 旋转的方向不一样
    return - [self.player stickerWithUniqueId:stickerIndex].sticker.param.angle;
}

- (void)getStickerId:(NSInteger)stickerId props:(nonnull IESInfoStickerProps *)props
{
    ACCImageAlbumStickerSearchResult *stickerWrap = [self.player stickerWithUniqueId:stickerId];
    ACCImageAlbumStickerProps *imageStickerProps = stickerWrap.sticker.param;
    
    props.stickerId = stickerId;
    props.angle = -imageStickerProps.angle;
    props.scale = imageStickerProps.scale;
    props.alpha = imageStickerProps.alpha;
    
    CGSize imageLayerSize = [self.player imageLayerSizeAtIndex:stickerWrap.imageIndex needClip:NO];
    if (ACCImageEditSizeIsValid(imageLayerSize)) {
        CGPoint videoOffset = [self p_covertImageOffsetToVideoOffset:CGPointMake(imageStickerProps.offsetX, imageStickerProps.offsetY) imageSize:imageLayerSize];
        props.offsetX = videoOffset.x;
        props.offsetY = videoOffset.y;
    }
    props.userInfo = stickerWrap.sticker.userInfo;
}

- (BOOL)getStickerVisible:(NSInteger)stickerIndex
{
    return YES;
}

- (void)beginCurrentImageEditorBatchUpdate
{
    [self.player beginCurrentImageEditorBatchUpdate];
}

- (void)endCurrentImageEditorBatchUpdate
{
    [self.player endCurrentImageEditorBatchUpdate];
}

- (CGFloat)getImageEditorTextStickerVEScaleWithImage:(UIImage *)image imagePath:(NSString *)path userInfo:(NSDictionary *)userInfo
{   
    if (self.textStickerVEScale != 0) {
        return self.textStickerVEScale;
    }
    
    /// 不得不说，这个取scale的方式也太....@todo 找VE开个接口取
    NSMutableDictionary *tempUserInfo = [NSMutableDictionary dictionaryWithDictionary:userInfo?:@{}];
    tempUserInfo[@"is_fake_add_key"] = @(YES);
    NSInteger stickerEditID = [self addInfoSticker:path withEffectInfo:nil userInfo:[tempUserInfo copy]];
    CGSize stickerSize = [self getInfoStickerSize:stickerEditID];
    if (!CGSizeEqualToSize(stickerSize, CGSizeZero)) {
        self.textStickerVEScale = image.scale / ACC_SCREEN_SCALE *  image.size.width / stickerSize.width;
        kTextStickerVEScaleStaticCache = self.textStickerVEScale;
    }
    [self.player removeInfoStickerWithUniqueId:stickerEditID traverseAllEditorIfNeed:YES];
    
    if (self.textStickerVEScale <= 0) {
        return kTextStickerVEScaleStaticCache;
    }
    
    return self.textStickerVEScale;
}

// ########################################################
// ##################### unsupported ######################
// ########################################################
#pragma mark - unsupported
- (void)removeAllInfoStickers
{

}

- (void)updateSticker:(NSInteger)stickerId  // 自动字幕
{

}

- (void)setStickerLayer:(NSInteger)stickerId layer:(NSInteger)layer
{
    
}

- (void)setTextStickerTextParams:(NSInteger)stickerId textParams:(nonnull NSString *)textParams
{
    
}

- (void)addStickerbyUIImage:(nonnull UIImage *)image letterInfo:(nullable NSString *)letterInfo duration:(CGFloat)duration
{
}

- (NSInteger)addTextStickerWithUserInfo:(nonnull NSDictionary *)userInfo
{
    
    return NSIntegerMin;
}

- (NSInteger)addSubtitleSticker
{
    
    return NSIntegerMin;
}

- (nonnull UIColor *)filterMusicLyricColor
{
    return [UIColor clearColor];
}

- (nonnull NSString *)filterMusicLyricEffectId
{
    return @"";
}

- (nonnull NSNumber *)filterMusicLyricStickerId
{
    return @(NSIntegerMin);
}

- (VEStickerPinStatus)getStickerPinStatus:(NSInteger)stickerIndex
{
    return VEStickerPinStatus_None;
}

- (BOOL)isAnimationSticker:(NSInteger)stickerID
{
    return NO;
}


- (void)removeAll2DStickers
{
    
}

- (void)setInfoStickerRestoreMode:(VEInfoStickerRestoreMode)mode
{
    
}

- (void)cancelPin:(NSInteger)stickerIndex
{
    
}

- (void)preparePin
{
    
}

// pin才会用到
- (CGPoint)getStickerPosition:(NSInteger)stickerId
{
    ACCImageAlbumStickerSearchResult *stickerWrap = [self.player stickerWithUniqueId:stickerId];
    if (!stickerWrap) {
        return CGPointZero;
    }
    UIEdgeInsets boundingBox = [self.player getInfoStickerBoundingBoxWithUniqueId:stickerId];
    CGSize size = [self getInfoStickerSize:stickerId];
    
    return CGPointMake(boundingBox.left + size.width/2.f, boundingBox.top + size.height/2.f);
}

// pin才会用到
- (CGRect)getstickerEditBoundBox:(NSInteger)stickerId
{
    CGPoint position = [self getStickerPosition:stickerId];
    CGSize size = [self getInfoStickerSize:stickerId];
    return CGRectMake(position.x - size.width/2.f, position.y - size.height/2.f, size.width, size.height);
}

- (void)setSrtAudioInfo:(NSInteger)stickerId seqIn:(NSTimeInterval)seqIn trimIn:(NSTimeInterval)trimIn duration:(NSTimeInterval)duration audioCycle:(BOOL)audioCycle
{
    
}

- (void)setSrtColor:(NSInteger)stickerId red:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b alpha:(CGFloat)a
{
    
}

- (void)setSrtFont:(NSInteger)stickerId fontPath:(nonnull NSString *)fontPath
{
    
}

- (void)setSrtInfo:(NSInteger)stickerId srt:(nonnull NSString *)srt
{
    
}

- (void)setSticker:(NSInteger)stickerId startTime:(CGFloat)startTime duration:(CGFloat)duration
{
    
}

- (void)startChangeStickerDuration:(NSInteger)stickerId
{
    
}

- (void)startPin:(NSInteger)stickerIndex pinStartTime:(float)pinStartTime pinDuration:(float)duration completion:(nonnull void (^)(BOOL, NSError * _Nonnull))completion
{
    
}

- (void)stopChangeStickerDuration:(NSInteger)stickerId
{
    
}

- (NSInteger)setStickerAnimationWithStckerID:(NSInteger)stickerID animationType:(NSInteger)animationType filePath:(nonnull NSString *)filePath duration:(CGFloat)duration {
    NSAssert(NO, @"");
    return 0;
}

- (void)setSrtManipulate:(NSInteger)stickerId state:(BOOL)state {}


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
