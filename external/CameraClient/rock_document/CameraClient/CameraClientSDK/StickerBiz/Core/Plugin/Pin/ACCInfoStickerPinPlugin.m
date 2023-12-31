//
//  ACCInfoStickerPinPlugin.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/9/30.
//

#import "ACCInfoStickerPinPlugin.h"
#import "ACCInfoStickerContentView.h"
#import "AWEPinStickerUtil.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreativeKitSticker/ACCBaseStickerView.h>

#import "ACCStickerBizDefines.h"
#import "ACCCommonStickerConfig.h"
#import <CreativeKitSticker/ACCStickerEventFlowProtocol.h>

@implementation ACCInfoStickerPinPlugin
@synthesize stickerContainer = _stickerContainer;

- (ACCStickerContainerFeature)implementedContainerFeature
{
    return ACCStickerContainerFeatureInfoPin;
}

+ (instancetype)createPlugin
{
    return [[ACCInfoStickerPinPlugin alloc] init];
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onAppDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)loadPlugin
{
    
}

- (void)playerFrameChange:(CGRect)playerFrame
{
    
}

- (void)stickerContainer:(UIView<ACCStickerContainerProtocol> *)container beforeRecognizerGesture:(UIGestureRecognizer *)gesture
{
    CGPoint touchPoint = [gesture locationInView:[self.stickerContainer containerView]];

    if (isnan(touchPoint.x) || isnan(touchPoint.y)) {
        return ;
    }
    CGPoint touchPointOnContainerView = touchPoint;
    CGSize videoFrameSize = self.stickerContainer.playerRect.size;
    
    // Found any view whit priority higher than pined sticker to response; so should not cancel pin any sticker
    if ([self.stickerContainer targetViewFor:gesture] != nil) {
        return;
    }
    [[self.stickerContainer allStickerViews] enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.contentView isKindOfClass:ACCInfoStickerContentView.class]) {
            ACCInfoStickerContentView *infoContentView = (id)obj.contentView;
            NSInteger stickerId = infoContentView.stickerId;
            
            if ([self.editStickerService getStickerPinStatus:stickerId] == VEStickerPinStatus_Pinned &&
                [self.editStickerService getStickerVisible:stickerId]) {
                CGSize size = [self.editStickerService getstickerEditBoundBox:stickerId].size;
                CGFloat rotation = [self.editStickerService getStickerRotation:stickerId];
                CGFloat fixedRotationInRadian = @(rotation).intValue % 360;

                if (fixedRotationInRadian < 0) {
                    fixedRotationInRadian += 180.f;
                }
                fixedRotationInRadian = fixedRotationInRadian * M_PI / 180;

                // 这个相对于视频分辨率范围[-1,1]，坐标(0,0)在视频中心。
                CGPoint relativeCenter = [self.editStickerService getStickerPosition:stickerId];
                // 将坐标原点修正到UIView的坐标系
                CGPoint fixedRelativeCenter = CGPointMake((relativeCenter.x + 1) / 2.f, (1 - relativeCenter.y) / 2.f);
                CGPoint center = CGPointMake(fixedRelativeCenter.x * videoFrameSize.width + self.stickerContainer.playerRect.origin.x,
                                             fixedRelativeCenter.y * videoFrameSize.height + self.stickerContainer.playerRect.origin.y);

                CGRect innerBoundingBox = CGRectMake(center.x - size.width / 2.f, center.y - size.height / 2.f, size.width, size.height);

                CGFloat stickerViewW = innerBoundingBox.size.height * fabs(sinf(fixedRotationInRadian)) + innerBoundingBox.size.width * fabs(cosf(fixedRotationInRadian));
                CGFloat stickerViewH = innerBoundingBox.size.width * fabs(sinf(fixedRotationInRadian)) + innerBoundingBox.size.height * fabs(cosf(fixedRotationInRadian));

                CGFloat outterBoundingBoxWidth = stickerViewH * fabs(sinf(fixedRotationInRadian)) + stickerViewW * fabs(cosf(fixedRotationInRadian));
                CGFloat outterBoundingBoxHeight = stickerViewW * fabs(sinf(fixedRotationInRadian)) + stickerViewH * fabs(cosf(fixedRotationInRadian));

                CGRect outterBoundingBox = CGRectMake(center.x - outterBoundingBoxWidth / 2.f,
                                                      center.y - outterBoundingBoxHeight / 2.f,
                                                      outterBoundingBoxWidth,
                                                      outterBoundingBoxHeight);

                //1. 首先检测点击点是否在最外部的boundingbox内部
                BOOL outterBBoxContain = CGRectContainsPoint(outterBoundingBox, touchPointOnContainerView);
                if (outterBBoxContain) {
                    //2. 根据rotation+boundingBox计算是否点击到了实际的贴纸区域
                    [AWEPinStickerUtil isTouchPointInStickerAreaWithPoint:touchPointOnContainerView
                                                 boundingBox:outterBoundingBox
                                               innerRectSize:CGSizeMake(stickerViewW, stickerViewH)
                                                    rotation:fixedRotationInRadian
                                                  completion:^(BOOL contain, CGSize trueSize) {
                        if (contain) {
                            [infoContentView didCancledPin];
                            
                            if ([self.editStickerService getStickerVisible:stickerId]) {
                                [self.editStickerService cancelPin:stickerId];
                            }
                            // 立即恢复坐标
                            [self resetStickerViewAfterCancelPin:obj stickerId:stickerId];
                            
                            // CancelPin之后会在下一帧让Pin失去效果，如果遇到被钉住的主物体在空间内移动或者缩放突变的情况会出现壳视图框恢复和
                            // 贴纸实际位置不同步的情况，所以需要进行额外的修正。
                            // 帧率：<= 30fps。
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1/30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                [self resetStickerViewAfterCancelPin:obj stickerId:stickerId];
                                IESInfoStickerProps *props = [IESInfoStickerProps new];
                                [self.editStickerService getStickerId:stickerId props:props];
                                
                                infoContentView.stickerInfos = props;
                                [self.editStickerService setSticker:stickerId offsetX:props.offsetX offsetY:props.offsetY angle:props.angle scale:1];
                            });
                            *stop = YES;
                        }
                    }];
                }
            }
        }
    }];
}

- (void)resetStickerViewAfterCancelPin:(ACCStickerViewType)stickerWrapper stickerId:(NSInteger)stickerId
{
    stickerWrapper.hidden = NO;
    if ([stickerWrapper isKindOfClass:ACCBaseStickerView.class]) {
        ACCBaseStickerView *baseWrapper = (id)stickerWrapper;
        baseWrapper.foreverHidden = NO;
    }
    
    IESInfoStickerProps *props = [IESInfoStickerProps new];
    [self.editStickerService getStickerId:stickerId props:props];
    
    ACCStickerGeometryModel *geoModel = [stickerWrapper.stickerGeometry copy];
    geoModel.x = [[NSDecimalNumber alloc] initWithFloat:props.offsetX];
    geoModel.y = [[NSDecimalNumber alloc] initWithFloat:-props.offsetY];
    geoModel.rotation = [[NSDecimalNumber alloc] initWithFloat:props.angle];
    geoModel.scale = [[NSDecimalNumber alloc] initWithFloat:props.scale];
    
    [stickerWrapper recoverWithGeometryModel:geoModel];
}

- (void)cancelPinStickerWithStickerId:(NSInteger )stickerId
{
    __block ACCStickerViewType targetViewType = nil;
    __block ACCInfoStickerContentView *targetInfoContentView = nil;
    [[self.stickerContainer allStickerViews] enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.contentView isKindOfClass:ACCInfoStickerContentView.class]) {
            ACCInfoStickerContentView *infoContentView = (id)obj.contentView;
            if (stickerId == infoContentView.stickerId) {
                targetViewType = obj;
                targetInfoContentView = infoContentView;
                *stop = YES;
            }
        }
    }];
    
    [self.editStickerService cancelPin:stickerId];
    // 立即恢复坐标
    [self resetStickerViewAfterCancelPin:targetViewType stickerId:stickerId];
    
    // CancelPin之后会在下一帧让Pin失去效果，如果遇到被钉住的主物体在空间内移动或者缩放突变的情况会出现壳视图框恢复和
    // 贴纸实际位置不同步的情况，所以需要进行额外的修正。
    // 帧率：<= 30fps。
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1/30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self resetStickerViewAfterCancelPin:targetViewType stickerId:stickerId];
        IESInfoStickerProps *props = [IESInfoStickerProps new];
        [self.editStickerService getStickerId:stickerId props:props];
        
        targetInfoContentView.stickerInfos = props;
        [self.editStickerService setSticker:stickerId offsetX:props.offsetX offsetY:props.offsetY angle:props.angle scale:1];
    });
}

- (void)cancelAllPinnedSticker
{
    [[self.stickerContainer allStickerViews] enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.contentView isKindOfClass:ACCInfoStickerContentView.class]) {
            ACCInfoStickerContentView *infoContentView = (id)obj.contentView;
            if ([self.editStickerService getStickerPinStatus:infoContentView.stickerId] == VEStickerPinStatus_Pinned) {
                [self cancelPinStickerWithStickerId:infoContentView.stickerId];
            }
        }
    }];
}

- (void)cancelAllPinningSticker
{
    [[self.stickerContainer allStickerViews] enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.contentView isKindOfClass:ACCInfoStickerContentView.class]) {
            ACCInfoStickerContentView *infoContentView = (id)obj.contentView;
            if ([self.editStickerService getStickerPinStatus:infoContentView.stickerId] == VEStickerPinStatus_Pinning) {
                [self cancelPinStickerWithStickerId:infoContentView.stickerId];
            }
        }
    }];
}

- (BOOL)featureSupportSticker:(id<ACCStickerProtocol>)sticker
{
    if (![sticker.config isKindOfClass:[ACCCommonStickerConfig class]]) {
        return NO;
    }
    return [self implementedContainerFeature] & ((ACCCommonStickerConfig *)sticker.config).preferredContainerFeature;
}

- (void)onAppDidEnterBackground {
    [self cancelAllPinningSticker];
}

@end
