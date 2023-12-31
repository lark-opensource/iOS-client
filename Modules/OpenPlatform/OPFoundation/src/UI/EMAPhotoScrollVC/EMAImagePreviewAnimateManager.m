//
//  EMAPreviewAnimateImageView.m
//  PacketImgBackAnimation
//
//  Created by tyh on 2017/5/9.
//  Copyright © 2017年 tyh. All rights reserved.
//

#import "EMAImagePreviewAnimateManager.h"
#import <OPFoundation/UIColor+EMA.h>
#import <OPFoundation/UIView+BDPExtension.h>
#import <OPFoundation/UIWindow+EMA.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <ECOInfra/ECOInfra-Swift.h>

@interface EMAImagePreviewAnimateManager()<UIGestureRecognizerDelegate>

//拖拽开始view
@property (nonatomic, weak)UIView *originView;
//拖拽返回view
@property (nonatomic, weak)UIView *backMaskView;

@property (nonatomic, strong)UIView *panView;

@property (nonatomic, strong)UIView *currentPreviewMaskView; //蒙在当前预览view上的

@property (nonatomic, assign)BOOL reachDismissCondition;

@property (nonatomic, strong)UIPanGestureRecognizer *panGesture;

@property (nonatomic, assign) CGPoint initGesturePoint;

@property (nonatomic, assign) CGRect initFrame;

@property (nonatomic, assign, readwrite)CGFloat minScale;

@property (nonatomic, weak) UIViewController *controller;

@end

@implementation EMAImagePreviewAnimateManager

- (instancetype)initWithController:(UIViewController *)controller
{
    self = [super init];
    if (self) {
        self.controller = controller;
        self.whiteMaskViewEnable = YES;
    }
    return self;
}

+ (BOOL)interativeExitEnable{
    
    if ([[LSUserDefault standard] containsWithKey:@"KSSCommonLogicImageTransitionAnimationEnableKey"]){
        return [[LSUserDefault standard] getBoolForKey:@"KSSCommonLogicImageTransitionAnimationEnableKey"];
    }
    return YES;
}

- (void)registeredPanBackWithGestureView:(UIView *)gestureView
{
    [gestureView addGestureRecognizer:self.panGesture];
}

- (UIWindow *)getCurrentWindow{
    return self.controller.view.window ?: OPWindowHelper.fincMainSceneWindow;
}

- (void)panGestureBegan:(UIPanGestureRecognizer*)panGestureRecognizer { //!OCLint 这块逻辑太复杂不好改，等重构的时候进行整理吧
    if (self.panDelegate && [self.panDelegate respondsToSelector:@selector(ttPreviewPanBackStateChange:scale:)]) {
        [self.panDelegate ttPreviewPanBackStateChange:EMAPreviewAnimateStateWillBegin scale:0];
    }

    if (self.panDelegate && [self.panDelegate respondsToSelector:@selector(ttPreviewPanBackGetOriginView)]) {
        self.originView = [self.panDelegate ttPreviewPanBackGetOriginView];
    }else{
        return;
    }

    if (!self.originView) {
        return;
    }

    //返回图片遮罩
    if (self.panDelegate && [self.panDelegate respondsToSelector:@selector(ttPreviewPanBackGetBackMaskView)]) {
        self.backMaskView = [self.panDelegate ttPreviewPanBackGetBackMaskView];
    }
    if (_whiteMaskViewEnable){
        if (!self.currentPreviewMaskView) {
            self.currentPreviewMaskView = [[UIView alloc] init];
        }

        if ([self.panDelegate respondsToSelector:@selector(ttPreviewPanBackTargetViewFrame)]){
            _currentPreviewMaskView.frame = self.panDelegate.ttPreviewPanBackTargetViewFrame;
        }

        if ([self.panDelegate respondsToSelector:@selector(ttPreviewPanBackTargetViewCornerRadius)] && self.panDelegate.ttPreviewPanBackTargetViewCornerRadius >= 0) {
            _currentPreviewMaskView.layer.cornerRadius = self.panDelegate.ttPreviewPanBackTargetViewCornerRadius;
            if (_currentPreviewMaskView.layer.cornerRadius > 0) {
                _currentPreviewMaskView.layer.masksToBounds = YES;
            }
        }

        if (nil == _backMaskView) {
            self.backMaskView = [self getCurrentWindow];
        }
        if ([self.backMaskView isKindOfClass:[UIImageView class]]){
            _currentPreviewMaskView.frame = self.backMaskView.bounds;
            _currentPreviewMaskView.layer.cornerRadius = self.backMaskView.layer.cornerRadius;
            _currentPreviewMaskView.layer.masksToBounds = self.backMaskView.layer.masksToBounds;
        }
        [self.backMaskView addSubview:_currentPreviewMaskView];
    }

    self.initGesturePoint = [panGestureRecognizer locationInView:self.originView];

    if ([_originView isKindOfClass:[UIImageView class]]){
        if (!_panView) {
            self.panView = [[UIImageView alloc]init];
            _panView.contentMode = UIViewContentModeScaleAspectFill;
            _panView.clipsToBounds = YES;
        }
        ((UIImageView*)_panView).image = ((UIImageView *)_originView).image;
    }else{
        self.panView = [_originView snapshotViewAfterScreenUpdates:NO];
    }
    [[self getCurrentWindow] addSubview:_panView];
    self.panView.frame = _initFrame;

    self.originView.hidden = YES;

    CGFloat currentContainerWidth = [UIWindow ema_currentContainerSize:[self getCurrentWindow]].width;
    self.minScale = currentContainerWidth * .3 / _initFrame.size.width;

    if (self.panDelegate && [self.panDelegate respondsToSelector:@selector(ttPreviewPanBackStateChange:scale:)]) {
        [self.panDelegate ttPreviewPanBackStateChange:EMAPreviewAnimateStateDidBegin scale:0];
    }
}

- (void)panGestureEnd:(UIPanGestureRecognizer*)panGestureRecognizer {
    CGFloat velocityY = [panGestureRecognizer velocityInView:panGestureRecognizer.view].y;
    BOOL top = _panView.bdp_top < _initFrame.origin.y;
    if (top){
        if (velocityY < -500){
            [self finishPanAnimated];
            return;
        }
        if (velocityY > 0){
            [self resetPanAnimated];
            return;
        }
    }else{
        if (velocityY > 500){
            [self finishPanAnimated];
            return;
        }
        if (velocityY < 0){
            [self resetPanAnimated];
            return;
        }
    }

    if (_reachDismissCondition){
        [self finishPanAnimated];
    }else{
        [self resetPanAnimated];
    }
}

- (void)panGestureAction:(UIPanGestureRecognizer*)panGestureRecognizer {
    
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [self panGestureBegan:panGestureRecognizer];
    } else if (panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        [self changePanAnimated:panGestureRecognizer];
    } else if(panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [self panGestureEnd:panGestureRecognizer];
    } else {
        [self resetPanAnimated];
    }
}

- (void)changePanAnimated:(UIPanGestureRecognizer*) panGestureRecognizer {
    
    CGPoint point = [panGestureRecognizer translationInView:self.originView];

    CGFloat length = point.y*point.y + point.x*point.x;
    
    CGFloat max = _initFrame.size.width *_initFrame.size.width;
    CGFloat scale = (max - length)/max;
    
    self.reachDismissCondition = scale < 0.9;
    
    scale = MAX(scale, _minScale);
    
    CGFloat width = _initFrame.size.width * scale;
    CGFloat height = _initFrame.size.height * scale;
    
    CGFloat x = _initFrame.origin.x + _initFrame.size.width / 2 + point.x - width / 2;
    CGFloat y = _initFrame.origin.y + point.y + _initFrame.size.height / 2 - height / 2;
    
    self.panView.frame = CGRectMake(x, y, width, height);
    if (self.panDelegate && [self.panDelegate respondsToSelector:@selector(ttPreviewPanBackStateChange:scale:)]) {
        [self.panDelegate ttPreviewPanBackStateChange:EMAPreviewAnimateStateChange scale:scale];
    }
}

- (void)resetContext{
    //清理现场
    self.originView = nil;
    self.initFrame = CGRectZero;
}


- (void)resetPanAnimated
{
    if (self.panDelegate && [self.panDelegate respondsToSelector:@selector(ttPreviewPanBackStateChange:scale:)]) {
        [self.panDelegate ttPreviewPanBackStateChange:EMAPreviewAnimateStateWillCancel scale:0];
    }
    self.panGesture.enabled = NO;
    [UIView animateWithDuration:.2 animations:^{
        self.panView.frame = _initFrame;
        if ([self.panDelegate respondsToSelector:@selector(ttPreviewPanBackCancelAnimationCompletion)]){
            [self.panDelegate ttPreviewPanBackCancelAnimationCompletion];
        }
    } completion:^(BOOL finished) {
        self.originView.hidden = NO;
        self.panGesture.enabled = YES;
        [_currentPreviewMaskView removeFromSuperview];
        [_panView removeFromSuperview];
        [self resetContext];
        if (self.panDelegate && [self.panDelegate respondsToSelector:@selector(ttPreviewPanBackStateChange:scale:)]) {
            [self.panDelegate ttPreviewPanBackStateChange:EMAPreviewAnimateStateDidCancel scale:0];
        }
    }];
   
}

- (void)finishPanAnimated   //!OCLint 这块逻辑太复杂不好改，等重构的时候进行整理吧
{
    if (self.panDelegate && [self.panDelegate respondsToSelector:@selector(ttPreviewPanBackStateChange:scale:)]) {
        [self.panDelegate ttPreviewPanBackStateChange:EMAPreviewAnimateStateWillFinish scale:0];
    }
    
    UIView *finishBackView = [self.panDelegate respondsToSelector:@selector(ttPreviewPanBackGetFinishBackgroundView)] ? self.panDelegate.ttPreviewPanBackGetFinishBackgroundView : nil;
    if (!finishBackView) {
        finishBackView = [self getCurrentWindow];
    }
    CGRect backFrame = CGRectMake(finishBackView.bdp_width / 2 , finishBackView.bdp_height / 2, 1, 1);
    CGFloat backCornerRadius = 0;
    CGRect panViewFrame;
    UIView *secondPanView = nil;
    if (_whiteMaskViewEnable){
        if (!CGRectEqualToRect(_currentPreviewMaskView.bounds, CGRectZero)){
            backFrame = [_currentPreviewMaskView convertRect:_currentPreviewMaskView.bounds toView:finishBackView];
            backCornerRadius = _currentPreviewMaskView.layer.cornerRadius;
        }
    }else if ([self.panDelegate respondsToSelector:@selector(ttPreviewPanBackTargetViewFrame)]){
        backFrame = self.panDelegate.ttPreviewPanBackTargetViewFrame;
        if ([self.panDelegate respondsToSelector:@selector(ttPreviewPanBackTargetViewCornerRadius)]) {
            backCornerRadius = self.panDelegate.ttPreviewPanBackTargetViewCornerRadius;
        }
    }
    
    panViewFrame = [self.panView convertRect:self.panView.bounds toView:finishBackView];
    
    [finishBackView addSubview:self.panView];
    self.panView.frame = panViewFrame;
    self.panGesture.enabled = NO;
    
    if ([self.panDelegate respondsToSelector:@selector(ttPreviewPanBackImageForSwitch)] && [[self.panDelegate ttPreviewPanBackImageForSwitch] isKindOfClass:[UIImage class]]){
        UIViewContentMode contentMode = UIViewContentModeScaleAspectFill;
        if ([self.panDelegate respondsToSelector:@selector(ttPreViewPanBackImageViewForSwitchContentMode)]){
            contentMode = [self.panDelegate ttPreViewPanBackImageViewForSwitchContentMode];
        }
        UIImage *secondImage;
        secondImage = [self.panDelegate ttPreviewPanBackImageForSwitch];
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.image = secondImage;
        imageView.clipsToBounds = YES;
        imageView.alpha = 0;
        if (!CGSizeEqualToSize(secondImage.size, CGSizeZero)){
            imageView.contentMode = contentMode;
            imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            imageView.bdp_size = _panView.bdp_size;
            if (imageView.bdp_width < imageView.bdp_height){
                if (secondImage.size.width < secondImage.size.height){
                    imageView.bdp_width = imageView.bdp_height * secondImage.size.width / secondImage.size.height;
                }else{
                    imageView.bdp_height = imageView.bdp_width * secondImage.size.height / secondImage.size.width;
                }
            }else{
                if (secondImage.size.width < secondImage.size.height){
                    imageView.bdp_height = imageView.bdp_width * secondImage.size.height / secondImage.size.width;
                }else{
                    imageView.bdp_width = imageView.bdp_height * secondImage.size.width / secondImage.size.height;
                }
            }
            imageView.center = _panView.center;
            [finishBackView addSubview:imageView];
        }else{
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            imageView.frame = _panView.bounds;
            secondPanView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self.panView addSubview:imageView];
        }
        secondPanView = imageView;
    }else if ([self.panDelegate respondsToSelector:@selector(ttPreviewPanBackViewForSwitch)]){
        //需要按比例放大
        secondPanView = [self.panDelegate ttPreviewPanBackViewForSwitch];
        CGFloat secondPanViewWidth = self.panView.bdp_width*backFrame.size.width/self.originView.bdp_width;
        CGFloat secondPanViewHeight = self.panView.bdp_height*backFrame.size.height/self.originView.bdp_height;
        secondPanView.frame = CGRectMake(self.panView.bdp_left, self.panView.bdp_top + (self.panView.bdp_height - secondPanView.bdp_height) / 2, secondPanViewWidth, secondPanViewHeight);
        [finishBackView addSubview:secondPanView];
        secondPanView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }

//    [UIView animateWithDuration:.22 customTimingFunction:CustomTimingFunctionSineOut delay:0 options:UIViewAnimationOptionTransitionCrossDissolve animation:^{
    [UIView animateWithDuration:.22 delay:0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        if ([self.panDelegate respondsToSelector:@selector(ttPreviewPanBackFinishAnimationCompletion)]){
            [self.panDelegate ttPreviewPanBackFinishAnimationCompletion];
        }
        self.panView.frame = backFrame;
        if (backCornerRadius >= 0) {
            self.panView.layer.cornerRadius = backCornerRadius;
        }

        if (backCornerRadius > 0) {
            self.panView.layer.masksToBounds = YES;
        }
        if (![secondPanView isKindOfClass:[UIImageView class]] || (secondPanView.contentMode == UIViewContentModeScaleAspectFill && [secondPanView isKindOfClass:[UIImageView class]])){
            secondPanView.frame = backFrame;
            if (backCornerRadius >= 0) {
                secondPanView.layer.cornerRadius = backCornerRadius;
            }
            if (backCornerRadius > 0) {
                secondPanView.layer.masksToBounds = YES;
            }
        }
    } completion:^(BOOL finished) {
        [self resetContext];
        [secondPanView removeFromSuperview];
        [self.panView removeFromSuperview];
        [_currentPreviewMaskView removeFromSuperview];
        self.panGesture.enabled = YES;
        if (self.panDelegate && [self.panDelegate respondsToSelector:@selector(ttPreviewPanBackStateChange:scale:)]) {
            [self.panDelegate ttPreviewPanBackStateChange:EMAPreviewAnimateStateDidFinish scale:0];
        }
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    }];
    [UIView animateWithDuration:.05 delay:.02 options:0 animations:^{
        secondPanView.alpha = 1;
    } completion:nil];
}

#pragma mark - Getter & Setter

- (UIPanGestureRecognizer *)panGesture{
    if (nil == _panGesture){
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
        _panGesture.delegate = self;
    }
    return _panGesture;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    if (gestureRecognizer == _panGesture){
        
        if (![EMAImagePreviewAnimateManager interativeExitEnable]){
            return NO;
        }
        
        BOOL gestureEnable = NO;
        if ([self.panDelegate respondsToSelector:@selector(ttPreviewPanGestureRecognizerShouldBegin:)]){
            gestureEnable = [self.panDelegate ttPreviewPanGestureRecognizerShouldBegin:gestureRecognizer];
        }
        if (!gestureEnable){
            return NO;
        }
        
        CGPoint velocity = [_panGesture velocityInView:_panGesture.view];
        if (fabs(velocity.x) > fabs(velocity.y)){
            return NO;
        }
        
        if ([self.panDelegate respondsToSelector:@selector(ttPreviewPanBackGetOriginView)]) {
            self.originView = [self.panDelegate ttPreviewPanBackGetOriginView];
        }
        if (_originView == nil){
            return NO;
        }
        
        self.initFrame = [_originView convertRect:self.originView.bounds toView:[self getCurrentWindow]];
        
        if (CGRectGetWidth(_initFrame) == 0 || CGRectGetHeight(_initFrame) == 0){
            return NO;
        }
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    if ([self.panDelegate respondsToSelector:@selector(ttPreviewPanGestureRecognizer:shouldRequireFailureOfGestureRecognizer:)]){
        return [self.panDelegate ttPreviewPanGestureRecognizer:gestureRecognizer shouldRequireFailureOfGestureRecognizer:otherGestureRecognizer];
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    if ([self.panDelegate respondsToSelector:@selector(ttPreviewPanGestureRecognizer:shouldBeRequiredToFailByGestureRecognizer:)]){
        return [self.panDelegate ttPreviewPanGestureRecognizer:gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:otherGestureRecognizer];
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    if ([self.panDelegate respondsToSelector:@selector(ttPreviewPanGestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:)]){
        return [self.panDelegate ttPreviewPanGestureRecognizer:gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:otherGestureRecognizer];
    }
    return NO;
}
@end




