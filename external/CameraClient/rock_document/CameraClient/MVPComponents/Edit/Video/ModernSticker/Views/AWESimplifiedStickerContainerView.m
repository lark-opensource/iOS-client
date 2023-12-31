//
//  AWESimplifiedSitckerContainerView.m
//  Pods
//
//  Created by jindulys on 2019/4/12.
//

#import "AWESimplifiedStickerContainerView.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import "AWEPinStickerUtil.h"
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreationKitInfra/ACCRTLProtocol.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import "AWERepoVideoInfoModel.h"

@interface AWESimplifiedStickerContainerView()

@property (nonatomic, strong, readwrite) NSMutableArray<AWEVideoStickerEditCircleView *> *stickerViews;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *cancelPinStickerIdArray;

@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;

@property (nonatomic, assign) CGFloat currentPlayerTime;
@property (nonatomic, strong) AWEVideoStickerEditCircleView *lastTimeSelectedStickerView;

@property (nonatomic, assign) CGPoint mediaCenter;

@property (nonatomic, assign) CGRect originalPlayerRect;
@property (nonatomic, assign) CGFloat toApplyDeltaX;
@property (nonatomic, assign) CGFloat toApplyDeltaY;
@property (nonatomic, assign) CGFloat toApplyWidthScale;
@property (nonatomic, assign) CGFloat toApplyHeightScale;

@end

@implementation AWESimplifiedStickerContainerView

- (instancetype)initWithFrame:(CGRect)frame publishModel:(AWEVideoPublishViewModel *)publishModel playerOriginalRect:(CGRect)playerRect
{
    self = [super initWithFrame:frame];
    if (self) {
        _stickerViews = [NSMutableArray array];
        _publishModel = publishModel;
        _originalPlayerRect = playerRect;
        _cancelPinStickerIdArray = [NSMutableArray new];
        [self generateParamsWithFrame:frame];
    }
    return self;
}

- (void)generateParamsWithFrame:(CGRect)frame {
    _toApplyDeltaX = frame.origin.x - _originalPlayerRect.origin.x;
    _toApplyDeltaY = frame.origin.y - _originalPlayerRect.origin.y;
    _toApplyWidthScale = frame.size.width / _originalPlayerRect.size.width;
    _toApplyHeightScale = frame.size.height / _originalPlayerRect.size.height;
}

#pragma mark - Public

// 恢复贴纸框
- (void)recoverStickerWithStickerInfos:(IESInfoStickerProps *)infos editSize:(CGSize)size setCurrentSticker:(BOOL)setCurrentSticker
{
    if (isnan(infos.offsetX)) {
        infos.offsetX = 0;
    }
    if (isnan(infos.offsetY)) {
        infos.offsetY = 0;
    }
    
    CGSize transferedSize = CGSizeMake(size.width * self.toApplyWidthScale, size.height * self.toApplyHeightScale);
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    
    AWEVideoStickerEditCircleView *stickerCircleView = [[AWEVideoStickerEditCircleView alloc] initWithFrame:CGRectMake(0, 0, transferedSize.width, transferedSize.height) isForImage:NO];
    stickerCircleView.originalSize = transferedSize;
    stickerCircleView.stickerInfos = infos;
    
    CGFloat offsetX = infos.offsetX;
    CGFloat stickerAngle = infos.angle * M_PI / 180.0;
    if (ACCRTL().isRTL) {
        offsetX = -offsetX;
        stickerAngle = -stickerAngle;
    }
    offsetX *= self.toApplyWidthScale;
    stickerCircleView.center = CGPointMake(center.x + offsetX, center.y - infos.offsetY * self.toApplyHeightScale);
    stickerCircleView.transform = CGAffineTransformMakeRotation(stickerAngle);
    self.mediaCenter = center;
    [self.stickerViews addObject:stickerCircleView];
    [self addSubview:stickerCircleView];
    if (setCurrentSticker) {
        self.currentStickerView = stickerCircleView;
    }
}

- (void)makeAllStickersResignActive
{
    // 记录一下上次选中的sticker
    self.lastTimeSelectedStickerView = self.currentStickerView;
    self.currentStickerView = nil;
}

- (void)restoreLastTimeSelectStickerView
{
    self.currentStickerView = self.lastTimeSelectedStickerView;
    self.lastTimeSelectedStickerView = nil;
}

- (void)updateViewsStatusWithCurrentPlayerTime:(CGFloat)currentPlayerTime
{
    for (AWEVideoStickerEditCircleView *stickerView in self.stickerViews) {
        CGFloat startTime = stickerView.realStartTime;
        CGFloat duration = stickerView.realDuration;

        if (stickerView.stickerEditId == self.currentStickerView.stickerEditId) {
            continue;
        }

        if ((ACC_FLOAT_GREATER_THAN(currentPlayerTime, startTime) || fabs(currentPlayerTime - startTime) < 0.1) && duration < 0) {
            stickerView.hidden = NO;
            continue;
        }

        if (stickerView.hidden && ACC_FLOAT_GREATER_THAN(currentPlayerTime, startTime) && ACC_FLOAT_LESS_THAN(currentPlayerTime, startTime + duration)) {
            stickerView.hidden = NO;
        }

        if (stickerView.hidden && (fabs(currentPlayerTime - startTime) < 0.1 || fabs(currentPlayerTime - startTime - duration) < 0.1)) {
            stickerView.hidden = NO;
        }

        if (!stickerView.hidden && (ACC_FLOAT_GREATER_THAN(currentPlayerTime, startTime + duration) || ACC_FLOAT_LESS_THAN(currentPlayerTime, startTime))) {
            stickerView.hidden = YES;
        }
    }
}


#pragma mark - Protocols

- (void)editorSticker:(UIView *)editView receivedTapGesture:(UITapGestureRecognizer *)gesture
{
    AWEVideoStickerEditCircleView *innerEditView = (AWEVideoStickerEditCircleView *)editView;

    // Pin Intercept Start - 判断当前点击的坐标中是否包含被Pin住的信息化贴纸（实际在视频中被Pin住的位置）
    CGPoint point = [gesture locationInView:self];
    if ([ACCRTL() isRTL]) {
        point.x = self.frame.size.width - point.x;
    }
    if ((!innerEditView || [self.editService.sticker getStickerPinStatus:innerEditView.stickerInfos.stickerId] == VEStickerPinStatus_Pinned) &&
        [self hasAnyPinnedInfoSticker]) {
        innerEditView = [self touchPinnedStickerInVideoAndCancelPin:[NSValue valueWithCGPoint:point]];
    }

    if (![innerEditView isKindOfClass:[AWEVideoStickerEditCircleView class]] || [innerEditView isEqual:self.currentStickerView]) {
        AWELogToolInfo(AWELogToolTagEdit, @"==== PIN ==== AWESimplifiedStickerContainerView tapAction return because of ![innerEditView isKindOfClass:[AWEVideoStickerEditCircleView class]] || [innerEditView isEqual:self.currentStickerView]");
         return;
    }

    [self selectStickerView:innerEditView];
}

- (void)editorSticker:(UIView *)editView receivedPanGesture:(UIPanGestureRecognizer *)gesture
{
    AWEVideoStickerEditCircleView *innerEditView = (AWEVideoStickerEditCircleView *)editView;

    // Pin Intercept Start - 判断当前点击的坐标中是否包含被Pin住的信息化贴纸（实际在视频中被Pin住的位置）
    CGPoint point = [gesture locationInView:self];
    if ([ACCRTL() isRTL]) {
        point.x = self.frame.size.width - point.x;
    }
    if ((!innerEditView || [self.editService.sticker getStickerPinStatus:innerEditView.stickerInfos.stickerId] == VEStickerPinStatus_Pinned) &&
        [self hasAnyPinnedInfoSticker]) {
        innerEditView = [self touchPinnedStickerInVideoAndCancelPin:[NSValue valueWithCGPoint:point]];
    }

    if (![editView isKindOfClass:[AWEVideoStickerEditCircleView class]]) {
        return;
    }
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self selectStickerView:innerEditView];
        return;
    }
    
    if (!self.currentStickerView) {
        // 如果没有设置currentStickerView，则不需要操作
        return;
    }
    
    CGPoint currentPoint = [gesture translationInView:self];
    CGPoint newCenter = CGPointMake(innerEditView.center.x + currentPoint.x, innerEditView.center.y + currentPoint.y);
    if (gesture.state == UIGestureRecognizerStateChanged) {
        innerEditView.center = newCenter;
        [gesture setTranslation:CGPointZero inView:self];
        // 还需要做scale的反向变换，这样子位移在视频里就是对的
        CGFloat offsetX = (innerEditView.center.x - self.mediaCenter.x) / self.toApplyWidthScale;
        CGFloat offsetY = (-(innerEditView.center.y - self.mediaCenter.y)) / self.toApplyHeightScale;
        if ([self.delegate respondsToSelector:@selector(setSticker:offsetX:offsetY:angle:scale:)]) {
            CGFloat stickerAngle = innerEditView.stickerInfos.angle;
            if (ACCRTL().isRTL) {
                offsetX = -offsetX;
                stickerAngle = -stickerAngle;
            }
            [self.delegate setSticker:innerEditView.stickerInfos.stickerId offsetX:offsetX offsetY:offsetY angle:stickerAngle scale:1];
            innerEditView.stickerInfos.offsetX = offsetX;
            innerEditView.stickerInfos.offsetY = offsetY;
        }
    } else if (gesture.state == UIGestureRecognizerStateEnded ||
               gesture.state == UIGestureRecognizerStateCancelled) {
        [self gestureEndWithStickerView:self.currentStickerView];
    }
}

- (void)editorSticker:(UIView *)editView receivedPinchGesture:(UIPinchGestureRecognizer *)gesture
{
    AWEVideoStickerEditCircleView *innerEditView = (AWEVideoStickerEditCircleView *)editView;

    // Pin Intercept Start - 判断当前点击的坐标中是否包含被Pin住的信息化贴纸（实际在视频中被Pin住的位置）
    CGPoint point = [gesture locationInView:self];
    if ([ACCRTL() isRTL]) {
        point.x = self.frame.size.width - point.x;
    }
    if ((!innerEditView || [self.editService.sticker getStickerPinStatus:innerEditView.stickerInfos.stickerId] == VEStickerPinStatus_Pinned) &&
        [self hasAnyPinnedInfoSticker]) {
        innerEditView = [self touchPinnedStickerInVideoAndCancelPin:[NSValue valueWithCGPoint:point]];
    }

    if (editView && ![editView isKindOfClass:[AWEVideoStickerEditCircleView class]]) {
        return;
    }

    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self selectStickerView:innerEditView];
        return;
    }
    
    if (!self.currentStickerView) {
        // 如果没有设置currentStickerView，则不需要操作
        return;
    }
    
    if (gesture.state == UIGestureRecognizerStateChanged) {
        CGFloat scale = gesture.scale;
        CGRect bounds = innerEditView.bounds;
        CGRect newBounds = CGRectMake(0, 0, bounds.size.width * scale, bounds.size.height * scale);
        innerEditView.bounds = newBounds;
        if ([self.delegate respondsToSelector:@selector(setSticker:offsetX:offsetY:angle:scale:)]) {
            CGFloat stickerAngle = self.currentStickerView.stickerInfos.angle;
            if (ACCRTL().isRTL) {
                stickerAngle = -stickerAngle;
            }
            [self.delegate setSticker:innerEditView.stickerInfos.stickerId
                              offsetX:innerEditView.stickerInfos.offsetX
                              offsetY:innerEditView.stickerInfos.offsetY
                                angle:stickerAngle
                                scale:scale];
        }
        [gesture setScale:1.f];
    } else if (gesture.state == UIGestureRecognizerStateEnded ||
               gesture.state == UIGestureRecognizerStateCancelled) {
        [self gestureEndWithStickerView:self.currentStickerView];
    }
    
}

- (void)editorSticker:(UIView *)editView receivedRotationGesture:(UIRotationGestureRecognizer *)gesture
{
    AWEVideoStickerEditCircleView *innerEditView = (AWEVideoStickerEditCircleView *)editView;

    // Pin Intercept Start - 判断当前点击的坐标中是否包含被Pin住的信息化贴纸（实际在视频中被Pin住的位置）
    CGPoint point = [gesture locationInView:self];
    if ([ACCRTL() isRTL]) {
        point.x = self.frame.size.width - point.x;
    }
    if ((!innerEditView || [self.editService.sticker getStickerPinStatus:innerEditView.stickerInfos.stickerId] == VEStickerPinStatus_Pinned) &&
        [self hasAnyPinnedInfoSticker]) {
        innerEditView = [self touchPinnedStickerInVideoAndCancelPin:[NSValue valueWithCGPoint:point]];
    }

    if (editView && ![editView isKindOfClass:[AWEVideoStickerEditCircleView class]]) {
        return;
    }

    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self selectStickerView:innerEditView];
        return;
    }
    
    if (!self.currentStickerView) {
        // 如果没有设置currentStickerView，则不需要操作
        return;
    }
    
    if (gesture.state == UIGestureRecognizerStateChanged) {
        CGFloat angle = gesture.rotation;
        
        if ([self.delegate respondsToSelector:@selector(setSticker:offsetX:offsetY:angle:scale:)]) {
            [innerEditView setTransform:CGAffineTransformMakeRotation(angle)];
            
            CGFloat stickerAngle = self.currentStickerView.stickerInfos.angle + angle * 180.0 / M_PI;
            if (ACCRTL().isRTL) {
                stickerAngle = -stickerAngle;
            }
            [self.delegate setSticker:self.currentStickerView.stickerEditId
                              offsetX:self.currentStickerView.stickerInfos.offsetX
                              offsetY:self.currentStickerView.stickerInfos.offsetY
                                angle:stickerAngle
                                scale:1];
            self.currentStickerView.stickerInfos.angle += angle * 180.0 / M_PI;
        }
        gesture.rotation = 0.f;
    } else if (gesture.state == UIGestureRecognizerStateEnded ||
               gesture.state == UIGestureRecognizerStateCancelled) {
        [self gestureEndWithStickerView:self.currentStickerView];
    }
}

- (void)editorStickerGestureStarted
{
    // 空实现
}

#pragma mark - Private

- (void)selectStickerView:(AWEVideoStickerEditCircleView *)stickerView
{
    if (![stickerView isKindOfClass:[AWEVideoStickerEditCircleView class]] ||
        [stickerView isEqual:self.currentStickerView]) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(activeSticker:)]) {
        if ([self.delegate activeSticker:stickerView.stickerEditId]) {
            [self.stickerViews removeObject:stickerView];
            [self.stickerViews addObject:stickerView];
            [self bringSubviewToFront:stickerView];
            self.currentStickerView = stickerView;
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.publishModel.repoTrack.referExtra];
            params[@"prop_id"] = stickerView.stickerInfos.userInfo[@"stickerID"] ?: @"";
            params[@"enter_method"] = @"change";
            params[@"is_diy_prop"] = @(stickerView.isCustomUploadSticker);
            [ACCTracker() trackEvent:@"prop_time_set"
                                             params:params
                                    needStagingFlag:NO];
        }
    }
}

- (void)gestureEndWithStickerView:(AWEVideoStickerEditCircleView *)stickerView
{
    if ([self.delegate respondsToSelector:@selector(handleStickerFinished)]) {
        [self.delegate handleStickerFinished];
    }
    
    if (!stickerView) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(getStickerId:props:)]) {
        IESInfoStickerProps *stickerInfos = [[IESInfoStickerProps alloc] init];
        [self.delegate getSticker:stickerView.stickerEditId props:stickerInfos];
        stickerView.stickerInfos = stickerInfos;
        if (ACCRTL().isRTL) {
            stickerView.stickerInfos.angle = -stickerInfos.angle;
        }
    }
    
    CGFloat viewAngle = [(NSNumber *)[stickerView valueForKeyPath:@"layer.transform.rotation.z"] floatValue];
    CGFloat stickerAngle = stickerView.stickerInfos.angle * M_PI / 180.0;
    
    // 修正手势旋转角度，使之与贴纸实际旋转角度匹配
    if (!ACC_FLOAT_EQUAL_TO(viewAngle, stickerAngle) &&
        [self.delegate respondsToSelector:@selector(setSticker:offsetX:offsetY:angle:scale:)]) {
        stickerView.transform = CGAffineTransformRotate(stickerView.transform, stickerAngle - viewAngle);
        CGFloat angle = stickerView.stickerInfos.angle;
        if (ACCRTL().isRTL) {
            angle = -angle;
        }
        [self.delegate setSticker:stickerView.stickerEditId
                          offsetX:stickerView.stickerInfos.offsetX
                          offsetY:stickerView.stickerInfos.offsetY
                            angle:angle
                            scale:1];
        
    }
}

#pragma mark - UIViewGeometry

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *tmpView = [super hitTest:point withEvent:event];
    
    if (tmpView == self) {
        return nil;
    }
    return tmpView;
}


#pragma mark - Pin

/// 是否有任何一个信息化贴纸被Pin住
- (BOOL)hasAnyPinnedInfoSticker {
    __block BOOL r = NO;
    [self.publishModel.repoVideoInfo.video.infoStickers enumerateObjectsUsingBlock:^(IESInfoSticker * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.pinStatus == VEStickerPinStatus_Pinned) {
            r = YES;
            *stop = YES;
        }
    }];
    return r;
}


/// 取消Pin后，因为Pin的过程中信息化贴纸的位置会随着视频而变化，取消Pin之后对壳视图的位置进行更新
/// @param stickerId 贴纸id
- (void)resetStickerViewAfterCancelPin:(NSInteger)stickerId center:(CGPoint)center viewSize:(CGSize)viewSize {

    IESInfoStickerProps *props = [IESInfoStickerProps new];
    [self.editService.sticker getStickerId:stickerId props:props];
    CGFloat videoDuration = self.publishModel.repoVideoInfo.video.totalVideoDuration;
    if (props.duration < 0 || props.duration > videoDuration) {
        props.duration = videoDuration;
    }
    float angle = props.angle;
    if (ACCRTL().isRTL) {
        props.angle = -angle;
    }
    [self updateStickerWithStickerInfos:props viewSize:viewSize center:center];
    // there is a frame diff between VE and Effect under VE Cross Platform, so VE always use data from user actions, getStickerId:props only means get data from effect; we should set data to VE
    [self.editService.sticker setSticker:stickerId offsetX:props.offsetX offsetY:props.offsetY angle:props.angle scale:1];
}

/// AWEVideoStickerEditCircleView这个壳视图对应的sticker是否是被Pin住了
/// @param sticker 壳视图
- (BOOL)videoStickerHasBeenPinned:(AWEVideoStickerEditCircleView *)sticker {
    if (!sticker) {
        return NO;
    }
    __block BOOL pinned = NO;
    [self.publishModel.repoVideoInfo.video.infoStickers enumerateObjectsUsingBlock:^(IESInfoSticker * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.stickerId == sticker.stickerEditId && obj.pinStatus == VEStickerPinStatus_Pinned) {
            pinned = YES;
        }
    }];
    return pinned;
}


/// 检测是否点中了已经被Pin住的贴纸，不是指壳视图，指的是实际视频中看到的特效贴纸。
/// 如果是，则取消Pin。
/// @param touchPoint 点击的坐标，坐标系需要在containerView上。
/// 这个touchPoint是相对于containerView的，视频展示的playerFrame会有一些出入，
/// 需要计算，因为playerFrame和containerView是垂直或者水平上是居中的
///（取决于剪裁了哪一边），可以直接根据origin.x计算
- (AWEVideoStickerEditCircleView *)touchPinnedStickerInVideoAndCancelPin:(NSValue *)touchPointValue {
    AWELogToolInfo(AWELogToolTagEdit, @"==== PIN ==== AWESimplifiedStickerContainerView touchPinnedStickerInVideoAndCancelPin center:%@", touchPointValue);
    if (!touchPointValue) {
        return nil;
    }
    CGPoint touchPoint = [touchPointValue CGPointValue];
    if (isnan(touchPoint.x) || isnan(touchPoint.y)) {
        return nil;
    }
    CGPoint touchPointOnContainerView = touchPoint;

    __block BOOL touched = NO;
    __block AWEVideoStickerEditCircleView *stickerView = nil;

    CGSize videoFrameSize = self.frame.size;

    [self.publishModel.repoVideoInfo.video.infoStickers enumerateObjectsUsingBlock:^(IESInfoSticker * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        AWELogToolInfo(AWELogToolTagEdit, @"==== PIN ==== AWESimplifiedStickerContainerView touchPinnedStickerInVideoAndCancelPin enumerate idx:%@ pinned:%@ visible:%@ player:%@", @(idx),  obj.pinStatus == VEStickerPinStatus_Pinned ? @"YES" : @"NO", [self.editService.sticker getStickerVisible:obj.stickerId] ? @"YES" : @"NO", self.editService);
        if (obj.pinStatus == VEStickerPinStatus_Pinned && [self.editService.sticker getStickerVisible:obj.stickerId]) {
            CGSize size = [self.editService.sticker getstickerEditBoundBox:obj.stickerId].size;
            CGFloat rotation = [self.editService.sticker getStickerRotation:obj.stickerId];
            CGFloat fixedRotationInRadian = @(rotation).intValue % 360;

            if (fixedRotationInRadian < 0) {
                fixedRotationInRadian += 180.f;
            }
            fixedRotationInRadian = fixedRotationInRadian * M_PI / 180;

            // 这个相对于视频分辨率范围[-1,1]，坐标(0,0)在视频中心。
            CGPoint relativeCenter = [self.editService.sticker getStickerPosition:obj.stickerId];
            // 将坐标原点修正到UIView的坐标系
            CGPoint fixedRelativeCenter = CGPointMake((relativeCenter.x + 1) / 2.f, (1 - relativeCenter.y) / 2.f);
            CGPoint center = CGPointMake(fixedRelativeCenter.x * videoFrameSize.width + self.playerFrame.CGRectValue.origin.x,
                                         fixedRelativeCenter.y * videoFrameSize.height + self.playerFrame.CGRectValue.origin.y);

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
            AWELogToolInfo(AWELogToolTagEdit, @"==== PIN ==== AWESimplifiedStickerContainerView touchPinnedStickerInVideoAndCancelPin outterBBoxContain:%@", outterBBoxContain ? @"YES" : @"NO");
            if (outterBBoxContain) {
                //2. 根据rotation+boundingBox计算是否点击到了实际的贴纸区域
                [AWEPinStickerUtil isTouchPointInStickerAreaWithPoint:touchPointOnContainerView
                                             boundingBox:outterBoundingBox
                                           innerRectSize:CGSizeMake(stickerViewW, stickerViewH)
                                                rotation:fixedRotationInRadian
                                              completion:^(BOOL contain, CGSize trueSize) {
                    AWELogToolInfo(AWELogToolTagEdit, @"==== PIN ==== AWESimplifiedStickerContainerView touchPinnedStickerInVideoAndCancelPin contain:%@", contain ? @"YES" : @"NO");
                    if (contain) {
                        if ([self.delegate conformsToProtocol:@protocol(AWESimplifiedStickerContainerViewDelegate)] &&
                            [self.delegate respondsToSelector:@selector(cancelPinSticker:)]) {
                            // 取消Pin
                            [self.delegate cancelPinSticker:obj.stickerId];
                            [self.cancelPinStickerIdArray addObject:@(obj.stickerId)];
                            AWELogToolInfo(AWELogToolTagEdit, @"==== PIN ==== AWESimplifiedStickerContainerView touchPinnedStickerInVideoAndCancelPin cancel pin");
                        }
                        [self resetStickerViewAfterCancelPin:obj.stickerId center:center viewSize:trueSize];
                        touched = YES;
                        [self.stickerViews enumerateObjectsUsingBlock:^(AWEVideoStickerEditCircleView * _Nonnull innerObj, NSUInteger innerIdx, BOOL * _Nonnull innerStop) {
                            if (innerObj.stickerEditId == obj.stickerId) {
                                stickerView = innerObj;
                                // 恢复可视，恢复手势点击
                                stickerView.hidden = NO;
                                *innerStop = YES;
                            }
                        }];
                        *stop = YES;
                    }
                }];
            }
        }
    }];
    return stickerView;
}

// 更新贴纸框
- (void)updateStickerWithStickerInfos:(IESInfoStickerProps *)infos viewSize:(CGSize)viewSize center:(CGPoint)center {
    [self.stickerViews enumerateObjectsUsingBlock:^(AWEVideoStickerEditCircleView *obj, NSUInteger idx, BOOL *stop) {
        if (obj.stickerEditId == infos.stickerId) {
            obj.stickerInfos = infos;
            CGFloat stickerAngle = infos.angle * M_PI / 180.0;
            if (ACCRTL().isRTL) {
                stickerAngle = -stickerAngle;
            }
            CGRect rect = CGRectMake(0, 0, viewSize.width, viewSize.height);
            if ([AWEPinStickerUtil isValidRect:rect]) {
                obj.bounds = rect;
                obj.center = center;
                obj.transform = CGAffineTransformMakeRotation(stickerAngle);
            }
            *stop = YES;
        }
    }];
}

@end
