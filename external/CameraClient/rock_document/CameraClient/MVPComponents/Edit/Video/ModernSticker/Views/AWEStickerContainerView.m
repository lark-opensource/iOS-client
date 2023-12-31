//
//  AWEStickerContainerView.m
//  AWEStudio
//
//  Created by guochenxiang on 2018/9/25.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEStickerContainerView.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/AWEFeedBackGenerator.h>
#import <CreationKitArch/AWEStudioExcludeSelfView.h>
#import "AWEXScreenAdaptManager.h"
#import "AWEStickerContainerFakeProfileView.h"
#import "AWEEditStickerBubbleManager.h"
#import "AWEEditStickerHintView.h"
#import <CreativeKit/NSTimer+ACCAdditions.h>
#import "AWEPinStickerUtil.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreationKitInfra/ACCRTLProtocol.h>
#import <CreationKitArch/ACCRepoStickerModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import "AWERepoVideoInfoModel.h"

static BOOL kCanStickerContainerViewAngleAdsorbingVibrate = YES;

typedef NS_OPTIONS(NSUInteger, AWEStickerDirectionOptions) {
    AWEStickerDirectionNone  = 0,
    AWEStickerDirectionLeft  = 1 << 0,
    AWEStickerDirectionRight = 1 << 1,
    AWEStickerDirectionUp    = 1 << 2,
    AWEStickerDirectionDown  = 1 << 3,
};


typedef NS_ENUM(NSInteger, AWEStickerEdgeLineType) {
    AWEStickerEdgeLineNone = 0,
    AWEStickerEdgeLineLeft,
    AWEStickerEdgeLineRight,
    AWEStickerEdgeLineDown,
    AWEStickerEdgeLineCenterVertical,
    AWEStickerEdgeLineCenterHorizontal
};

static const CGFloat kAWEStickerContainerViewHintAnimationYOffset = 8.f;

@interface AWEStickerContainerView () <AWEEditorStickerGestureDelegate>

@property (nonatomic, strong, readwrite) NSMutableArray<AWEVideoStickerEditCircleView *> *stickerViews;

@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;

@property (nonatomic, strong) NSTimer *countDownTimer;

//垃圾箱
@property (nonatomic, assign) BOOL isInDeleting;
@property (nonatomic, assign) CGFloat currentPlayerTime;

@property (nonatomic, assign) CGPoint mediaCenter;

//信息化贴纸对齐
@property (nonatomic, strong) UIView *leftAlignLine;
@property (nonatomic, strong) UIView *rightAlignLine;
@property (nonatomic, strong) UIView *bottomAlignLine;
/// 垂直对齐线
@property (nonatomic, strong) UIView *centerVerticalAlignLine;
/// 水平对齐线
@property (nonatomic, strong) UIView *centerHorizontalAlignLine;
@property (nonatomic, strong) NSTimer *edgeLineTimer;
@property (nonatomic, assign) BOOL isEdgeAdsorbing;
@property (nonatomic, assign) BOOL isAngleAdsorbing;
/// 半透明个人视频页底部元素，用来警示投票贴纸的安全区域
@property (nonatomic, strong) AWEStickerContainerFakeProfileView *fakeProfileView;
// 拦截旋转操作时记录过往角度的数组
@property (nonatomic, strong) NSMutableArray<NSNumber *> *interceptedAnglesInRadian;
@property (nonatomic, assign) CGAffineTransform basedTransform;
@property (nonatomic, strong) NSNumber *lastMatchedAdsobringAngle;
@property (nonatomic, assign) float lastMatchedAngleInRadian;
@property (nonatomic, assign) float lastMatchedScale;
@property (nonatomic, strong) AWEEditStickerHintView *hintView;

// 重置操作
@property (nonatomic, assign) BOOL invalidAction;
@property (nonatomic, assign) BOOL hasBackup;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) AWEVideoStickerEditCircleView *currentAnimationView;
@property (nonatomic, assign) CGFloat resetAnimationAngle;
@property (nonatomic, assign) CGFloat resetAnimationScale;
@property (nonatomic, assign) CGFloat resetAnimationXDistance;
@property (nonatomic, assign) CGFloat resetAnimationYDistance;

@property (nonatomic, assign) CGPoint panAnchorOffset;
@property (nonatomic, assign) NSUInteger lastNumberOfTouches;

@end


@implementation AWEStickerContainerView

- (instancetype)initWithFrame:(CGRect)frame publishModel:(AWEVideoPublishViewModel *)publishModel
{
    self = [super initWithFrame:frame];
    if (self) {
        _stickerViews = [NSMutableArray array];
        _publishModel = publishModel;
        _interceptedAnglesInRadian = [NSMutableArray array];
        //对齐线
        [self addSubview:self.leftAlignLine];
        [self addSubview:self.rightAlignLine];
        [self addSubview:self.bottomAlignLine];
        [self addSubview:self.centerVerticalAlignLine];
        [self addSubview:self.centerHorizontalAlignLine];

        CGFloat wGap = 0.f;
        CGFloat hGap = 0.f;
        if (frame.size.width && frame.size.height) {
            wGap = (frame.size.width - ACC_SCREEN_WIDTH)/2;
            hGap = (frame.size.height - ACC_SCREEN_HEIGHT)/2;
        }
        
        ACCMasUpdate(self.leftAlignLine, {
            make.top.bottom.equalTo(self);
            make.width.mas_equalTo(1.5f);
            make.left.equalTo(self).offset(14.5+wGap);
        });
        ACCMasUpdate(self.rightAlignLine, {
            make.top.bottom.equalTo(self);
            make.width.mas_equalTo(1.5f);
            make.right.equalTo(self).offset(-56.f-(self.acc_width - UIScreen.mainScreen.bounds.size.width)/2.f);
        });
        ACCMasUpdate(self.bottomAlignLine, {
            make.left.right.equalTo(self);
            make.height.mas_equalTo(1.5f);
            if (@available(iOS 11.0,*)) {
                if ([AWEXScreenAdaptManager needAdaptScreen]) {
                    CGFloat offset = - ACC_IPHONE_X_BOTTOM_OFFSET - 69;
                    if ([UIDevice acc_isIPhoneXsMax]) {
                        offset = - ACC_IPHONE_X_BOTTOM_OFFSET - 80;
                    }
                    make.bottom.equalTo(self).offset(offset);
                } else {
                    make.bottom.equalTo(self).offset(-(42.5+hGap) - [[UIApplication sharedApplication].delegate window].safeAreaInsets.bottom);
                }
            }else{
                make.bottom.equalTo(self).offset(-(42.5+hGap));
            }
        });
        ACCMasMaker(self.centerHorizontalAlignLine, {
            if ([AWEXScreenAdaptManager needAdaptScreen]) {
                make.height.mas_equalTo(1.5f);
                make.left.right.equalTo(self);
                CGFloat centerY = (self.maskViewTwo.acc_bottom - self.maskViewOne.acc_top) / 2.f;
                make.centerY.mas_equalTo(centerY).priorityMedium();
            } else {
                make.height.mas_equalTo(1.5f);
                make.left.right.equalTo(self);
                make.centerY.equalTo(self);
            }
        });
        ACCMasMaker(self.centerVerticalAlignLine, {
            make.width.mas_equalTo(1.5f);
            make.centerX.equalTo(self);
            make.top.bottom.equalTo(self); // TODO: 这个地方需要确认布局
        });

        self.fakeProfileView = [[AWEStickerContainerFakeProfileView alloc] initWithNeedIgnoreRTL:YES];
        [self addSubview:self.fakeProfileView];
        self.fakeProfileView.bottomContainerView.hidden = YES;
        self.fakeProfileView.rightContainerView.hidden = YES;
        ACCMasMaker(self.fakeProfileView, {
            make.left.equalTo(self).offset((self.acc_width - UIScreen.mainScreen.bounds.size.width)/2.f);
            make.width.equalTo(@(UIScreen.mainScreen.bounds.size.width));
            make.top.equalTo(self.maskViewOne.mas_bottom);
            if ([UIDevice acc_isIPhoneX]) {
                if ([AWEXScreenAdaptManager needAdaptScreen]) {
                    if ([UIDevice acc_isIPhoneXsMax]) {
                        make.bottom.equalTo(self.maskViewTwo.mas_top).offset(-36.f - 12);
                    } else {
                        make.bottom.equalTo(self.maskViewTwo.mas_top).offset(-36.f);
                    }
                } else {
                    make.bottom.equalTo(self.maskViewTwo.mas_top).offset(-34.f);
                }
            } else {
                make.bottom.equalTo(self.maskViewTwo.mas_top);
            }
        });


        [self p_showEdgeLineWithType:AWEStickerEdgeLineNone];
    }
    return self;
}

- (void)createMaskViewWithFrame:(CGRect)frame playerFrame:(CGRect)playerFrame
{
    if ([AWEXScreenAdaptManager needAdaptScreen]) {
        //上下有黑边
        CGFloat maskTopHeight = CGRectGetMinY(playerFrame);
        CGFloat maskBottomHeight = frame.size.height - CGRectGetMaxY(playerFrame);
        
        CGFloat radius = 0.0;
        if (!ACCViewFrameOptimizeContains(ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize), ACCViewFrameOptimizeFullDisplay) &&
            ACC_FLOAT_EQUAL_TO([AWEXScreenAdaptManager standPlayerFrame].size.height, playerFrame.size.height) &&
            ACC_FLOAT_LESS_THAN([AWEXScreenAdaptManager standPlayerFrame].size.width, playerFrame.size.width)) {
            radius = 12.0;
        }
        
        self.maskViewOne = [[AWEStudioExcludeSelfView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), maskTopHeight + radius)];
        self.maskViewTwo = [[AWEStudioExcludeSelfView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(playerFrame) - radius, CGRectGetWidth(frame), maskBottomHeight + radius)];
        self.maskViewOne.backgroundColor = [UIColor blackColor];
        self.maskViewTwo.backgroundColor = [UIColor blackColor];
        
        [self makeMaskLayerForMaskViewOneWithRadius:radius];
        [self makeMaskLayerForMaskViewTwoWithRadius:radius];
        [self addSubview:self.maskViewOne];
        [self addSubview:self.maskViewTwo];
        
        if (CGRectGetWidth(playerFrame) < CGRectGetWidth(frame)) {
            //左右有黑边
            CGFloat maskWidth = (CGRectGetWidth(frame) - CGRectGetWidth(playerFrame)) * 0.5;
            self.maskViewThree = [[AWEStudioExcludeSelfView alloc] initWithFrame:CGRectMake(0, 0, maskWidth, CGRectGetHeight(frame))];
            self.maskViewFour = [[AWEStudioExcludeSelfView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(playerFrame), 0, maskWidth, CGRectGetHeight(frame))];
            self.maskViewThree.backgroundColor = [UIColor blackColor];
            self.maskViewFour.backgroundColor = [UIColor blackColor];
            [self addSubview:self.maskViewThree];
            [self addSubview:self.maskViewFour];
        }
        
        CGRect actualFrame = CGRectMake(MAX(0, CGRectGetMinX(playerFrame)), MAX(0, CGRectGetMinY(playerFrame)), MIN(CGRectGetWidth(frame),CGRectGetWidth(playerFrame)), MIN(CGRectGetHeight(frame),CGRectGetHeight(playerFrame))); AWEEditStickerBubbleManager.videoStickerBubbleManager.getParentViewActualFrameBlock = ^CGRect{
            return actualFrame;
        };
    }
}

#pragma mark - AWEEditorStickerGestureProtocol

- (void)editorSticker:(AWEVideoStickerEditCircleView *)editView receivedTapGesture:(UITapGestureRecognizer *)gesture
{
    AWEVideoStickerEditCircleView *innerEditView = editView;

    // Pin Intercept Start - 判断当前点击的坐标中是否包含被Pin住的信息化贴纸（实际在视频中被Pin住的位置）
    CGPoint point = [gesture locationInView:self];
    if ([ACCRTL() isRTL]) {
        point.x = self.frame.size.width - point.x;
    }
    if ((!innerEditView || [self.editService.sticker getStickerPinStatus:innerEditView.stickerInfos.stickerId] == VEStickerPinStatus_Pinned) &&
        [self hasAnyPinnedInfoSticker]) {
        innerEditView = [self touchPinnedStickerInVideoAndCancelPin:[NSValue valueWithCGPoint:point]];
    }

    // 未选中目标
    if (!innerEditView) {
        [self makeAllStickersResignActive];
    } else if ([self hasAnyPinnedInfoSticker]) {
        // 判断当前点击的位置对应的信息化贴纸View是不是已经被Pin住了，如果被Pin住则不响应后续
        if ([self videoStickerHasBeenPinned:innerEditView]) {
            return;
        }
    }
    
    if (![innerEditView isKindOfClass:[AWEVideoStickerEditCircleView class]]) {
        return;
    }
    
    [self makeStickerCurrent:innerEditView showHandleBar:YES];
}

- (void)editorSticker:(AWEVideoStickerEditCircleView *)editView receivedPanGesture:(UIPanGestureRecognizer *)gesture
{
    AWEVideoStickerEditCircleView *innerEditView = editView;

    if (gesture.state == UIGestureRecognizerStateEnded ||
        gesture.state == UIGestureRecognizerStateCancelled) {
        self.panAnchorOffset = CGPointZero;
        self.lastNumberOfTouches = 0;
    } else if (gesture.numberOfTouches != self.lastNumberOfTouches) {
        self.lastNumberOfTouches = gesture.numberOfTouches;
        CGPoint position = [gesture locationInView:self];
        self.panAnchorOffset = CGPointMake(editView.center.x - position.x, editView.center.y - position.y);
    }

    // Pin Intercept Start - 判断当前点击的坐标中是否包含被Pin住的信息化贴纸（实际在视频中被Pin住的位置）
    CGPoint point = [gesture locationInView:self];
    if ([ACCRTL() isRTL]) {
        point.x = self.frame.size.width - point.x;
    }
    if ((!innerEditView || [self.editService.sticker getStickerPinStatus:innerEditView.stickerInfos.stickerId] == VEStickerPinStatus_Pinned) &&
        [self hasAnyPinnedInfoSticker]) {
        innerEditView = [self touchPinnedStickerInVideoAndCancelPin:[NSValue valueWithCGPoint:point]];
    }

    if (!innerEditView || ![innerEditView isKindOfClass:[AWEVideoStickerEditCircleView class]]) {
        return;
    }
    ACCBLOCK_INVOKE(self.startPanGestureBlock);

    {//对齐线逻辑
        CGPoint currentPoint = [gesture translationInView:self];
        CGPoint position =  [gesture locationInView:editView.superview];
        position.x += self.panAnchorOffset.x;
        position.y += self.panAnchorOffset.y;
        {
            CGSize scaleSize = CGSizeMake((innerEditView.bounds.size.width-6)*innerEditView.stickerInfos.scale, (innerEditView.bounds.size.height-6)*innerEditView.stickerInfos.scale);
            CGFloat radius = atan2f(innerEditView.transform.b, innerEditView.transform.a);
            CGFloat true_h = fabs(scaleSize.width * sin(fabs(radius))) + fabs(scaleSize.height * cos(fabs(radius)));
            CGFloat true_w = fabs(scaleSize.width * cos(fabs(radius))) + fabs(scaleSize.height * sin(fabs(radius)));
            CGPoint newCenter = position;
            //set direction
            AWEStickerDirectionOptions direction = [self p_getDirectionWithTranslation:currentPoint];

            if (gesture.state == UIGestureRecognizerStateBegan) {//旋转后恢复可拖动状态
                [self p_resetAdsorbingWithEditView:innerEditView width:true_w height:true_h];
            }
            
            //set limit edge
            CGFloat edgesShift = 0.5f;
            CGFloat continueMoveShift = 5.f;
            CGFloat sensitivity = 0.5f;
            /** ============ 水平居中 && 垂直居中的处理 BEGIN ========== */
            if (direction & AWEStickerDirectionLeft || direction & AWEStickerDirectionRight) {
                // center vertical
                BOOL centerXWhenDirectionLeft = (direction & AWEStickerDirectionLeft) &&
                ACC_FLOAT_GREATER_THAN(innerEditView.acc_centerX, self.centerVerticalAlignLine.acc_centerX) &&
                ACC_FLOAT_LESS_THAN(newCenter.x, self.centerVerticalAlignLine.acc_centerX);

                BOOL centerXWhenDirectionRight = (direction & AWEStickerDirectionRight) &&
                ACC_FLOAT_LESS_THAN(innerEditView.acc_centerX, self.centerVerticalAlignLine.acc_centerX) &&
                ACC_FLOAT_GREATER_THAN(newCenter.x, self.centerVerticalAlignLine.acc_centerX);
                if (centerXWhenDirectionLeft || centerXWhenDirectionRight) {
                    newCenter.x = self.centerVerticalAlignLine.acc_centerX;
                }

                if (self.isEdgeAdsorbing) {
                    if (fabs(innerEditView.acc_centerX - self.centerVerticalAlignLine.acc_centerX) <= 0.01) {
                        // 垂直线吸附后继续左右移动的条件
                        if (currentPoint.x > continueMoveShift) {
                            // 向右移动
                            self.isEdgeAdsorbing = NO;
                            newCenter.x = self.centerVerticalAlignLine.acc_centerX + edgesShift;
                        } else if (currentPoint.x < -continueMoveShift) {
                            // 向左移动
                            self.isEdgeAdsorbing = NO;
                            newCenter.x = self.centerHorizontalAlignLine.acc_centerX - edgesShift;
                        }
                    } else {
                        // 水平线吸附后继续左右移动的条件
                        if (fabs(innerEditView.acc_centerY - self.centerHorizontalAlignLine.acc_centerY) <= 0.01) {
                            if (fabs(currentPoint.x) > sensitivity) {//灵敏度
                                newCenter.y = self.centerHorizontalAlignLine.acc_centerY;
                                [self p_updateTranslationWithGesture:gesture view:innerEditView center:newCenter direction:direction];
                            }
                        }
                    }
                }
            }
            if (direction & AWEStickerDirectionUp || direction & AWEStickerDirectionDown) {
                // center horizontal
                BOOL centerYWhenDirectionUp = (direction & AWEStickerDirectionUp) &&

                ACC_FLOAT_GREATER_THAN(innerEditView.acc_centerY, self.centerHorizontalAlignLine.acc_centerY) &&
                ACC_FLOAT_LESS_THAN(newCenter.y, self.centerHorizontalAlignLine.acc_centerY);

                BOOL centerYWhenDirectionDown = (direction & AWEStickerDirectionDown) &&
                ACC_FLOAT_LESS_THAN(innerEditView.acc_centerY, self.centerHorizontalAlignLine.acc_centerY) &&
                ACC_FLOAT_GREATER_THAN(newCenter.y, self.centerHorizontalAlignLine.acc_centerY);
                if (centerYWhenDirectionUp || centerYWhenDirectionDown) {
                    newCenter.y = self.centerHorizontalAlignLine.acc_centerY;
                }

                if (self.isEdgeAdsorbing) {
                    if (fabs(innerEditView.acc_centerY - self.centerHorizontalAlignLine.acc_centerY) <= 0.01) {
                        // 水平线吸附后继续上下移动的条件
                        if (currentPoint.y > continueMoveShift) {
                            // 向下移动
                            self.isEdgeAdsorbing = NO;
                            newCenter.y = self.centerHorizontalAlignLine.acc_centerY + edgesShift;
                        } else if (currentPoint.y < -continueMoveShift) {
                            // 向上移动
                            self.isEdgeAdsorbing = NO;
                            newCenter.y = self.centerHorizontalAlignLine.acc_centerY - edgesShift;
                        }
                    } else {
                        // 垂直线吸附后继续上下移动的条件
                        if (fabs(innerEditView.acc_centerX - self.centerVerticalAlignLine.acc_centerX) <= 0.01) {
                            if (fabs(currentPoint.y) > sensitivity) {//灵敏度
                                newCenter.x = self.centerVerticalAlignLine.acc_centerX;
                                [self p_updateTranslationWithGesture:gesture view:innerEditView center:newCenter direction:direction];
                            }
                        }
                    }
                }
            }
            /** ============ 水平居中 && 垂直居中的处理 END ========== */
            if (direction & AWEStickerDirectionLeft) {
                if (self.isEdgeAdsorbing) {
                    if (!ACC_FLOAT_EQUAL_TO(innerEditView.center.x,self.leftAlignLine.acc_right + true_w/2)) {
                        if (ACC_FLOAT_EQUAL_TO(innerEditView.center.x,self.rightAlignLine.acc_left - true_w/2)) {
                            self.isEdgeAdsorbing = NO;//触右边线后往左移
                        } else if (ACC_FLOAT_EQUAL_TO(innerEditView.center.y,self.bottomAlignLine.acc_top - true_h/2)) {//触底后可以左右移动
                            if (fabs(currentPoint.x) > sensitivity) {//灵敏度
                                newCenter.y = self.bottomAlignLine.acc_top - true_h/2;
                                [self p_updateTranslationWithGesture:gesture view:innerEditView center:newCenter direction:direction];
                            }
                        }
                    }
                }
            }
            if (direction & AWEStickerDirectionRight) {
                if (self.isEdgeAdsorbing) {
                    if (!ACC_FLOAT_EQUAL_TO(innerEditView.center.x,self.rightAlignLine.acc_left - true_w/2)) {//触右边线后还能再往右移的条件
                        if (ACC_FLOAT_EQUAL_TO(innerEditView.center.x,self.leftAlignLine.acc_right + true_w/2)) {
                            self.isEdgeAdsorbing = NO;//触左边线后往右移
                        } else if (ACC_FLOAT_EQUAL_TO(innerEditView.center.y,self.bottomAlignLine.acc_top - true_h/2)) {//触底后可以左右移动
                            if (fabs(currentPoint.x) > sensitivity) {//灵敏度
                                newCenter.y = self.bottomAlignLine.acc_top - true_h/2;
                                [self p_updateTranslationWithGesture:gesture view:innerEditView center:newCenter direction:direction];
                            }
                        }
                    }
                }
            }
            if (direction & AWEStickerDirectionDown) {
                if (self.isEdgeAdsorbing) {
                    if (ACC_FLOAT_EQUAL_TO(innerEditView.center.y,self.bottomAlignLine.acc_top - true_h/2)) {//触底边线后还能再往下移的条件
                        if (currentPoint.y > continueMoveShift) {
                            self.isEdgeAdsorbing = NO;
                            newCenter.y = self.bottomAlignLine.acc_top - true_h/2 + edgesShift;
                        }
                    } else {//触两边后还可以上下滑动
                        if (fabs(currentPoint.y) > sensitivity) {//灵敏度
                            BOOL canMoveDown = NO;
                            if (ACC_FLOAT_EQUAL_TO(innerEditView.center.x,self.leftAlignLine.acc_right + true_w/2)) {
                                newCenter.x = self.leftAlignLine.acc_right + true_w/2;
                                canMoveDown = YES;
                            }
                            if (ACC_FLOAT_EQUAL_TO(innerEditView.center.x,self.rightAlignLine.acc_left - true_w/2)) {
                                newCenter.x = self.rightAlignLine.acc_left - true_w/2;
                                canMoveDown = YES;
                            }
                            if (canMoveDown) {
                                [self p_updateTranslationWithGesture:gesture view:innerEditView center:newCenter direction:direction];
                            }
                        }
                    }
                }
            }
            if (direction & AWEStickerDirectionUp) {
                if (self.isEdgeAdsorbing) {
                    if (ACC_FLOAT_EQUAL_TO(innerEditView.center.y,self.bottomAlignLine.acc_top - true_h/2)) {//触底边线后往上移动
                        self.isEdgeAdsorbing = NO;
                    } else {//触两边后还可以上下滑动
                        if (fabs(currentPoint.y) > sensitivity) {//灵敏度
                            BOOL canMoveUP = NO;
                            if (ACC_FLOAT_EQUAL_TO(innerEditView.center.x,self.leftAlignLine.acc_right + true_w/2)) {
                                newCenter.x = self.leftAlignLine.acc_right + true_w/2;
                                canMoveUP = YES;
                            }
                            if (ACC_FLOAT_EQUAL_TO(innerEditView.center.x,self.rightAlignLine.acc_left - true_w/2)) {
                                newCenter.x = self.rightAlignLine.acc_left - true_w/2;
                                canMoveUP = YES;
                            }
                            if (canMoveUP) {
                                [self p_updateTranslationWithGesture:gesture view:innerEditView center:newCenter direction:direction];
                            }
                        }
                    }
                }
            }
            
            // 移动的状态先控制右边和下面的边界UI提示，并且需要边界线不展示
            if (gesture.state == UIGestureRecognizerStateChanged) {
                if (newCenter.x + true_w / 2.f >= self.rightAlignLine.acc_left) {
                    self.fakeProfileView.rightContainerView.hidden = NO;
                } else {
                    self.fakeProfileView.rightContainerView.hidden = YES;
                }

                if (ACCConfigInt(kConfigInt_editor_toolbar_optimize) == ACCStoryEditorOptimizeTypeNone) {
                    if (newCenter.y + true_h / 2.f >= self.bottomAlignLine.acc_top) {
                        self.fakeProfileView.bottomContainerView.hidden = NO;
                    } else {
                        self.fakeProfileView.bottomContainerView.hidden = YES;
                    }
                } else {
                    if (newCenter.y + true_h / 2.f >= self.fakeProfileView.bottomContainerView.acc_top + [self.fakeProfileView bottomContainerTopMargin]) {
                        self.fakeProfileView.bottomContainerView.hidden = NO;
                    } else {
                        self.fakeProfileView.bottomContainerView.hidden = YES;
                    }
                }
                
                CGRect invalidFrame = [self.publishModel.repoSticker.gestureInvalidFrameValue CGRectValue];
                if (!CGRectIsEmpty(invalidFrame) && CGRectIntersectsRect(invalidFrame, innerEditView.frame)) {
                    self.invalidAction = YES;
                } else {
                    self.invalidAction = NO;
                }
            }

            if (gesture.state == UIGestureRecognizerStateChanged && !self.isEdgeAdsorbing) {
                [self p_updateTranslationWithGesture:gesture view:innerEditView center:newCenter direction:direction];
                [self p_checkAdsorbingWithEditView:innerEditView width:true_w height:true_h direction:direction];
            }
        }
    }
    
    //是不是拖到了顶部删除按钮区域
    BOOL needDelete = [self deleteActionForStickerEditCircleView:innerEditView didReceivePanGesture:gesture];
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self gestureBeginWithStickerView:innerEditView];
        [self trackEvent:@"prop_adjust" params:@{
                                                 @"enter_from" : @"video_edit_page",
                                                 @"prop_id" : innerEditView.stickerInfos.userInfo[@"stickerID"] ? : @"",
                                                 @"enter_method" : @"finger_gesture"
                                                 }];
    } else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        if (needDelete && [self.delegate respondsToSelector:@selector(removeSticker:)]) {
            [self trackEvent:@"prop_delete" params:@{
                                                     @"enter_from" : self.publishModel.repoTrack.enterFrom ?: @"",
                                                     @"prop_id" : innerEditView.stickerInfos.userInfo[@"stickerID"] ? : @"",
                                                     }];
            [self.delegate removeSticker:innerEditView.stickerInfos.stickerId];
            [self.stickerViews removeObject:innerEditView];
            [innerEditView removeFromSuperview];
            self.currentStickerView = nil;
            self.invalidAction = NO;
            self.isInDeleting = NO;
        } else if (!needDelete && self.invalidAction) {
            if ([self.delegate respondsToSelector:@selector(setSticker:alpha:)]) {
                [self.delegate setSticker:innerEditView.stickerEditId alpha:1.0];
            }
            [self p_resetTranslationWithView:innerEditView];
        }
        
        [self gestureEndWithStickerView:innerEditView];
    }
}

- (void)editorSticker:(AWEVideoStickerEditCircleView *)editView receivedPinchGesture:(UIPinchGestureRecognizer *)pinch
{
    AWEVideoStickerEditCircleView *innerEditView = editView;

    // Pin Intercept Start - 判断当前点击的坐标中是否包含被Pin住的信息化贴纸（实际在视频中被Pin住的位置）
    CGPoint point = [pinch locationInView:self];
    if ([ACCRTL() isRTL]) {
        point.x = self.frame.size.width - point.x;
    }
    if ((!innerEditView || [self.editService.sticker getStickerPinStatus:innerEditView.stickerInfos.stickerId] == VEStickerPinStatus_Pinned) &&
        [self hasAnyPinnedInfoSticker]) {
        innerEditView = [self touchPinnedStickerInVideoAndCancelPin:[NSValue valueWithCGPoint:point]];
    }

    if (innerEditView && ![innerEditView isKindOfClass:[AWEVideoStickerEditCircleView class]]) {
        return;
    }
    
    if (pinch.state == UIGestureRecognizerStateBegan) {
        [self gestureBeginWithStickerView:innerEditView];
        
        [self trackEvent:@"prop_adjust" params:@{
                                                 @"enter_from" : @"video_edit_page",
                                                 @"prop_id" : self.currentStickerView.stickerInfos.userInfo[@"stickerID"] ? : @"",
                                                 @"enter_method" : @"finger_gesture"
                                                 }];
    } else if (pinch.state == UIGestureRecognizerStateChanged) {
        CGFloat scale = pinch.scale;
        CGRect bounds = self.currentStickerView.bounds;
        CGRect newBounds = CGRectMake(0, 0, bounds.size.width * scale, bounds.size.height * scale);
        CGFloat minLenght = 22.f;//kVideoStickerEditCircleViewEdgeInset
        if (newBounds.size.width <= minLenght || newBounds.size.height <= minLenght) {
            return;
        }
        if ([self.currentStickerView setBounds:newBounds scale:scale] &&
            [self.delegate respondsToSelector:@selector(setSticker:offsetX:offsetY:angle:scale:)]) {
            CGFloat stickerAngle = self.currentStickerView.stickerInfos.angle;
            if (ACCRTL().isRTL) {
                stickerAngle = -stickerAngle;
            }
            [self setSticker:self.currentStickerView.stickerEditId
                     offsetX:self.currentStickerView.stickerInfos.offsetX
                     offsetY:self.currentStickerView.stickerInfos.offsetY
                       angle:stickerAngle
                       scale:scale];
        }
        [pinch setScale:1.f];

        [self refreshFakeProfileViewHiddenWithEditedView:innerEditView];
        [self fixCurrentStickerAndViewScaleDiff];

    } else if (pinch.state == UIGestureRecognizerStateEnded ||
               pinch.state == UIGestureRecognizerStateCancelled) {
        [self gestureEndWithStickerView:self.currentStickerView];
    }
    
}

- (void)editorSticker:(AWEVideoStickerEditCircleView *)editView receivedRotationGesture:(UIRotationGestureRecognizer *)rotation
{
    AWEVideoStickerEditCircleView *innerEditView = editView;

    // Pin Intercept Start - 判断当前点击的坐标中是否包含被Pin住的信息化贴纸（实际在视频中被Pin住的位置）
    CGPoint point = [rotation locationInView:self];
    if ([ACCRTL() isRTL]) {
        point.x = self.frame.size.width - point.x;
    }
    if ((!innerEditView || [self.editService.sticker getStickerPinStatus:innerEditView.stickerInfos.stickerId] == VEStickerPinStatus_Pinned) &&
        [self hasAnyPinnedInfoSticker]) {
        innerEditView = [self touchPinnedStickerInVideoAndCancelPin:[NSValue valueWithCGPoint:point]];
    }

    if (innerEditView && ![innerEditView isKindOfClass:[AWEVideoStickerEditCircleView class]]) {
        return;
    }

    if (rotation.state == UIGestureRecognizerStateBegan) {
        [self gestureBeginWithStickerView:innerEditView];
        self.basedTransform = innerEditView.transform;
        [self trackEvent:@"prop_adjust" params:@{
                                                 @"enter_from" : @"video_edit_page",
                                                 @"prop_id" : innerEditView.stickerInfos.userInfo[@"stickerID"] ? : @"",
                                                 @"enter_method" : @"finger_gesture"
                                                 }];
    } else if (rotation.state == UIGestureRecognizerStateChanged) {
        CGFloat angle = innerEditView.stickerInfos.angle / 180 * M_PI + rotation.rotation;
        [self interceptToAngleAdSorbingWith:rotation angleInRadians:angle scale:1 editedView:innerEditView];
        if (!_isAngleAdsorbing) {
            if ([self.delegate respondsToSelector:@selector(setSticker:offsetX:offsetY:angle:scale:)]) {
                CGFloat stickerAngle = angle * 180.0 / M_PI;
                if (ACCRTL().isRTL) {
                    stickerAngle = -stickerAngle;
                }
                [self setSticker:innerEditView.stickerInfos.stickerId
                         offsetX:innerEditView.stickerInfos.offsetX
                         offsetY:innerEditView.stickerInfos.offsetY
                           angle:stickerAngle
                           scale:1];
            }
            innerEditView.stickerInfos.angle = angle * 180.0 / M_PI;
            rotation.rotation = 0;
            [innerEditView setTransform:CGAffineTransformRotate(self.basedTransform, angle)];
            [self fixViewAndStickerDiff:innerEditView];
            [self fixCurrentStickerAndViewScaleDiff];
        }

        [self refreshFakeProfileViewHiddenWithEditedView:innerEditView];

    } else if (rotation.state == UIGestureRecognizerStateEnded ||
               rotation.state == UIGestureRecognizerStateCancelled) {
        [self gestureEndWithStickerView:innerEditView];
    }
}

- (void)editorStickerGestureStarted
{
    [self makeAllStickersResignActive];
}

#pragma mark - AWEEditorStickerGestureDelegate

- (void)editorSticker:(AWEVideoStickerEditCircleView *)editView clickedDeleteButton:(UIButton *)sender
{
    [self trackEvent:@"prop_delete" params:@{
                                             @"enter_from" : self.publishModel.repoTrack.enterFrom ?: @"",
                                             @"prop_id" : editView.stickerInfos.userInfo[@"stickerID"] ? : @"",
                                             }];
    [self.stickerViews removeObject:editView];
    [editView removeFromSuperview];
    
    if ([self.delegate respondsToSelector:@selector(removeSticker:)]) {
        [self.delegate removeSticker:editView.stickerEditId];
    }
    
    editView = nil;
    kCanStickerContainerViewAngleAdsorbingVibrate = YES;
    self.currentStickerView = nil;
}

- (void)editorSticker:(AWEVideoStickerEditCircleView *)editView clickedSelectTimeButton:(UIButton *)sender
{
    [editView hideAngleHelperDashLine];
    [self trackEvent:@"prop_time_set" params:@{
                                               @"enter_from" : @"video_edit_page",
                                               @"prop_id" : editView.stickerInfos.userInfo[@"stickerID"] ? : @"",
                                               @"enter_method" : @"click",
                                               @"is_diy_prop" : @(editView.isCustomUploadSticker)
                                               }];
    [self cancelStickerViewVaildDuration:editView];
    if (self.delegate && [self.delegate respondsToSelector:@selector(selectTimeForStickerView:)]) {
        [self.delegate selectTimeForStickerView:editView];
    }
    self.currentStickerView = nil;
}

- (void)editorSticker:(UIView *)editView clickedPinStickerButton:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(pinSticker:)] && [editView isKindOfClass:[AWEVideoStickerEditCircleView class]]) {
        [self.delegate pinSticker:(AWEVideoStickerEditCircleView *)editView];
    }
}

#pragma mark - Count Down Timer

- (void)startCountDownTimer
{
    [self invalidateCountDownTimer];
    self.countDownTimer = [NSTimer timerWithTimeInterval:3 target:self selector:@selector(deselectCurrentSticker) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:self.countDownTimer forMode:NSRunLoopCommonModes];
}

- (void)invalidateCountDownTimer
{
    [self.countDownTimer invalidate];
    self.countDownTimer = nil;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark - Gesture Helpers

- (void)makeStickerCurrent:(AWEVideoStickerEditCircleView *)stickerView showHandleBar:(BOOL)show
{
    if (!stickerView) {
        return;
    }
    //歌词贴纸不弹编辑框
    if (stickerView.isLyricSticker && show) {
        [self bringSubviewToFront:stickerView];
        [self makeAllStickersResignActive];
        [self makeStickerViewVaildDuration:stickerView];
        self.currentStickerView = stickerView;
        if ([self.delegate respondsToSelector:@selector(activeSticker:)]) {
            [self.delegate activeSticker:stickerView.stickerEditId];
        }
        return;
    }
    
    if ([stickerView isEqual:self.currentStickerView] || stickerView.isActive) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(activeSticker:)] && ![self.delegate activeSticker:stickerView.stickerEditId]) {
        return;
    }
    
    [self.stickerViews removeObject:stickerView];
    [self.stickerViews addObject:stickerView];
    [self bringSubviewToFront:stickerView];
    [self makeAllStickersResignActive];
    [self makeStickerViewVaildDuration:stickerView];
    self.currentStickerView = stickerView;
    
    if (show) {
        [self trackEvent:@"prop_more_click" params:@{
            @"enter_from" : @"video_edit_page",
            @"is_diy_prop": @(stickerView.isCustomUploadSticker)
        }];
        [stickerView becomeActive];
        [self startCountDownTimer];
    }
}

- (void)gestureBeginWithStickerView:(AWEVideoStickerEditCircleView *)stickerView
{
    self.invalidAction = NO;
    self.currentStickerView = stickerView;
    [self makeStickerCurrent:stickerView showHandleBar:NO];
    [self invalidateCountDownTimer];
    [stickerView backupActive];
    if (!self.hasBackup) {
        self.hasBackup = YES;
        [stickerView backupLocationInfo];
    }
    
    // 设计要求操作贴纸时弹窗直接消失无须动画
    [[AWEEditStickerBubbleManager videoStickerBubbleManager] setBubbleVisible:NO animated:NO];

    // UE需求，针对歌词贴纸提示框要立即消失
    [self dismissHintTextWithAnimation:!stickerView.isLyricSticker];

    if ([self.delegate respondsToSelector:@selector(handleStickerStarted:)]) {
        [self.delegate handleStickerStarted:stickerView.stickerEditId];
    }
}

- (void)gestureEndWithStickerView:(AWEVideoStickerEditCircleView *)stickerView
{
    [self.interceptedAnglesInRadian removeAllObjects];
    [self p_showEdgeLineWithType:AWEStickerEdgeLineNone];

    self.fakeProfileView.bottomContainerView.hidden = YES;
    self.fakeProfileView.rightContainerView.hidden = YES;
    self.hasBackup = NO;

    if ([self.delegate respondsToSelector:@selector(handleStickerFinished:)]) {
        [self.delegate handleStickerFinished:stickerView.stickerEditId];
    }
    
    if (!stickerView) {
        return;
    }
    
    // 修复手势各种混杂操作引发的异常问题
    ACCBLOCK_INVOKE(self.finishPanGestureBlock);
    
    [self cancelStickerViewVaildDuration:stickerView];
    
    if ([self.delegate respondsToSelector:@selector(getSticker:props:)]) {
        IESInfoStickerProps *stickerInfos = [[IESInfoStickerProps alloc] init];
        [self.delegate getSticker:stickerView.stickerEditId props:stickerInfos];
        
        CGFloat videoDuration = self.publishModel.repoVideoInfo.video.totalVideoDuration;
        if (stickerInfos.duration < 0 || stickerInfos.duration > videoDuration) {
            stickerInfos.duration = videoDuration;
        }
        stickerView.stickerInfos = stickerInfos;
        if (ACCRTL().isRTL) {
            stickerView.stickerInfos.angle = -stickerInfos.angle;
        }
    }
    
    [self fixViewAndStickerDiff:stickerView];
    [self deselectCurrentSticker];
    self.isAngleAdsorbing = NO;
    [stickerView hideAngleHelperDashLine];
}


/**
 修正旋转过后，绘制出的sticker和sticker依附的circleView角度有偏差的问题，
 这里以sticker看齐，让view靠齐sticker
 @param stickerView 被操作的stickerView
 */
- (void)fixViewAndStickerDiff:(AWEVideoStickerEditCircleView *)stickerView {
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
        [self setSticker:stickerView.stickerEditId
                 offsetX:stickerView.stickerInfos.offsetX
                 offsetY:stickerView.stickerInfos.offsetY
                   angle:angle
                   scale:1];
        
    }
}

/**
 修复放大过后，绘制出的sticker的大小和borderView有偏差的问题，
 导致拦截贴纸最小状态时可以无限缩小，因为拦截是通过borderView所在view的bounds.size来决定的
 */
- (void)fixCurrentStickerAndViewScaleDiff {
    [self fixStickerAndViewScaleDiffWithStickerView:self.currentStickerView];
}

- (void)fixStickerAndViewScaleDiffWithStickerView:(AWEVideoStickerEditCircleView *)stickerView {
    if (self.stickerSizeBlock) {
        NSDictionary *dic = self.stickerSizeBlock(stickerView.stickerInfos.stickerId);
        if (!dic[@"size"] || !dic[@"center"]) {
            return;
        }
        CGSize size = [dic[@"size"] CGSizeValue];
        CGPoint center = [dic[@"center"] CGPointValue];
        [self updateStickerWithStickerInfos:stickerView.stickerInfos editSize:size center:center];
    }
}

// 设置贴纸始终显示（编辑状态）
- (void)makeStickerViewVaildDuration:(AWEVideoStickerEditCircleView *)stickerView
{
    if ([self.delegate respondsToSelector:@selector(setSticker:startTime:duration:)]) {
        // duration < 0，表示设置为始终有效，fix时间不精确引起的闪屏问题
        [self.delegate setSticker:stickerView.stickerEditId startTime:0 duration:-1];
    }
}

// 设置贴纸为选定时间内显示
- (void)cancelStickerViewVaildDuration:(AWEVideoStickerEditCircleView *)stickerView
{
    if (stickerView && [self.delegate respondsToSelector:@selector(setSticker:startTime:duration:)]) {
        [self.delegate setSticker:stickerView.stickerEditId startTime:stickerView.realStartTime duration:stickerView.realDuration];
    }
}
#pragma mark - Hint
- (void)showHintTextOnStickerView:(AWEVideoStickerEditCircleView *)stickerView {
    if (!self.hintView.superview) {
        [self addSubview:self.hintView];
    }
    [self.hintView showHint:ACCLocalizedString(@"creation_edit_sticker_tap", @"单击可进行更多操作") type:AWEEditStickerHintTypeInfo];
    CGSize size = [self.hintView intrinsicContentSize];
    ACCMasReMaker(self.hintView, {
        make.size.equalTo(@(size));
        make.centerX.equalTo(stickerView.borderView);
        make.bottom.equalTo(stickerView.borderView.mas_top);
    });
}

- (void)checkLyricStickerViewHintShow
{
    @weakify(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @strongify(self);
        [self.stickerViews enumerateObjectsUsingBlock:^(AWEVideoStickerEditCircleView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            @strongify(self);
            if (obj.isLyricSticker) {
                [self updateLyricStickerInfoPositionAndSize];
                if (!self.hintView.superview) {
                    [self addSubview:self.hintView];
                }
                [self.hintView showHint:ACCLocalizedString(@"creation_edit_sticker_lyrics_stciker_tap", @"点击更换样式") animated:NO autoDismiss:NO];

                CGRect frame = CGRectZero;
                CGSize size = [self.hintView intrinsicContentSize];
                frame.origin.x = obj.frame.origin.x;
                frame.origin.y = obj.frame.origin.y - [AWEVideoStickerEditCircleView linePadding] - size.height + kAWEStickerContainerViewHintAnimationYOffset;
                frame.size = size;
                self.hintView.frame = frame;
                ACCMasReMaker(self.hintView, {
                    make.size.equalTo(@(size));
                    make.left.equalTo(@(frame.origin.x));
                    make.top.equalTo(@(frame.origin.y));
                });
                [self.hintView.superview setNeedsLayout];
                [self.hintView.superview layoutIfNeeded];

                self.hintView.alpha = 0.f;
                [UIView animateWithDuration:0.3 animations:^{
                    self.hintView.alpha = 1.f;
                    ACCMasUpdate(self.hintView, {
                        make.top.equalTo(@(frame.origin.y - kAWEStickerContainerViewHintAnimationYOffset));
                    });
                    [self.hintView.superview setNeedsLayout];
                    [self.hintView.superview layoutIfNeeded];
                } completion:^(BOOL finished) {
                    [self performSelector:@selector(p_dismissHintView) withObject:nil afterDelay:3.f];
                }];
                
                *stop = YES;
            }
        }];
    });
}

- (void)dismissHintTextWithAnimation:(BOOL)animated {
    [self.hintView dismissWithAnimation:animated];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(p_dismissHintView) object:nil];
}

- (void)p_dismissHintView
{
    [UIView animateWithDuration:0.3 animations:^{
        self.hintView.alpha = 0.f;
        self.hintView.frame = CGRectOffset(self.hintView.frame, 0, kAWEStickerContainerViewHintAnimationYOffset);
    } completion:^(BOOL finished) {
        [self.hintView dismissWithAnimation:NO];
    }];
}

#pragma mark - public

// 取消当前选中
- (void)deselectCurrentSticker
{
    [self makeAllStickersResignActive];
}

// 取消所有选中
- (void)makeAllStickersResignActive
{
    [self cancelStickerViewVaildDuration:self.currentStickerView];
    [self invalidateCountDownTimer];
    
    for (AWEVideoStickerEditCircleView *view in self.stickerViews) {
        [view resignActive];
    }
    self.currentStickerView = nil;
}

- (BOOL)hasEditingSticker
{
    return (self.currentStickerView != nil);
}

- (NSInteger)stickersCount
{
    return self.stickerViews.count;
}

- (NSArray *)stickerEditIds
{
    __block NSMutableArray *editIds = [NSMutableArray array];
    [self.stickerViews enumerateObjectsUsingBlock:^(AWEVideoStickerEditCircleView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj) {
            [editIds addObject:@(obj.stickerEditId)];
        }
    }];
    
    return [editIds copy];
}

// 添加贴纸
- (AWEVideoStickerEditCircleView *)addStickerWithStickerInfos:(IESInfoStickerProps *)infos isLyricSticker:(BOOL)isLyricSticker editSize:(CGSize)size center:(CGPoint)center
{
    BOOL isImage = self.publishModel.repoContext.videoType == AWEVideoTypeStoryPicture ? YES : NO;
    AWEVideoStickerEditCircleView *stickerCircleView = [[AWEVideoStickerEditCircleView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height) isForImage:isImage];
    stickerCircleView.delegate = self;
    stickerCircleView.originalSize = size;
    stickerCircleView.stickerInfos = infos;
    stickerCircleView.center = center;
    stickerCircleView.gestureManager = self.gestureManager;
    stickerCircleView.isLyricSticker = isLyricSticker;
    [stickerCircleView hideAngleHelperDashLine];
    self.mediaCenter = center;
    [self.stickerViews addObject:stickerCircleView];
    [self addSubview:stickerCircleView];
    [self makeStickerCurrent:stickerCircleView showHandleBar:NO];
    if (!isLyricSticker) {
        [self showHintTextOnStickerView:stickerCircleView];
    }
    self.currentStickerView = nil;
    return stickerCircleView;
}

// 草稿箱恢复贴纸
- (void)recoverStickerWithStickerInfos:(IESInfoStickerProps *)infos isLyricSticker:(BOOL)isLyricSticker editSize:(CGSize)size center:(CGPoint)center
{
    if (isnan(infos.offsetX)) {
        infos.offsetX = 0;
    }
    if (isnan(infos.offsetY)) {
        infos.offsetY = 0;
    }
    
    AWEVideoStickerEditCircleView *stickerCircleView = [[AWEVideoStickerEditCircleView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height) isForImage:NO];
    stickerCircleView.delegate = self;
    stickerCircleView.originalSize = size;
    stickerCircleView.stickerInfos = infos;
    stickerCircleView.isLyricSticker = isLyricSticker;
    
    CGFloat offsetX = infos.offsetX;
    CGFloat stickerAngle = infos.angle * M_PI / 180.0;
    if (ACCRTL().isRTL) {
        offsetX = -offsetX;
        stickerAngle = -stickerAngle;
    }
    stickerCircleView.center = CGPointMake(center.x + offsetX, center.y - infos.offsetY);
    stickerCircleView.transform = CGAffineTransformMakeRotation(stickerAngle);
    self.mediaCenter = center;
    [self.stickerViews addObject:stickerCircleView];
    [self addSubview:stickerCircleView];
}

// 更新贴纸框
- (void)updateStickerWithStickerInfos:(IESInfoStickerProps *)infos editSize:(CGSize)size center:(CGPoint)center
{
    if (isnan(infos.offsetX)) {
        infos.offsetX = 0;
    }
    if (isnan(infos.offsetY)) {
        infos.offsetY = 0;
    }
    
    [self.stickerViews enumerateObjectsUsingBlock:^(AWEVideoStickerEditCircleView *obj, NSUInteger idx, BOOL *stop) {
        if (obj.stickerEditId == infos.stickerId) {
            obj.originalSize = size;
            obj.stickerInfos = infos;
            CGFloat offsetX = infos.offsetX;
            CGFloat stickerAngle = infos.angle * M_PI / 180.0;
            if (ACCRTL().isRTL) {
                offsetX = -offsetX;
                stickerAngle = -stickerAngle;
            }
            CGRect rect = CGRectMake(obj.bounds.origin.x, obj.bounds.origin.y, size.width, size.height);
            if ([AWEPinStickerUtil isValidRect:rect]) {
                [obj setBounds:rect scale:infos.scale];
                obj.center = CGPointMake(center.x + offsetX, center.y - infos.offsetY);
                obj.transform = CGAffineTransformMakeRotation(stickerAngle);
            }
            *stop = YES;
        }
    }];
}

- (void)handleStickerIdChangedFrom:(NSInteger)oldStikcerId newStickerId:(NSInteger)newStickerId
{
    [self.stickerViews enumerateObjectsUsingBlock:^(AWEVideoStickerEditCircleView *obj, NSUInteger idx, BOOL *stop) {
        if (obj.stickerInfos.stickerId == oldStikcerId) {
            obj.stickerInfos.stickerId = newStickerId;
            *stop = YES;
        }
    }];
}

- (void)removeStickerWithStickerId:(NSInteger)stickerId
{
    __block AWEVideoStickerEditCircleView *circleView;
    [self.stickerViews enumerateObjectsUsingBlock:^(AWEVideoStickerEditCircleView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.stickerInfos.stickerId == stickerId) {
            circleView = obj;
            *stop = YES;
        }
    }];
    if (circleView) {
        [self.stickerViews removeObject:circleView];
        [circleView removeFromSuperview];
    }
}

- (void)updateStickerCircleViewsStatusWithCurrentPlayerTime:(CGFloat)currentPlayerTime editService:(id<ACCEditServiceProtocol>)editService
{
    self.currentPlayerTime = currentPlayerTime;
    for (AWEVideoStickerEditCircleView *stickerCircleView in self.stickerViews) {
        IESInfoStickerProps *stickerInfos = [[IESInfoStickerProps alloc] init];
        [editService.sticker getStickerId:stickerCircleView.stickerInfos.stickerId props:stickerInfos];
        
        if(self.publishModel.repoVideoInfo.video.effect_timeMachineType == HTSPlayerTimeMachineReverse) {
            currentPlayerTime = [self.publishModel.repoVideoInfo.video totalVideoDuration] - currentPlayerTime;
        }

        if (stickerCircleView.hidden && ACC_FLOAT_GREATER_THAN(currentPlayerTime, stickerInfos.startTime) && ACC_FLOAT_LESS_THAN(currentPlayerTime, stickerInfos.startTime + stickerInfos.duration)) {
            stickerCircleView.hidden = NO;
        }
        
        if (!stickerCircleView.hidden && (ACC_FLOAT_GREATER_THAN(currentPlayerTime, stickerInfos.startTime + stickerInfos.duration) || ACC_FLOAT_LESS_THAN(currentPlayerTime, stickerInfos.startTime))) {
            stickerCircleView.hidden = YES;
        }
    }
}

- (void)updateLyricStickerInfoPositionAndSize
{
    [self.stickerViews enumerateObjectsUsingBlock:^(AWEVideoStickerEditCircleView * _Nonnull circleView, NSUInteger idx, BOOL * _Nonnull stop) {
        if (circleView.isLyricSticker) {
            if ([self.delegate respondsToSelector:@selector(getSticker:props:)]) {
                IESInfoStickerProps *props = [[IESInfoStickerProps alloc] init];
                [self.delegate getSticker:circleView.stickerEditId props:props];
                CGPoint centerOffset = CGPointMake(self.mediaCenter.x + props.offsetX, self.mediaCenter.y - props.offsetY);
                [circleView updateBorderCenter:centerOffset];
            }
            if ([self.delegate respondsToSelector:@selector(getInfoStickerSize:)]) {
                CGPoint center = circleView.center;
                //通过boundingbox相对位置，修正view中心点
                CGRect boundingbox = [self.delegate getstickerEditBoundBox:circleView.stickerEditId];
                circleView.origin = boundingbox.origin;
                center.x += boundingbox.origin.x;
                center.y -= boundingbox.origin.y;
                [circleView setCenter:center];
       
                // if transform is identity, Keep the original calculation mode
                if(CGAffineTransformIsIdentity(circleView.transform)) {
                    [circleView setFrame:CGRectMake(center.x - boundingbox.size.width / 2, center.y - boundingbox.size.height / 2, boundingbox.size.width, boundingbox.size.height)];
                    // @discuss necessary?  no need to update bounce,  but need trigger internal UI update func -.-
                    [circleView setBounds:CGRectMake(0, 0, boundingbox.size.width, boundingbox.size.height) scale:0];
                    
                }else {
                    // otherwise, do not use frame if view is transformed since it will not correctly reflect the actual location of the view
                    // use bounds + center instead when transform is not identity value
                    [circleView setBounds:CGRectMake(0, 0, boundingbox.size.width, boundingbox.size.height) scale:0];
                };
            }
            *stop = YES;
        }
    }];
}

- (void)resignActiveFinished
{
    [self invalidateCountDownTimer];
}

- (void)removeAllStickerViews
{
    NSArray<AWEVideoStickerEditCircleView *> *stickerViews = [self.stickerViews copy];
    for (AWEVideoStickerEditCircleView *stickerView in stickerViews) {
        [stickerView removeFromSuperview];
    }
    [self.stickerViews removeAllObjects];
}

#pragma mark - alignment line methods

- (AWEStickerDirectionOptions)p_getDirectionWithTranslation:(CGPoint)currentPoint
{
    AWEStickerDirectionOptions direction = AWEStickerDirectionNone;
    if (currentPoint.x > 0.f) {
        direction |= AWEStickerDirectionRight;
    } else if (currentPoint.x < 0.f){
        direction |= AWEStickerDirectionLeft;
    }
    if (currentPoint.y > 0.f) {
        direction |= AWEStickerDirectionDown;
    } else if (currentPoint.y < 0.f) {
        direction |= AWEStickerDirectionUp;
    }
    return direction;
}

- (void)p_resetAdsorbingWithEditView:(UIView *)editView width:(CGFloat)true_w height:(CGFloat)true_h
{
    BOOL reachLeftEdge = ACC_FLOAT_EQUAL_TO(editView.center.x,self.leftAlignLine.acc_right + true_w/2);
    BOOL reachRightEdge = ACC_FLOAT_EQUAL_TO(editView.center.x,self.rightAlignLine.acc_left - true_w/2);
    BOOL reachBottomEdge = ACC_FLOAT_EQUAL_TO(editView.center.y,self.bottomAlignLine.acc_top - true_h/2);
    if (!(reachBottomEdge || reachRightEdge || reachLeftEdge)) {
        self.isEdgeAdsorbing = NO;
    }
}

- (void)p_updateStickerPositionWithEditView:(AWEVideoStickerEditCircleView *)editView
{
    CGFloat offsetX = editView.center.x - self.mediaCenter.x;
    CGFloat offsetY = -(editView.center.y - self.mediaCenter.y);
    if ([self.delegate respondsToSelector:@selector(setSticker:offsetX:offsetY:angle:scale:)]) {
        CGFloat stickerAngle = editView.stickerInfos.angle;
        offsetX -= editView.origin.x;//给effect更新pos时计算原点位置
        offsetY -= editView.origin.y;
        if (ACCRTL().isRTL) {
            offsetX = -offsetX;
            stickerAngle = -stickerAngle;
        }
        [self setSticker:editView.stickerEditId offsetX:offsetX offsetY:offsetY angle:stickerAngle scale:1];
        editView.stickerInfos.offsetX = offsetX;
        editView.stickerInfos.offsetY = offsetY;
    }
}

- (void)p_checkAdsorbingWithEditView:(UIView *)editView width:(CGFloat)true_w height:(CGFloat)true_h direction:(AWEStickerDirectionOptions)direction
{
    BOOL reachLeftEdge = ACC_FLOAT_EQUAL_TO(editView.center.x,self.leftAlignLine.acc_right + true_w/2) && (direction & AWEStickerDirectionLeft);//从右往左移直到触左边线
    BOOL reachRightEdge = ACC_FLOAT_EQUAL_TO(editView.center.x,self.rightAlignLine.acc_left - true_w/2) && (direction & AWEStickerDirectionRight);//从左往右移直到触右边线
    BOOL reachBottomEdge = ACC_FLOAT_EQUAL_TO(editView.center.y,self.bottomAlignLine.acc_top - true_h/2) && (direction & AWEStickerDirectionDown);//从上往下移直到触底边线
    BOOL reachCenterHorizontalWhenMoveVertically = ACC_FLOAT_EQUAL_TO(editView.center.y, self.centerHorizontalAlignLine.acc_centerY) &&
    ((direction & AWEStickerDirectionDown) || direction & AWEStickerDirectionUp);
    BOOL reachCenterVerticalWhenMoveHorizontally = ACC_FLOAT_EQUAL_TO(editView.center.x, self.centerVerticalAlignLine.acc_centerX) &&
    ((direction & AWEStickerDirectionLeft) || direction & AWEStickerDirectionRight);
    if (reachLeftEdge || reachRightEdge || reachBottomEdge || reachCenterHorizontalWhenMoveVertically || reachCenterVerticalWhenMoveHorizontally) {
        self.isEdgeAdsorbing = YES;
    }
}

- (void)p_updateTranslationWithGesture:(UIPanGestureRecognizer *)gesture
                                  view:(AWEVideoStickerEditCircleView *)editView
                                center:(CGPoint)newCenter
                             direction:(AWEStickerDirectionOptions)direction {
    if (gesture.state == UIGestureRecognizerStateChanged) {
        editView.center = newCenter;
        [self p_alignEdgeWithView:editView direction:direction];
        [gesture setTranslation:CGPointZero inView:self];
        
        [self p_updateStickerPositionWithEditView:editView];
    }
}

/// invalid gesture action, reset transform
- (void)p_resetTranslationWithView:(AWEVideoStickerEditCircleView *)editView
{
    CGFloat duration = 0.49;
    
    [self.displayLink invalidate];
    self.displayLink = nil;
    
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleDisplayLink)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    self.resetAnimationAngle = editView.backupStickerInfos.angle - editView.stickerInfos.angle;
    self.resetAnimationScale = editView.backupStickerInfos.scale - editView.stickerInfos.scale;
    CGFloat xDistance = fabs(editView.backupStickerInfos.offsetX - editView.stickerInfos.offsetX);
    CGFloat yDistance = fabs(editView.backupStickerInfos.offsetY - editView.stickerInfos.offsetY);
    if (xDistance >= yDistance) {
        self.resetAnimationXDistance = xDistance;
        self.resetAnimationYDistance = 0.0;
    } else {
        self.resetAnimationXDistance = 0.0;
        self.resetAnimationYDistance = yDistance;
    }
    
    self.currentAnimationView = editView;
    
    [UIView animateWithDuration:duration delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:0.30 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        editView.center = editView.backupCenter;
        
    } completion:^(BOOL finished) {
        // refresh sticker in player
        CGFloat stickerAngle = self.currentAnimationView.backupStickerInfos.angle;
        if (ACCRTL().isRTL) {
            stickerAngle = -stickerAngle;
        }
        [self setSticker:self.currentAnimationView.backupStickerInfos.stickerId
                 offsetX:self.currentAnimationView.backupStickerInfos.offsetX
                 offsetY:self.currentAnimationView.backupStickerInfos.offsetY
                   angle:stickerAngle
                   scale:1];
        [self setSticker:self.currentAnimationView.stickerEditId scale:self.currentAnimationView.backupStickerInfos.scale];
        
        // refresh sticker info
        editView.center = editView.backupCenter;
        IESInfoStickerProps *props = [IESInfoStickerProps new];
        [self.editService.sticker getStickerId:self.currentAnimationView.stickerEditId props:props];
        if (props.duration < 0 || props.duration > [self.publishModel.repoVideoInfo.video totalVideoDuration]) {
            props.duration = [self.publishModel.repoVideoInfo.video totalVideoDuration];
        }
        self.currentAnimationView.stickerInfos = props;
        if (ACCRTL().isRTL) {
            self.currentAnimationView.stickerInfos.angle = -props.angle;
        }
        
        // refresh handle view bounds
        [self.currentAnimationView setBounds:self.currentAnimationView.backupBounds scale:self.currentAnimationView.backupStickerInfos.scale];
        [self fixStickerAndViewScaleDiffWithStickerView:self.currentAnimationView];
        
        [self.displayLink invalidate];
        self.displayLink = nil;
        self.invalidAction = NO;
        self.currentAnimationView = nil;
    }];
}

- (void)handleDisplayLink
{
    CGPoint center = CGPointMake(self.currentAnimationView.layer.presentationLayer.frame.origin.x + self.currentAnimationView.layer.presentationLayer.frame.size.width / 2.0 , self.currentAnimationView.layer.presentationLayer.frame.origin.y + self.currentAnimationView.layer.presentationLayer.frame.size.height / 2.0);
    
    CGFloat offsetX = center.x - self.mediaCenter.x;
    CGFloat offsetY = -(center.y - self.mediaCenter.y);
    
    CGFloat xDistance = fabs(self.currentAnimationView.backupStickerInfos.offsetX - offsetX);
    CGFloat yDistance = fabs(self.currentAnimationView.backupStickerInfos.offsetY - offsetY);
    
    CGFloat distanceScale = 0.0;
    if (ACC_FLOAT_EQUAL_ZERO(self.resetAnimationYDistance) && !ACC_FLOAT_EQUAL_ZERO(self.resetAnimationXDistance)) {
        distanceScale = xDistance / self.resetAnimationXDistance;
    }
    
    if (ACC_FLOAT_EQUAL_ZERO(self.resetAnimationXDistance) && !ACC_FLOAT_EQUAL_ZERO(self.resetAnimationYDistance)) {
        distanceScale = yDistance / self.resetAnimationYDistance;
    }
    
    CGFloat currentAngle = self.currentAnimationView.backupStickerInfos.angle;
    CGFloat currentScale = self.currentAnimationView.backupStickerInfos.scale;
    
    if (self.resetAnimationAngle > 1.0) {
        currentAngle = currentAngle - distanceScale * self.resetAnimationAngle;
    }
    
    if (!ACC_FLOAT_EQUAL_ZERO(self.resetAnimationScale)) {
        currentScale = currentScale - distanceScale * self.resetAnimationScale;
    }
    
    if (ACCRTL().isRTL) {
        offsetX = -offsetX;
        currentAngle = -currentAngle;
    }
    
    [self setSticker:self.currentAnimationView.stickerEditId offsetX:offsetX offsetY:offsetY angle:currentAngle scale:1];
    [self setSticker:self.currentAnimationView.stickerEditId scale:currentScale];
}

- (NSMutableArray *)animationValues:(CGFloat)fromValue toValue:(CGFloat)toValue usingSpringWithDamping:(CGFloat)damping initialSpringVelocity:(CGFloat)velocity duration:(CGFloat)duration{

    //60个关键帧
    NSInteger numOfPoints  = duration * 60;
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:numOfPoints];

    //差值
    CGFloat d_value = toValue - fromValue;

    for(int point = 0; point < numOfPoints; point++) {

        CGFloat x = (CGFloat)point / (CGFloat)numOfPoints;
        CGFloat value = toValue - d_value * (pow(M_E, -damping * x) * cos(velocity * x)); //1 y = 1-e^{-5x} * cos(30x)

        values[point] = @(value);
    }

    return values;
}

- (void)p_alignEdgeWithView:(AWEVideoStickerEditCircleView *)editView  direction:(AWEStickerDirectionOptions)direction
{
    CGFloat radius = atan2f(editView.transform.b, editView.transform.a);
    CGPoint position = editView.center;
    CGSize scaleSize = CGSizeMake((editView.bounds.size.width-6)*editView.stickerInfos.scale, (editView.bounds.size.height-6)*editView.stickerInfos.scale);
    CGFloat true_h = fabs(scaleSize.width * sin(fabs(radius))) + fabs(scaleSize.height * cos(fabs(radius)));
    CGFloat true_w = fabs(scaleSize.width * cos(fabs(radius))) + fabs(scaleSize.height * sin(fabs(radius)));
    
    if ((direction & AWEStickerDirectionLeft) || (direction & AWEStickerDirectionRight)) {
        //left edge line
        if (ACC_FLOAT_EQUAL_TO(position.x - true_w/2,self.leftAlignLine.acc_right)) {
            [self p_showEdgeLineWithType:AWEStickerEdgeLineLeft];
        } else {
            [self p_hideEdgeLineWithType:AWEStickerEdgeLineLeft];
        }
        
        //right edge line
        if (ACC_FLOAT_EQUAL_TO(position.x + true_w/2,self.rightAlignLine.acc_left)) {
            [self p_showEdgeLineWithType:AWEStickerEdgeLineRight];
        } else {
            [self p_hideEdgeLineWithType:AWEStickerEdgeLineRight];
        }

        // center vertical line
        if (ACC_FLOAT_EQUAL_TO(position.x, self.centerVerticalAlignLine.acc_centerX)) {
            [self p_showEdgeLineWithType:AWEStickerEdgeLineCenterVertical];
        } else {
            [self p_hideEdgeLineWithType:AWEStickerEdgeLineCenterVertical];
        }
    }
    
    if ((direction & AWEStickerDirectionDown) || (direction & AWEStickerDirectionUp)) {
        //bottom edge line
        if (ACC_FLOAT_EQUAL_TO(position.y + true_h/2,self.bottomAlignLine.acc_top)) {
            [self p_showEdgeLineWithType:AWEStickerEdgeLineDown];
        } else {
            [self p_hideEdgeLineWithType:AWEStickerEdgeLineDown];
        }

        //center horizontal line
        if (ACC_FLOAT_EQUAL_TO(position.y, self.centerHorizontalAlignLine.acc_centerY)) {
            [self p_showEdgeLineWithType:AWEStickerEdgeLineCenterHorizontal];
        } else {
            [self p_hideEdgeLineWithType:AWEStickerEdgeLineCenterHorizontal];
        }
    }
}

- (void)p_hideEdgeLineWithType:(AWEStickerEdgeLineType)type
{
    switch (type) {
        case AWEStickerEdgeLineLeft:{
            if (!self.leftAlignLine.hidden) {
                self.leftAlignLine.hidden = YES;
                self.leftAlignLine.alpha = 0.f;
            }
        }
            break;
        case AWEStickerEdgeLineRight:{
            if (!self.rightAlignLine.hidden) {
                self.rightAlignLine.hidden = YES;
                self.rightAlignLine.alpha = 0.f;
            }
        }
            break;
        case AWEStickerEdgeLineDown:{
            if (!self.bottomAlignLine.hidden) {
                self.bottomAlignLine.hidden = YES;
                self.bottomAlignLine.alpha = 0.f;
            }
        }
            break;
        case AWEStickerEdgeLineCenterVertical:{
            if (!self.centerVerticalAlignLine.hidden) {
                self.centerVerticalAlignLine.hidden = YES;
                self.centerVerticalAlignLine.alpha = 0.f;
            }
        }
            break;
        case AWEStickerEdgeLineCenterHorizontal:{
            if (!self.centerHorizontalAlignLine.hidden) {
                self.centerHorizontalAlignLine.hidden = YES;
                self.centerHorizontalAlignLine.alpha = 0.f;
            }
        }
            break;
        case AWEStickerEdgeLineNone:
            break;
    }
}

- (void)p_showEdgeLineWithType:(AWEStickerEdgeLineType)type
{
    switch (type) {
        case AWEStickerEdgeLineLeft:{
//            if (self.leftAlignLine.hidden) {
//                self.leftAlignLine.hidden = NO;
//                [UIView animateWithDuration:0.2f animations:^{
//                    self.leftAlignLine.alpha = 1.f;
//                }];
//            }
        }
            break;
        case AWEStickerEdgeLineRight:{
//            if (self.rightAlignLine.hidden) {
//                self.rightAlignLine.hidden = NO;
//                [UIView animateWithDuration:0.2f animations:^{
//                    self.rightAlignLine.alpha = 1.f;
//                }];
//            }
        }
            break;
        case AWEStickerEdgeLineDown:{
//            if (self.bottomAlignLine.hidden) {
//                self.bottomAlignLine.hidden = NO;
//                [UIView animateWithDuration:0.2f animations:^{
//                    self.bottomAlignLine.alpha = 1.f;
//                }];
//            }
        }
            break;
        case AWEStickerEdgeLineCenterVertical:{
            if (self.centerVerticalAlignLine.hidden) {
                self.centerVerticalAlignLine.hidden = NO;
                [UIView animateWithDuration:0.2f animations:^{
                    self.centerVerticalAlignLine.alpha = 1.f;
                }];
            }
        }
            break;
        case AWEStickerEdgeLineCenterHorizontal:{
            if (self.centerHorizontalAlignLine.hidden) {
                self.centerHorizontalAlignLine.hidden = NO;
                [UIView animateWithDuration:0.2f animations:^{
                    self.centerHorizontalAlignLine.alpha = 1.f;
                }];
            }
        }
            break;
        case AWEStickerEdgeLineNone: {
            if (!self.leftAlignLine.hidden || !self.rightAlignLine.hidden || !self.bottomAlignLine.hidden) {
                @weakify(self);
                self.edgeLineTimer = [NSTimer acc_timerWithTimeInterval:1.f block:^(NSTimer * _Nonnull timer) {
                    @strongify(self);
                    self.leftAlignLine.hidden = YES;
                    self.rightAlignLine.hidden = YES;
                    self.bottomAlignLine.hidden = YES;
                    self.fakeProfileView.bottomContainerView.hidden = YES;
                    self.fakeProfileView.rightContainerView.hidden = YES;
                    self.centerVerticalAlignLine.hidden = YES;
                    self.centerHorizontalAlignLine.hidden = YES;
                    [UIView animateWithDuration:0.2f animations:^{
                        self.leftAlignLine.alpha = 0.f;
                        self.rightAlignLine.alpha = 0.f;
                        self.bottomAlignLine.alpha = 0.f;
                        self.centerVerticalAlignLine.alpha = 0;
                        self.centerHorizontalAlignLine.alpha = 0;
                    }];
                } repeats:NO];
                [[NSRunLoop currentRunLoop] addTimer:self.edgeLineTimer forMode:NSRunLoopCommonModes];
                [self.edgeLineTimer fire];
            } else {
                self.leftAlignLine.hidden = YES;
                self.rightAlignLine.hidden = YES;
                self.bottomAlignLine.hidden = YES;
                self.fakeProfileView.bottomContainerView.hidden = YES;
                self.fakeProfileView.rightContainerView.hidden = YES;
                self.leftAlignLine.alpha = 0.f;
                self.rightAlignLine.alpha = 0.f;
                self.bottomAlignLine.alpha = 0.f;
                self.centerVerticalAlignLine.alpha = 0;
                self.centerHorizontalAlignLine.alpha = 0;
            }
        }
            break;
    }
}

#pragma mark - getter/setter

- (void)setPlayerFrame:(NSValue *)playerFrame
{
    _playerFrame = playerFrame;
    CGRect playerFrameRect = [playerFrame CGRectValue];
    [self createMaskViewWithFrame:self.frame playerFrame:playerFrameRect];
    
    if (@available(iOS 11.0,*)) {
        if ([AWEXScreenAdaptManager needAdaptScreen] &&
            ACCViewFrameOptimizeContains(ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize), ACCViewFrameOptimizeFullDisplay)) {
            ACCMasUpdate(self.centerHorizontalAlignLine, {
                make.centerY.mas_equalTo(self.mas_top).mas_offset(CGRectGetMidY(playerFrameRect));
            });
            ACCMasUpdate(self.fakeProfileView, {
                make.bottom.mas_equalTo(self.mas_top).mas_offset(CGRectGetMaxY(playerFrameRect) + 52.f);
            });
        }
    }
    
    ACCMasUpdate(self.bottomAlignLine, {
        make.left.right.equalTo(self);
        make.height.mas_equalTo(1.5f);
        if ((playerFrame.CGRectValue.size.width && playerFrame.CGRectValue.size.height) && (playerFrame.CGRectValue.size.height <= playerFrame.CGRectValue.size.width) && self.maskViewTwo.superview) {//上下有黑边
            make.bottom.equalTo(self.maskViewTwo.mas_top);
        } else {
            if (@available(iOS 11.0,*)) {
                if ([AWEXScreenAdaptManager needAdaptScreen]) {
                    CGFloat offset = - ACC_IPHONE_X_BOTTOM_OFFSET - 73 - 100;
                    if ([UIDevice acc_isIPhoneXsMax]) {
                        offset = - ACC_IPHONE_X_BOTTOM_OFFSET - 85 - 100;
                    }
                    make.bottom.equalTo(self).offset(offset);
                } else {
                    make.bottom.equalTo(self).offset(-200.f);
                }
            }else{
                make.bottom.equalTo(self).offset(-200.f);
            }
        }
    });
}

- (UIView *)leftAlignLine
{
    if (!_leftAlignLine) {
        _leftAlignLine = [self createLine];
    }
    return _leftAlignLine;
}

- (UIView *)rightAlignLine
{
    if (!_rightAlignLine) {
        _rightAlignLine = [self createLine];
    }
    return _rightAlignLine;
}

- (UIView *)bottomAlignLine
{
    if (!_bottomAlignLine) {
        _bottomAlignLine = [self createLine];
    }
    return _bottomAlignLine;
}

- (UIView *)centerVerticalAlignLine {
    if (!_centerVerticalAlignLine) {
        _centerVerticalAlignLine = [self createLine];
    }
    return _centerVerticalAlignLine;
}
- (UIView *)centerHorizontalAlignLine {
    if (!_centerHorizontalAlignLine) {
        _centerHorizontalAlignLine = [self createLine];
    }
    return _centerHorizontalAlignLine;
}

- (UIView *)createLine
{
    UIView *line = [UIView new];
    line.backgroundColor = ACCResourceColor(ACCUIColorConstSecondary);
    return line;
}

- (AWEEditStickerHintView *)hintView {
    if (!_hintView) {
        _hintView = [AWEEditStickerHintView new];
    }
    return _hintView;
}

#pragma mark - Utils

- (void)refreshFakeProfileViewHiddenWithEditedView:(AWEVideoStickerEditCircleView *)editedView {
    if (editedView.acc_centerX + editedView.frame.size.width / 2.f >= self.rightAlignLine.acc_left) {
        self.fakeProfileView.rightContainerView.hidden = NO;
    } else {
        self.fakeProfileView.rightContainerView.hidden = YES;
    }

    if (editedView.acc_centerY + editedView.frame.size.height / 2.f >= self.bottomAlignLine.acc_top) {
        self.fakeProfileView.bottomContainerView.hidden = NO;
    } else {
        self.fakeProfileView.bottomContainerView.hidden = YES;
    }
}

/**
 拦截角度的变化，实现特殊角度的吸附效果
 @param gesture 当前手势
 @param angleInRadians 当前角度，单位弧度
 @param editedView 当前被编辑的stickerView
 */
- (void)interceptToAngleAdSorbingWith:(UIGestureRecognizer *)gesture
                       angleInRadians:(CGFloat)angleInRadians
                                scale:(CGFloat)scale
                           editedView:(AWEVideoStickerEditCircleView *)editedView {
    BOOL angleInRadiansIsNotNegative = angleInRadians >= 0;
    CGFloat fixedAngleRadians = angleInRadiansIsNotNegative ? angleInRadians : M_PI * 2 + angleInRadians;
    fixedAngleRadians = fmodf(fixedAngleRadians, M_PI * 2);
    NSArray<NSNumber *> *adsorbingAngleInRadians = @[@(-M_PI / 4), @(-M_PI / 2), @(-M_PI / 4 * 3), @(-M_PI), @(-M_PI / 4 * 5), @(-M_PI / 2 * 3), @(-M_PI / 4 * 7),
                                                     @0,
                                                     @(M_PI / 4), @(M_PI / 2), @(M_PI / 4 * 3), @(M_PI), @(M_PI / 4 * 5), @(M_PI / 2 * 3), @(M_PI / 4 * 7)];
    CGFloat continuousMoveThreshold = 4.f * M_PI / 180;
    // 如果需要吸附效果记录当前的scale,trans重建transform
    __block CGAffineTransform aimedTransform = CGAffineTransformMakeScale(scale, scale);
    __block CGFloat matchedAngleValue = 0;
    __block BOOL matched = NO;
    [adsorbingAngleInRadians enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ((fixedAngleRadians > (-continuousMoveThreshold + obj.floatValue)) && (fixedAngleRadians < (continuousMoveThreshold + obj.floatValue))) {
            aimedTransform = CGAffineTransformRotate(aimedTransform, obj.floatValue);
            matchedAngleValue = obj.floatValue;
            matched = YES;
            *stop = YES;
        }
    }];
    if ([gesture isKindOfClass:[UIRotationGestureRecognizer class]]) {
        BOOL satifiedRotationThreshold = [gesture isKindOfClass:[UIRotationGestureRecognizer class]] ? fabs(((UIRotationGestureRecognizer *)gesture).rotation) > (6.f * M_PI / 180) : NO;
        if (self.isAngleAdsorbing && !matched && !satifiedRotationThreshold) {
            [editedView showAngleHelperDashLine];
        } else if (self.isAngleAdsorbing && !matched && satifiedRotationThreshold) {
            // 在已经吸附的状态下大于角度的阈值即可继续旋转
            self.isAngleAdsorbing = NO;
            [editedView hideAngleHelperDashLine];
            kCanStickerContainerViewAngleAdsorbingVibrate = YES;
            return;
        }
    } else if ([gesture isKindOfClass:[UIPanGestureRecognizer class]]) {
        BOOL satifiedOneFingerThreshold = [gesture isKindOfClass:[UIPanGestureRecognizer class]] ? fabs(angleInRadians) > (6.f * M_PI / 180) : NO;
        if (self.isAngleAdsorbing && !matched && satifiedOneFingerThreshold) {
            // 在已经吸附的状态下大于3角度的阈值即可继续旋转
            self.isAngleAdsorbing = NO;
            [editedView hideAngleHelperDashLine];
            kCanStickerContainerViewAngleAdsorbingVibrate = YES;
            return;
        }
    }

    if (matched && !self.isAngleAdsorbing) {
        self.isAngleAdsorbing = YES;
    } else {
        if (self.isAngleAdsorbing) {
            [editedView showAngleHelperDashLine];
        }
        return;
    }

    if (self.isAngleAdsorbing) {
        [self generateLightImpactFeedBack];
        kCanStickerContainerViewAngleAdsorbingVibrate = NO;
        editedView.transform = aimedTransform;
        CGFloat fixedAngle = [self fixedAngle:angleInRadians];
        editedView.stickerInfos.angle = fixedAngle;
        editedView.stickerInfos.scale = scale;
        CGFloat stickerAngle = fixedAngle;
        if (ACCRTL().isRTL) {
            stickerAngle = -stickerAngle;
        }
        [self setSticker:self.currentStickerView.stickerEditId
                 offsetX:self.currentStickerView.stickerInfos.offsetX
                 offsetY:self.currentStickerView.stickerInfos.offsetY
                   angle:stickerAngle
                   scale:scale];
        self.lastMatchedScale = scale;
        self.lastMatchedAdsobringAngle = @(matchedAngleValue);
        self.lastMatchedAngleInRadian = angleInRadians / 180 * M_PI;
        [editedView showAngleHelperDashLine];
    }
}

- (CGFloat)fixedAngle:(CGFloat)angleInRadians {
    angleInRadians = fmodf(angleInRadians, M_PI * 2);
    CGFloat inputAngle = angleInRadians / M_PI * 180;
    NSArray<NSNumber *> *adsorbingAngle = @[@(-M_PI / 4), @(-M_PI / 2), @(-M_PI / 4 * 3), @(-M_PI), @(-M_PI / 4 * 5), @(-M_PI / 2 * 3), @(-M_PI / 4 * 7),
                                            @0,
                                            @(M_PI / 4), @(M_PI / 2), @(M_PI / 4 * 3), @(M_PI), @(M_PI / 4 * 5), @(M_PI / 2 * 3), @(M_PI / 4 * 7)];
    __block CGFloat matchedAngle = inputAngle;
    [adsorbingAngle enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat angle = obj.floatValue / M_PI * 180;
        if (fabs(inputAngle - angle) < 4.f) {
            matchedAngle = angle;
            *stop = YES;
        }
    }];
    return matchedAngle;
}

- (void)generateLightImpactFeedBack {
    if (!self.currentStickerView.centerHorizontalDashLayer.hidden) {
        return;
    }
    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *fbGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [fbGenerator prepare];
        [fbGenerator impactOccurred];
    } else {
        // Fallback on earlier versions
    }
}

- (void)setSticker:(NSInteger)stickerEditId offsetX:(CGFloat)x offsetY:(CGFloat)y angle:(CGFloat)angle scale:(CGFloat)scale
{
    if ([self.delegate respondsToSelector:@selector(setSticker:offsetX:offsetY:angle:scale:)]) {
        self.currentStickerView.userInteractionEnabled = YES;
        [self.delegate setSticker:stickerEditId offsetX:x offsetY:y angle:angle scale:scale];
    }
}

- (void)setSticker:(NSInteger)stickerEditId scale:(CGFloat)scale
{
    if ([self.delegate respondsToSelector:@selector(setSticker:scale:)]) {
        [self.delegate setSticker:stickerEditId scale:scale];
    }
}

- (void)trackEvent:(NSString *)event params:(NSDictionary *)params
{
    if (self.publishModel.repoContext.recordSourceFrom == AWERecordSourceFromIM || self.publishModel.repoContext.recordSourceFrom == AWERecordSourceFromIMGreet) {
        return;
    }
    NSMutableDictionary *dict = [self.publishModel.repoTrack.referExtra mutableCopy];
    [dict addEntriesFromDictionary:params];
    [ACCTracker() trackEvent:event params:dict needStagingFlag:NO];
}

- (BOOL)deleteActionForStickerEditCircleView:(AWEVideoStickerEditCircleView *)stickerEditCircleView didReceivePanGesture:(UIPanGestureRecognizer *)pan
{
    BOOL isInDeleteRect = NO;
    CGRect rect = [AWEStoryDeleteView handleFrame];
    rect = [[UIApplication sharedApplication].keyWindow convertRect:rect toView:self.superview];
    CGPoint currentPoint = [pan locationInView:self.superview];
    if (CGRectContainsPoint(rect, currentPoint)) {
        isInDeleteRect = YES;
    }
    
    if (self.playerFrame) {
        if (CGRectIsNull(CGRectIntersection(self.playerFrame.CGRectValue, stickerEditCircleView.frame))) {
            isInDeleteRect = YES;
        }
    }
    
    //如果手指拖动到删除框里了
    CGFloat stickerAlpha = 1;
    if (isInDeleteRect) {
        //触发删除
        [self.deleteView startAnimation];
        stickerAlpha = 0.34;
    } else {
        [self.deleteView stopAnimation];
        stickerAlpha = 1;
    }
    
    if (self.invalidAction) {
        stickerAlpha = 0.34;
    }
    
    if (isInDeleteRect ^ self.isInDeleting) {
        [[AWEFeedBackGenerator sharedInstance] doFeedback];
    }
    
    self.isInDeleting = isInDeleteRect;
    
    if ([self.delegate respondsToSelector:@selector(setSticker:alpha:)]) {
        [self.delegate setSticker:stickerEditCircleView.stickerEditId alpha:stickerAlpha];
    }
    
    return isInDeleteRect;
}

- (void)updateMusicCoverWithMusicModel:(id<ACCMusicModelProtocol>)model {
    [self.fakeProfileView updateMusicCoverWithMusicModel:model];
}


#pragma mark - Pin


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

    CGSize videoFrameSize = self.playerFrame.CGRectValue.size;

    [self.publishModel.repoVideoInfo.video.infoStickers enumerateObjectsUsingBlock:^(IESInfoSticker * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([self.editService.sticker getStickerPinStatus:obj.stickerId] == VEStickerPinStatus_Pinned &&
            [self.editService.sticker getStickerVisible:obj.stickerId]) {
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
            if (outterBBoxContain) {
                //2. 根据rotation+boundingBox计算是否点击到了实际的贴纸区域
                [AWEPinStickerUtil isTouchPointInStickerAreaWithPoint:touchPointOnContainerView
                                             boundingBox:outterBoundingBox
                                           innerRectSize:CGSizeMake(stickerViewW, stickerViewH)
                                                rotation:fixedRotationInRadian
                                              completion:^(BOOL contain, CGSize trueSize) {
                    if (contain) {
                        if ([self.delegate conformsToProtocol:@protocol(AWEStickerContainerViewDelegate)] &&
                            [self.delegate respondsToSelector:@selector(cancelPinSticker:)]) {
                            // 取消Pin
                            [self.delegate cancelPinSticker:obj.stickerId];
                        }
                        touched = YES;
                        [self.stickerViews enumerateObjectsUsingBlock:^(AWEVideoStickerEditCircleView * _Nonnull innerObj, NSUInteger innerIdx, BOOL * _Nonnull innerStop) {
                            if (innerObj.stickerEditId == obj.stickerId) {
                                stickerView = innerObj;
                                // 恢复可视，恢复手势点击
                                stickerView.hidden = NO;
                                *innerStop = YES;
                            }
                        }];
                        // 立即恢复坐标
                        [self resetStickerViewAfterCancelPin:stickerView];
                        // CancelPin之后会在下一帧让Pin失去效果，如果遇到被钉住的主物体在空间内移动或者缩放突变的情况会出现壳视图框恢复和
                        // 贴纸实际位置不同步的情况，所以需要进行额外的修正。
                        // 帧率：<= 30fps。
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1/30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [self resetStickerViewAfterCancelPin:stickerView];
                        });
                        *stop = YES;
                    }
                }];
            }
        }
    }];
    return stickerView;
}

/// 取消指定的一个pin贴纸
- (AWEVideoStickerEditCircleView *)cancelPinnedStickerWithStickerId:(NSInteger )stickerId
{
    if ([self.delegate conformsToProtocol:@protocol(AWEStickerContainerViewDelegate)] &&
        [self.delegate respondsToSelector:@selector(cancelPinSticker:)]) {
        // 取消Pin
        [self.delegate cancelPinSticker:stickerId];
    }
    
    __block AWEVideoStickerEditCircleView *stickerView = nil;
    [self.stickerViews enumerateObjectsUsingBlock:^(AWEVideoStickerEditCircleView * _Nonnull innerObj, NSUInteger innerIdx, BOOL * _Nonnull innerStop) {
        if (innerObj.stickerEditId == stickerId) {
            stickerView = innerObj;
            // 恢复可视，恢复手势点击
            stickerView.hidden = NO;
            *innerStop = YES;
        }
    }];
    // 立即恢复坐标
    [self resetStickerViewAfterCancelPin:stickerView];
    // CancelPin之后会在下一帧让Pin失去效果，如果遇到被钉住的主物体在空间内移动或者缩放突变的情况会出现壳视图框恢复和
    // 贴纸实际位置不同步的情况，所以需要进行额外的修正。
    // 帧率：<= 30fps。
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1/30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self resetStickerViewAfterCancelPin:stickerView];
    });
    
    return stickerView;
}

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
- (void)resetStickerViewAfterCancelPin:(AWEVideoStickerEditCircleView *)stickerView {
    IESInfoStickerProps *props = [IESInfoStickerProps new];
    [self.editService.sticker getStickerId:stickerView.stickerEditId props:props];
    if (stickerView.stickerInfos.duration > 0) {
        props.startTime = stickerView.stickerInfos.startTime;
        props.duration = stickerView.stickerInfos.duration;
    }
    if (props.duration < 0 || props.duration > [self.publishModel.repoVideoInfo.video totalVideoDuration]) {
        props.duration = [self.publishModel.repoVideoInfo.video totalVideoDuration];
    }
    float angle = props.angle;
    if ([ACCRTL() isRTL]) {
        props.angle = -angle;
    }
    stickerView.stickerInfos = props;
    [self fixStickerAndViewScaleDiffWithStickerView:stickerView];
    if (stickerView.isActive) {
        [stickerView becomeActive];
    }
    // 2020-08-20 14:53, I was forced to modify "scale" from "props.scale" to "1.0". This code is so sick.
    [self setSticker:stickerView.stickerEditId offsetX:props.offsetX offsetY:props.offsetY angle:props.angle scale:1.0];
}

- (void)resetStickerWithStickerInfos:(IESInfoStickerProps *)infos viewSize:(CGSize)viewSize center:(CGPoint)center {
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


#pragma mark - UIViewGeometry

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *tmpView = [super hitTest:point withEvent:event];
    
    if (tmpView == self) {
        return nil;
    }
    return tmpView;
}


@end
