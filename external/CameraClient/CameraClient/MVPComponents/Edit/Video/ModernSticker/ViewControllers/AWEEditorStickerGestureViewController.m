//
//  AWEEditorStickerGestureViewController.m
//  AWEStudio
//
//  Created by li xingdong on 2018/12/4.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "AWEStickerContainerView.h"
#import "AWEStoryTextContainerView.h"
#import "AWESimplifiedStickerContainerView.h"
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <TTVideoEditor/VEEditorSession+Effect.h>
#import <CreativeKitSticker/ACCStickerEventFlowProtocol.h>
#import <CreativeKitSticker/ACCStickerProtocol.h>
#import "ACCCanvasStickerContentView.h"
#import <CreationKitInfra/ACCRTLProtocol.h>

@interface AWEEditorStickerGestureViewController ()<UIGestureRecognizerDelegate>

@property (nonatomic, strong, readwrite) AWEStickerContainerView *infoStickerContainer;
@property (nonatomic, strong, readwrite) AWEStoryTextContainerView *textStickerContainer;
@property (nonatomic, strong, readwrite) AWESimplifiedStickerContainerView *simplifiedStickerContainer;
@property (nonatomic, assign, readwrite) AWEGestureActiveType gestureActiveStatus;

@property (nonatomic, weak) UIView *targetView;
@property (nonatomic, weak) UIView *previousTargetViewForPinch;
@property (nonatomic, weak) UIView *previousTargetViewForRotate;

@end

@implementation AWEEditorStickerGestureViewController

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        self.view.backgroundColor = [UIColor clearColor];
        [self setupGesture];
    }
    
    return self;
}

- (void)setupGesture
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [self.view addGestureRecognizer:tap];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
    pan.delegate = self;
    [self.view addGestureRecognizer:pan];
    
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchAction:)];
    pinch.delegate = self;
    [self.view addGestureRecognizer:pinch];
    
    UIRotationGestureRecognizer *rotation = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotationAction:)];
    rotation.delegate = self;
    [self.view addGestureRecognizer:rotation];
}

#pragma mark - Public

- (void)configInfoStickerContainer:(AWEStickerContainerView *)container
{
    self.infoStickerContainer = container;
}

- (void)configTextStickerContainer:(AWEStoryTextContainerView *)container
{
    self.textStickerContainer = container;
}

- (void)configSimpliedInfoStickerContainer:(AWESimplifiedStickerContainerView *)container
{
    self.simplifiedStickerContainer = container;
}

#pragma mark - Gesture Action

- (void)tapAction:(UITapGestureRecognizer *)gesture
{
    AWELogToolInfo(AWELogToolTagEdit, @"==== PIN ==== AWEEditorStickerGestureViewController tapAction: %@", gesture);
    if ([self.delegate respondsToSelector:@selector(enableTapGesture)] &&
        ![self.delegate enableTapGesture]) {
        return;
    }

    if (self.gestureActiveStatus != AWEGestureActiveTypeNone) {
        return;
    }
    
    [self.stickerContainerView beforeGestureBeRecognizerInSticker:gesture];

    if (self.infoStickerContainer) {
        [self.infoStickerContainer updateLyricStickerInfoPositionAndSize];
    }
    
    UIView *targetView = [self hitTargetStickerWithGesture:gesture];
    AWELogToolInfo(AWELogToolTagEdit, @"==== PIN ==== AWEEditorStickerGestureViewController tapAction targetView:%@", targetView);
    if (![self startGestureOnView:targetView]) {
        AWELogToolInfo(AWELogToolTagEdit, @"==== PIN ==== AWEEditorStickerGestureViewController tapAction return cause of targetView && ![self startGestureOnView:targetView]");
        return;
    }
    self.targetView = nil;
    
    if (targetView) {
        if ([self.stickerContainerView isChildView:targetView]) {
            [self.stickerContainerView editorSticker:targetView receivedTapGesture:gesture];
            
        } else if ([targetView isKindOfClass:[AWEStoryBackgroundTextView class]]) {
            [self.textStickerContainer editorSticker:targetView receivedTapGesture:gesture];
            
        } else if ([targetView isKindOfClass:[AWEVideoStickerEditCircleView class]] && self.infoStickerContainer) {
            [self.infoStickerContainer editorSticker:targetView receivedTapGesture:gesture];
            
        } else if ([targetView isKindOfClass:[AWEVideoStickerEditCircleView class]]) {
            AWELogToolInfo(AWELogToolTagEdit, @"==== PIN ==== AWEEditorStickerGestureViewController tapAction enter editorSticker receivedTapGesture");
            [self.simplifiedStickerContainer editorSticker:targetView receivedTapGesture:gesture];
        }
        return;
    }
    
    // 取消文字编辑框
    if (self.currentTextStickerView) {
        [self.textStickerContainer editorSticker:nil receivedTapGesture:gesture];
        return;
    }
    
    // 取消贴纸编辑框
    if (self.currentInfoStickerView) {
        [self.infoStickerContainer editorSticker:nil receivedTapGesture:gesture];
        return;
    }
    
    BOOL artboardFlag = NO;
    if (self.stickerContainerView != nil) {
        BOOL tmpFlag =
        [self.stickerContainerView endEditIfNeeded:gesture onTargetChange:targetView];
        
        if (tmpFlag) {
            artboardFlag = YES;
        }
    }
    if (artboardFlag) {
        return;
    }

    // 进入文字编辑
    if ((!targetView || (targetView && [targetView isKindOfClass:[AWEStoryBackgroundTextView class]])) && self.textStickerContainer) {
        ACCBLOCK_INVOKE(self.tapToTextEdit);
        [self.textStickerContainer editorSticker:nil receivedTapGesture:gesture];
        return;
    }
}

- (void)panAction:(UIPanGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self.stickerContainerView beforeGestureBeRecognizerInSticker:gesture];
    }

    if (self.infoStickerContainer) {
        [self.infoStickerContainer updateLyricStickerInfoPositionAndSize];
    }
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        UIView *targetView = [self hitTargetStickerWithGesture:gesture];
        if (![self startGestureOnView:targetView]) {
            return;
        }
    }
    if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        self.gestureActiveStatus &= ~AWEGestureActiveTypePan;
    }

    if (self.targetView) {
        if ([self.stickerContainerView isChildView:self.targetView]) {
            [self.stickerContainerView editorSticker:self.targetView receivedPanGesture:gesture];
            self.previousTargetViewForPinch = self.targetView;
            self.previousTargetViewForRotate = self.targetView;
        } else if ([self.targetView isKindOfClass:[AWEStoryBackgroundTextView class]]) {
            [self.textStickerContainer editorSticker:self.targetView receivedPanGesture:gesture];
            
        } else if ([self.targetView isKindOfClass:[AWEVideoStickerEditCircleView class]] && self.infoStickerContainer) {
            [self.infoStickerContainer editorSticker:self.targetView receivedPanGesture:gesture];
            
        } else if ([self.targetView isKindOfClass:[AWEVideoStickerEditCircleView class]]) {
            [self.simplifiedStickerContainer editorSticker:self.targetView receivedPanGesture:gesture];
        }
    }
    if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        if (self.gestureActiveStatus == AWEGestureActiveTypeNone) {
            self.targetView = nil;
        }
    } else {
        self.gestureActiveStatus |= AWEGestureActiveTypePan;
    }
}

- (void)pinchAction:(UIPinchGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self.stickerContainerView beforeGestureBeRecognizerInSticker:gesture];
    }

    if (gesture.state == UIGestureRecognizerStateBegan) {
        UIView *targetView = [self hitTargetStickerWithGesture:gesture];
        if (![self startGestureOnView:targetView]) {
            return;
        }
    }
    if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        self.gestureActiveStatus &= ~AWEGestureActiveTypePinch;
    }

    if (self.targetView || self.previousTargetViewForPinch) {
        if ([self.stickerContainerView isChildView:self.targetView] || [self.stickerContainerView isChildView:self.previousTargetViewForPinch]) {
            [self.stickerContainerView editorSticker:(self.targetView ? : self.previousTargetViewForPinch) receivedPinchGesture:gesture];
            self.previousTargetViewForRotate = self.targetView;

        } else if ([self.targetView isKindOfClass:[AWEStoryBackgroundTextView class]]) {
            [self.textStickerContainer editorSticker:self.targetView receivedPinchGesture:gesture];
            
        } else if ([self.targetView isKindOfClass:[AWEVideoStickerEditCircleView class]] && self.infoStickerContainer) {
            [self.infoStickerContainer editorSticker:self.targetView receivedPinchGesture:gesture];
            
        } else if ([self.targetView isKindOfClass:[AWEVideoStickerEditCircleView class]]) {
            [self.simplifiedStickerContainer editorSticker:self.targetView receivedPinchGesture:gesture];
        }
    }
    if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        self.previousTargetViewForPinch = nil;
        if (self.gestureActiveStatus == AWEGestureActiveTypeNone) {
            self.targetView = nil;
        }
    } else {
        self.gestureActiveStatus |= AWEGestureActiveTypePinch;
    }
}

- (void)rotationAction:(UIRotationGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self.stickerContainerView beforeGestureBeRecognizerInSticker:gesture];
    }

    if (gesture.state == UIGestureRecognizerStateBegan) {
        UIView *targetView = [self hitTargetStickerWithGesture:gesture];
        if (![self startGestureOnView:targetView]) {
            return;
        }
    }

    // fix AME-90020: ensure gestureActiveStatus correct
    if ([self.targetView isKindOfClass:[AWEStoryBackgroundTextView class]]) {
        if (((AWEStoryBackgroundTextView *)self.targetView).isCaption) {
            return;
        }
    }

    if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        self.gestureActiveStatus &= ~AWEGestureActiveTypeRotate;
    }

    if (self.targetView || self.previousTargetViewForRotate) {
        if ([self.stickerContainerView isChildView:self.targetView] || [self.stickerContainerView isChildView:self.previousTargetViewForRotate]) {
            [self.stickerContainerView editorSticker:(self.targetView ? : self.previousTargetViewForRotate) receivedRotationGesture:gesture];
            self.previousTargetViewForPinch = self.targetView;
            
        } else if ([self.targetView isKindOfClass:[AWEStoryBackgroundTextView class]]) {
            [self.textStickerContainer editorSticker:self.targetView receivedRotationGesture:gesture];
            
        } else if ([self.targetView isKindOfClass:[AWEVideoStickerEditCircleView class]] && self.infoStickerContainer) {
            [self.infoStickerContainer editorSticker:self.targetView receivedRotationGesture:gesture];
            
        } else if ([self.targetView isKindOfClass:[AWEVideoStickerEditCircleView class]]) {
            [self.simplifiedStickerContainer editorSticker:self.targetView receivedRotationGesture:gesture];
        }
    }
    if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        self.previousTargetViewForRotate = nil;
        if (self.gestureActiveStatus == AWEGestureActiveTypeNone) {
            self.targetView = nil;
        }
    } else {
        self.gestureActiveStatus |= AWEGestureActiveTypeRotate;
    }
}

#pragma mark - Utils

- (UIView *)hitTargetStickerWithGesture:(UIGestureRecognizer *)gesture
{
    return [self hitTargetStickerWithGesture:gesture deSelected:YES dispatchGestureEventFlow:NO];
}

- (UIView *)hitTargetStickerWithGesture:(UIGestureRecognizer *)gesture deSelected:(BOOL)deSelected
{
    return [self hitTargetStickerWithGesture:gesture deSelected:deSelected dispatchGestureEventFlow:YES];
}

- (UIView *)hitTargetStickerWithGesture:(UIGestureRecognizer *)gesture deSelected:(BOOL)deSelected dispatchGestureEventFlow:(BOOL)dispatchGestureEventFlow
{
    if (dispatchGestureEventFlow) {
        if (gesture.state == UIGestureRecognizerStateBegan) {
            [self.stickerContainerView beforeGestureBeRecognizerInSticker:gesture];
        }
    }

    AWELogToolInfo(AWELogToolTagEdit, @"==== PIN ==== AWEEditorStickerGestureViewController hitTargetStickerWithGesture gesture:%@ deSelected:%@", gesture, deSelected ? @"YES" : @"NO");
    __block UIView *targetView = nil;
        
    if (self.stickerContainerView != nil && !targetView) {
        targetView = [self.stickerContainerView targetViewFor:gesture];
    }
    
    if (self.textStickerContainer.captionView &&
        !self.textStickerContainer.captionView.hidden && !targetView) {
        CGPoint center = [gesture locationInView:self.textStickerContainer];
        center = [self.textStickerContainer convertPoint:center toView:self.textStickerContainer.captionView];
        if (CGRectContainsPoint(self.textStickerContainer.captionView.bounds, center)) {
            targetView = self.textStickerContainer.captionView;
        }
    }
    
    if (self.textStickerContainer && !targetView) {
        [self.textStickerContainer.textViews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(AWEStoryBackgroundTextView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGPoint center = [gesture locationInView:self.textStickerContainer];
            center = [self.textStickerContainer convertPoint:center toView:obj];
            if (!obj.hidden && CGRectContainsPoint(obj.bounds, center)) {
                targetView = obj;
                *stop = YES;
            }
        }];
    }
    
    if (self.infoStickerContainer && !targetView) {
        [self.infoStickerContainer.stickerViews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(AWEVideoStickerEditCircleView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGPoint center = [gesture locationInView:self.infoStickerContainer];
            center = [self.infoStickerContainer convertPoint:center toView:obj];
            if (!obj.hidden && CGRectContainsPoint(obj.bounds, center)) {
                targetView = obj;
                *stop = YES;
            }
        }];
        [self processPinStickerHitTestWithGesrure:gesture containerView:self.infoStickerContainer targetView:&targetView];
    }
    
    if (self.simplifiedStickerContainer && !targetView) {
        [self.simplifiedStickerContainer.stickerViews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(AWEVideoStickerEditCircleView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGPoint center = [gesture locationInView:self.simplifiedStickerContainer];
            center = [self.simplifiedStickerContainer convertPoint:center toView:obj];
            if (!obj.hidden && CGRectContainsPoint(obj.bounds, center)) {
                targetView = obj;
                *stop = YES;
            }
        }];
        AWELogToolInfo(AWELogToolTagEdit, @"==== PIN ==== AWEEditorStickerGestureViewController hitTargetStickerWithGesture before processPinStickerHitTestWithGesrure targetView:%@", targetView);
        [self processPinStickerHitTestWithGesrure:gesture containerView:self.simplifiedStickerContainer targetView:&targetView];
    }
    
    if (deSelected) {
        // 取消非编辑类型的贴纸选中
        if ([self.stickerContainerView isChildView:targetView]) {
            [self.infoStickerContainer editorStickerGestureStarted];
            [self.textStickerContainer editorStickerGestureStarted];
            
        } else if ([targetView isKindOfClass:[AWEStoryBackgroundTextView class]]) {
            [self.infoStickerContainer editorStickerGestureStarted];
            [self.stickerContainerView endEditIfNeeded:gesture onTargetChange:targetView];

        } else if ([targetView isKindOfClass:[AWEVideoStickerEditCircleView class]]) {
            [self.textStickerContainer editorStickerGestureStarted];
            [self.stickerContainerView endEditIfNeeded:gesture onTargetChange:targetView];
        }
    }
    
    if ([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
        return targetView;
    }
    
    if ([gesture isKindOfClass:[UIPanGestureRecognizer class]] && gesture.numberOfTouches == 1) {
        return targetView;
    }
    
    if (self.currentTextStickerView) {
        targetView = self.textStickerContainer.currentOperationView;
        self.infoStickerContainer.currentStickerView = nil;
    } else if (self.currentInfoStickerView) {
        targetView = self.infoStickerContainer.currentStickerView;
    }
    
    return targetView;
}


/// Pin贴纸需求将贴纸Pin住之后，贴纸跟踪视频内物体，可能出现贴纸框（壳视图）在原地响应了手势，
/// 但是此时贴纸在画面中是不可见的，需要做特殊处理，否则会进行反选等一系列认为点击到贴纸的操作）
/// @param gesture 手势
/// @param containerView 容器视图 simplifiedContainer 或者 infoStickerContainer
/// @param targetView 识别到点击的视图
- (void)processPinStickerHitTestWithGesrure:(UIGestureRecognizer *)gesture
                              containerView:(UIView *)containerView
                                 targetView:(UIView **)targetView {
    if (containerView != self.simplifiedStickerContainer && containerView != self.infoStickerContainer) {
        AWELogToolInfo(AWELogToolTagEdit, @"==== PIN ==== AWEEditorStickerGestureViewController hitTargetStickerWithGesture  processPinStickerHitTestWithGesrure return because containerView != self.simplifiedStickerContainer && containerView != self.infoStickerContainer");
        return;
    }
    if (targetView && !*targetView) {
        AWELogToolInfo(AWELogToolTagEdit, @"==== PIN ==== AWEEditorStickerGestureViewController hitTargetStickerWithGesture  processPinStickerHitTestWithGesrure hit !*targetView");
        // Case: 贴纸框（壳视图）不在此处，但是实际贴纸在此处，需要通过计算当前是否点击到了Pin贴纸内容，并且去取消Pin
        CGPoint center = [gesture locationInView:containerView];
        if ([ACCRTL() isRTL]) {
            center.x = containerView.frame.size.width - center.x;
        }
        if ([containerView respondsToSelector:@selector(touchPinnedStickerInVideoAndCancelPin:)]) {
            *targetView = [containerView performSelector:@selector(touchPinnedStickerInVideoAndCancelPin:) withObject:[NSValue valueWithCGPoint:center]];
        }
    } else if (targetView && [*targetView isKindOfClass:[AWEVideoStickerEditCircleView class]] && [containerView respondsToSelector:@selector(player)]){
        AWELogToolInfo(AWELogToolTagEdit, @"==== PIN ==== AWEEditorStickerGestureViewController hitTargetStickerWithGesture  processPinStickerHitTestWithGesrure hit [*targetView isKindOfClass:[AWEVideoStickerEditCircleView class]] && [containerView respondsToSelector:@selector(player)]");
        // Case: 贴纸框（壳视图）在此处，但是实际贴纸不在此处或者贴纸当前的状态是不可见的，需要取消手势的响应。
        id<ACCEditServiceProtocol> editService = [containerView performSelector:@selector(editService)];
        if (!editService) {
            AWELogToolInfo(AWELogToolTagEdit, @"==== PIN ==== AWEEditorStickerGestureViewController hitTargetStickerWithGesture  processPinStickerHitTestWithGesrure return cause of non player");
            return;
        }
        BOOL isPinned = ([editService.sticker getStickerPinStatus:((AWEVideoStickerEditCircleView *)*targetView).stickerInfos.stickerId] == VEStickerPinStatus_Pinned);
        BOOL isVisible = [editService.sticker getStickerVisible:((AWEVideoStickerEditCircleView *)*targetView).stickerInfos.stickerId];
        if (isPinned && !isVisible) {
            *targetView = nil;
        }
        AWELogToolInfo(AWELogToolTagEdit, @"==== PIN ==== AWEEditorStickerGestureViewController hitTargetStickerWithGesture  processPinStickerHitTestWithGesrure isPinned:%@ isVisible:%@", isPinned ? @"YES" : @"NO", isVisible ? @"YES" : @"NO");
    } else {
        AWELogToolInfo(AWELogToolTagEdit, @"==== PIN ==== AWEEditorStickerGestureViewController hitTargetStickerWithGesture  processPinStickerHitTestWithGesrure hit nothing");
    }
}

- (BOOL)startGestureOnView:(UIView *)view
{
    if (self.gestureActiveStatus != AWEGestureActiveTypeNone && view != self.targetView) {
        return NO;
    }
    
    self.targetView = view;
    
    if (self.gestureStartBlock) {
        
        BOOL ret = ACCBLOCK_INVOKE(self.gestureStartBlock, view);
        if (!ret) {
            self.targetView = nil;
            self.gestureActiveStatus = AWEGestureActiveTypeNone;
        }
        return ret;
    } else {
        return YES;
    }
    
    ACCBLOCK_INVOKE(self.gestureStartBlock, view);
    return YES;
}

#pragma mark - getter

- (void)setInfoStickerContainer:(AWEStickerContainerView *)infoStickerContainer
{
    _infoStickerContainer = infoStickerContainer;
}

- (AWEStoryBackgroundTextView *)currentTextStickerView
{
    if (self.textStickerContainer.currentOperationView) {
        return self.textStickerContainer.currentOperationView;
    }
    return nil;
}

- (AWEVideoStickerEditCircleView *)currentInfoStickerView
{
    if (self.infoStickerContainer.currentStickerView) {
        return self.infoStickerContainer.currentStickerView;
    }
    return nil;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (![gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        return NO;
    }
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        UIView *view = [self.view hitTest:[gestureRecognizer locationInView:self.view] withEvent:nil];
        if ([view isKindOfClass:[ACCCanvasStickerContentView class]]) {
            return NO;
        }
    }
    
    [self.stickerContainerView beforeGestureBeRecognizerInSticker:gestureRecognizer];
    
    // current operating view and will response view check
    if (self.targetView != nil && [self.targetView isKindOfClass:[ACCBaseStickerView class]] && [self.targetView conformsToProtocol:@protocol(ACCGestureResponsibleStickerProtocol)]) {
        ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> *operatingView = (ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> *)self.targetView;
        if (operatingView != nil) {
            if (![operatingView supportGesture:gestureRecognizer]) {
                return NO;
            }
        }
    }
    UIView *targetView = self.targetView;
    if (targetView == nil) {
        targetView = [self.stickerContainerView targetViewFor:gestureRecognizer];
        // not old IM photo and not found a sticker
        if (targetView == nil && self.textStickerContainer == nil && self.infoStickerContainer == nil && self.simplifiedStickerContainer == nil) {
            return NO;
        }
    }
    return YES;
}

#pragma mark - ContainerHierachy
// 这个东西不属于这里
// 不过目前大家都会往这里注册，这里的信息最全
// TODO: DINGLI 贴纸容器
- (void)focuseOn:(UIView *)focusedView rootView:(UIView *)rootView
{
    if (focusedView != self.textStickerContainer) {
        return;
    }
    
    if (self.stickerContainerView != nil) {
        [rootView insertSubview:self.stickerContainerView belowSubview:focusedView];
    }
}

- (void)resetContainerHierachy:(UIView *)rootView
{
    if (self.stickerContainerView != nil) {
        [rootView insertSubview:self.textStickerContainer belowSubview:self.stickerContainerView];
    }
}

@end
