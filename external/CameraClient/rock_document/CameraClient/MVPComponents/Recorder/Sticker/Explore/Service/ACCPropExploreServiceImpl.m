//
//  ACCPropExploreServiceImpl.m
//  CameraClient-Pods-AwemeCore
//
//  Created by wanghongyu on 2021/10/12.
//

#import "ACCPropExploreServiceImpl.h"
#import <CameraClient/ACCTransitioningDelegateProtocol.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CreationKitInfra/ACCResponder.h>
#import <CameraClient/AWEExploreStickerViewController.h>
#import <CreationKitRTProtocol/ACCCameraSubscription.h>

@interface ACCPropExploreServiceImpl()

@property (nonatomic, strong) AWEExploreStickerViewController *exploreVC;
@property (nonatomic, strong) id<UIViewControllerTransitioningDelegate, ACCInteractiveTransitionProtocol> transitionDelegate;

@property (nonatomic, assign) BOOL showingExploreVC;

@property (nonatomic, strong) ACCCameraSubscription *subscription;

@end

@implementation ACCPropExploreServiceImpl

- (void)showExplorePage {
    AWEExploreStickerViewController *exploreVC = [[AWEExploreStickerViewController alloc] init];
    exploreVC.serviceProvider = self.serviceProvider;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:exploreVC];
    navigationController.navigationBar.translucent = NO;
    navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
    navigationController.modalPresentationCapturesStatusBarAppearance = YES;
    
    [[ACCResponder topViewController] presentViewController:navigationController animated:YES completion:nil];
    
    self.exploreVC = exploreVC;
    
    [self.subscription performEventSelector:@selector(propExplorePageWillShow) realPerformer:^(id<ACCPropExploreServiceSubscriber> subscriber) {
        [subscriber propExplorePageWillShow];
    }];
    self.showingExploreVC = YES;
}

- (void)dismissExplorePage {
    [self.exploreVC dismissViewControllerAnimated:YES completion:nil];
    self.exploreVC = nil;
    self.showingExploreVC = NO;
}


- (BOOL)isShowing {
    return self.showingExploreVC;
}

#pragma mark - ACCCameraSubscription

- (ACCCameraSubscription *)subscription
{
    if (!_subscription) {
        _subscription = [[ACCCameraSubscription alloc] init];
    }
    return _subscription;
}

- (void)addSubscriber:(id<ACCPropExploreServiceSubscriber>)subscriber
{
    [self.subscription addSubscriber:subscriber];
}


@end
