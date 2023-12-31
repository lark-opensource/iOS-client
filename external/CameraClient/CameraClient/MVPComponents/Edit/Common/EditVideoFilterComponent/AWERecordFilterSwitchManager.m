//
//  AWERecordFilterSwitchManager.m
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/3/25.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWERecordFilterSwitchManager.h"

#import <CreationKitArch/AWEColorFilterDataManager.h>
#import <CreationKitInfra/ACCTapticEngineManager.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitComponents/AWECameraFilterConfiguration.h>
#import <CreationKitInfra/AWESlider.h>
#import <CreationKitInfra/ACCRTLProtocol.h>

@interface AWERecordFilterSwitchManager () <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UIViewController *targetController;
@property (nonatomic, copy) NSArray *filterArray;

//滑动滤镜切换 相关
@property (nonatomic, strong) IESEffectModel *currentFilter;
@property (nonatomic, strong) UIPanGestureRecognizer *panGes;
@property (nonatomic, assign) NSInteger switchFilterDirection;
@property (nonatomic, strong) IESEffectModel *switchToFilter;
@property (nonatomic, assign) BOOL filterAniTiming;
@property (nonatomic, assign) double autoRenderProgress;
@property (nonatomic, assign) BOOL isCompeleteWhenFilterAniBegin;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) BOOL isSwitchFilter;
@property (nonatomic, strong) AWECameraFilterConfiguration *filterConfiguration;
@property (nonatomic, strong) NSHashTable<UIView *> *panGesExcludeViews;

@property (nonatomic, assign) BOOL reloadFilterPanelWhenFinishSwitching;

@end

@implementation AWERecordFilterSwitchManager

- (void)dealloc
{
    if (_displayLink) {
        [_displayLink invalidate];
        _displayLink = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)addFilterSwitchGestureForViewController:(UIViewController *)controller
                                    filterArray:(NSArray *)filterArray
                            filterConfiguration:(AWECameraFilterConfiguration *)filterConfiguration
{
    self.targetController = controller;
    self.filterArray = filterArray;
    UIView *targetView = controller.view;
    self.panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panSwitchFilter:)];
    self.panGes.cancelsTouchesInView = NO;
    self.panGes.maximumNumberOfTouches = 1;
    self.panGes.delegate = self;
    [targetView addGestureRecognizer:self.panGes];
    self.filterConfiguration = filterConfiguration;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadFilterArrayIfNecessary) name:kAWEStudioColorFilterUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadFilterArrayIfNecessary) name:kAWEStudioColorFilterListUpdateNotification object:nil];
}

- (void)reloadFilterArrayIfNecessary
{
    if (self.isSwitchFilter) {
        self.reloadFilterPanelWhenFinishSwitching = YES;;
        return ;
    }
    [self reloadFilterArray];
}

- (void)reloadFilterArray
{
    [self.filterConfiguration updateFilterData];
    self.filterArray = self.filterConfiguration.filterArray;
}

- (void)setIsSwitchFilter:(BOOL)isSwitchFilter
{
    _isSwitchFilter = isSwitchFilter;
    if (!isSwitchFilter && self.reloadFilterPanelWhenFinishSwitching) {
        [self reloadFilterArray];
        self.reloadFilterPanelWhenFinishSwitching = NO;
    }
}

- (void)panSwitchFilter:(UIPanGestureRecognizer *)gestureRecognizer
{
    if (!self.delegate.enableFilterSwitch) {
        return;
    }
    UIView *panView = gestureRecognizer.view;
    CGPoint location = [gestureRecognizer locationInView:panView];
    if (!CGRectEqualToRect(self.gestureResponseArea,CGRectZero)) {
        if (location.x < self.gestureResponseArea.origin.x || location.x > self.gestureResponseArea.size.width ||
            location.y < self.gestureResponseArea.origin.y || location.y > self.gestureResponseArea.size.height) {
            return;
        }
    }

    double translationX = [gestureRecognizer translationInView:panView].x;
    double velocityX = [gestureRecognizer velocityInView:panView].x;
    double velocityY = [gestureRecognizer velocityInView:panView].y;
    
    if ([ACCRTL() isRTL]) {
        translationX = -translationX;
        velocityX = -velocityX;
    }
    
    // 滤镜切换进度
    __block CGFloat progressFilter = fabs(translationX) / CGRectGetWidth(panView.frame);
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            if (fabs(velocityY) <= fabs(velocityX)) { // 横向速度大，说明是要滑动滤镜
                self.isSwitchFilter = YES;

                // 确定往哪个方向切换滤镜
                // 1 表示新滤镜将从屏幕右边出现； -1 表示新滤镜将从屏幕左边出现
                self.switchFilterDirection = velocityX > 0 ? -1 : 1;

                if (self.switchFilterDirection == -1) {
                    self.switchToFilter = [AWEColorFilterDataManager prevFilterOfFilter:self.currentFilter filterArray:self.filterArray];
                } else {
                    self.switchToFilter = [AWEColorFilterDataManager nextFilterOfFilter:self.currentFilter filterArray:self.filterArray];
                }
            } else { // 纵向速度大，说明是要滑动音乐特效
                self.isSwitchFilter = NO;
            }
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            if (self.isSwitchFilter) {
                // 按进度调用切换滤镜的接口
                if ((translationX > 0 ? -1 : 1) == self.switchFilterDirection) {
                    IESEffectModel *leftModel = nil;
                    IESEffectModel *rightModel = nil;
                    CGFloat actualFilterProgress = progressFilter;
                    if (self.switchFilterDirection == 1) {
                        leftModel = self.currentFilter;
                        rightModel = self.switchToFilter;
                        actualFilterProgress = 1 - progressFilter;
                    } else {
                        leftModel = self.switchToFilter;
                        rightModel = self.currentFilter;
                    }
                    // 修正，防止滤镜出现一条细边
                    if (actualFilterProgress < 0.025) {
                        actualFilterProgress = 0;
                    }
                    if (actualFilterProgress > 1 - 0.025) {
                        actualFilterProgress = 1;
                    }
                    
                    [self.delegate switchFilterWithFilterOne:leftModel
                                                           FilterTwo:rightModel
                                                           direction:self.switchFilterDirection
                                                            progress:actualFilterProgress];
                    [self changeFilterRelatedUIWithProgress:progressFilter];
                }
            }
        }
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: //cancel调用同样的逻辑
        {
            if (self.isSwitchFilter) {
                BOOL isCompelete = (fabs(velocityX) > 500 && ((velocityX > 0 ? -1 : 1) == self.switchFilterDirection)) || (fabs(progressFilter) > 0.5 && (translationX > 0 ? -1 : 1) == self.switchFilterDirection);
                [self applyFilterWithBeginProgress:progressFilter isCompelete:isCompelete];
            }
        }
            break;
        default:
            break;
    }
}

- (void)applyFilterWithBeginProgress:(double)progress isCompelete:(BOOL)isCompelete
{
    [self applyFilterWithBeginProgress:progress isCompelete:isCompelete showFilterName:YES];
}

- (void)applyFilterWithBeginProgress:(double)progress isCompelete:(BOOL)isCompelete showFilterName:(BOOL)show
{
    if ((progress > 0.02 && !isCompelete) || (progress < 0.98 && isCompelete)){
        self.filterAniTiming = YES;
        self.isCompeleteWhenFilterAniBegin = isCompelete;
        self.autoRenderProgress = progress;
        self.panGes.enabled = NO;
        return;
    }

    self.filterAniTiming = NO;
    self.panGes.enabled = YES;

    if (isCompelete) {
        if ([self.delegate respondsToSelector:@selector(applyFilterWithFilterModel:type:)]) {
            [self.delegate applyFilterWithFilterModel:self.switchToFilter type:IESEffectFilter];
        }
        self.currentFilter = self.switchToFilter;
        self.isSwitchFilter = NO;
        [ACCTapticEngineManager tap];
    } else {
        if ([self.delegate respondsToSelector:@selector(applyFilterWithFilterModel:type:)]) {
            [self.delegate applyFilterWithFilterModel:self.currentFilter type:IESEffectFilter];
        }
        self.isSwitchFilter = NO;
    }
    ACCBLOCK_INVOKE(self.completionBlock, self.currentFilter);
}

- (void)renderOnMainLoop
{
    if (!self.filterAniTiming) {
        return;
    }

    if (self.isCompeleteWhenFilterAniBegin) {
        if (self.autoRenderProgress >= 0.98) {
            [self applyFilterWithBeginProgress:1.0 isCompelete:self.isCompeleteWhenFilterAniBegin];
        } else {
            self.autoRenderProgress += 0.045;
            if (self.autoRenderProgress >= 0.98) {
                self.autoRenderProgress = 1.0;
            }
            
            IESEffectModel *leftModel = nil;
            IESEffectModel *rightModel = nil;
            CGFloat actualFilterProgress = self.autoRenderProgress;
            if (self.switchFilterDirection == 1) {
                leftModel = self.currentFilter;
                rightModel = self.switchToFilter;
                actualFilterProgress = 1 - self.autoRenderProgress;
            } else {
                leftModel = self.switchToFilter;
                rightModel = self.currentFilter;
            }
            
            [self.delegate switchFilterWithFilterOne:leftModel
                                                   FilterTwo:rightModel
                                                   direction:self.switchFilterDirection
                                                    progress:actualFilterProgress];
            
            [self changeFilterRelatedUIWithProgress:self.autoRenderProgress];
        }
    } else {
        if (self.autoRenderProgress <= 0.02) {
            [self applyFilterWithBeginProgress:0.0 isCompelete:self.isCompeleteWhenFilterAniBegin];
        } else {
            self.autoRenderProgress -= 0.045;
            if (self.autoRenderProgress <= 0.02) {
                self.autoRenderProgress = 0.0;
            }
            IESEffectModel *leftModel = nil;
            IESEffectModel *rightModel = nil;
            CGFloat actualFilterProgress = self.autoRenderProgress;
            if (self.switchFilterDirection == 1) {
                leftModel = self.currentFilter;
                rightModel = self.switchToFilter;
                actualFilterProgress = 1 - self.autoRenderProgress;
            } else {
                leftModel = self.switchToFilter;
                rightModel = self.currentFilter;
            }

            [self.delegate switchFilterWithFilterOne:leftModel
                                                   FilterTwo:rightModel
                                                   direction:self.switchFilterDirection
                                                    progress:actualFilterProgress];
            [self changeFilterRelatedUIWithProgress:self.autoRenderProgress];
        }
    }
}

- (void)changeFilterRelatedUIWithProgress:(CGFloat)progress
{
    CGFloat displayProgress = progress;
    IESEffectModel *leftFilter = self.switchToFilter;
    IESEffectModel *rightFilter = self.currentFilter;
    if (self.switchFilterDirection > 0) {
        displayProgress = 1 - displayProgress;
        leftFilter = self.currentFilter;
        rightFilter =  self.switchToFilter;
    }
    ACCBLOCK_INVOKE(self.changeProgressBlock, leftFilter, rightFilter, displayProgress);
}

- (void)startSwitchDisplayLink
{
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }

    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(renderOnMainLoop)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)stopSwitchDisplayLink
{
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}


- (void)refreshCurrentFilterModelWithFilter:(IESEffectModel *)filter
{
    self.currentFilter = filter;
}

- (void)updatePanGestureEnabled:(BOOL)enabled
{
    self.panGes.enabled = enabled;
}

- (void)addPanGesExcludedView:(UIView *)exludedView
{
    if (exludedView == nil) {
        return;
    }
    if (!_panGesExcludeViews) {
        _panGesExcludeViews = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }
    [self.panGesExcludeViews addObject:exludedView];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer  == self.panGes && ![self.delegate switchFilterGestureShouldBegin]) {
        return NO;
    }
    if (self.currentFilter == nil) {
        return NO;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isKindOfClass:[AWESlider class]]) {
        return NO;
    }
    for (UIView *someView in self.panGesExcludeViews) {
        if ([touch.view isDescendantOfView:someView]) {
            return NO;
        }
    }
    return YES;
}

- (void)finishCurrentSwitchProcess
{
    if (self.panGes.state == UIGestureRecognizerStateBegan || self.panGes.state == UIGestureRecognizerStateChanged) {
        self.panGes.enabled = NO;
        [self applyFilterWithBeginProgress:self.autoRenderProgress >= 0.5 ? 1.f : 0.f isCompelete:self.autoRenderProgress >= 0.5 ? YES : NO showFilterName:NO];
    }
}

@end
