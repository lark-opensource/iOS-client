//
//  ACCStickerGestureComponent.m
//  Pods
//
//  Created by chengfei xiao on 2019/10/21.
//

#import "ACCStickerGestureComponent.h"
#import <QuartzCore/QuartzCore.h>
#import "ACCEditVideoFilterService.h"
#import <CreativeKit/ACCEditViewContainer.h>

@interface ACCStickerGestureComponent ()

@property (nonatomic, weak) id<ACCEditViewContainer> viewContainer;
@property (nonatomic, weak) id<ACCEditVideoFilterService> filterService;

@end

@implementation ACCStickerGestureComponent
@synthesize stickerGestureController = _stickerGestureController;

IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, filterService, ACCEditVideoFilterService)

- (void)loadComponentView {
    //editview
    if (self.viewContainer.containerView && !self.viewContainer.containerView.superview) {
        [self.controller.root.view addSubview:self.viewContainer.containerView];
    }
    //gesture view
    if (!self.stickerGestureController.view.superview) {
        [self.viewContainer.gestureView addSubview:self.stickerGestureController.view];
    }
}

- (void)componentDidMount
{
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase {
    return ACCFeatureComponentLoadPhaseEager;
}

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCStickerGestureComponentProtocol), self);
}

#pragma mark - ACCStickerGestureComponentProtocol

- (AWEEditorStickerGestureViewController *)stickerGestureController
{
    if (!_stickerGestureController) {
        _stickerGestureController = [[AWEEditorStickerGestureViewController alloc] init];
    }
    
    return _stickerGestureController;
}

- (void)startNewStickerPanOperation
{
    if (self.viewContainer.containerView.alpha == 0) {
        return;
    }
    [[self filterService].filterSwitchManager updatePanGestureEnabled:NO];
    
    [self.viewContainer.containerView.layer removeAllAnimations];
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.viewContainer.containerView.alpha = 0;
    } completion:^(BOOL finished) {}];
}

- (void)finishNewStickerPanOperation
{
    [[self filterService].filterSwitchManager updatePanGestureEnabled:YES];
    
    [self.viewContainer.containerView.layer removeAllAnimations];
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.viewContainer.containerView.alpha = 1;
    } completion:^(BOOL finished) {}];
}

- (void)startPanOperation
{
    if (self.viewContainer.containerView.alpha == 0) {
        return;
    }
    [[self filterService].filterSwitchManager updatePanGestureEnabled:NO];
    
    [self.viewContainer.containerView.layer removeAllAnimations];
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.viewContainer.containerView.alpha = 0;
    } completion:^(BOOL finished) {}];
}

- (void)finishPanOperation
{
    [[self filterService].filterSwitchManager updatePanGestureEnabled:YES];
    
    [self.viewContainer.containerView.layer removeAllAnimations];
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.viewContainer.containerView.alpha = 1;
    } completion:^(BOOL finished) {}];
}

@end
