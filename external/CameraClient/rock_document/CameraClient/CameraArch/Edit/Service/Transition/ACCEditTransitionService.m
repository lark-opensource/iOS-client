//
//  ACCEditTransitionService.m
//  Pods
//
//  Created by haoyipeng on 2020/8/6.
//

#import "ACCEditTransitionService.h"
#import "AWEBigToSmallModalDelegate.h"
#import <CreativeKit/ACCMacros.h>

@interface ACCEditTransitionService ()

@property (nonatomic, strong) AWEBigToSmallModalDelegate *bigToSmallModalTransitionDelegate;

@property (nonatomic, weak, readwrite) UIViewController<ACCEditTransitionContainerViewControllerProtocol> *containerViewController;
@property (nonatomic, strong) NSHashTable *observers;
@property (nonatomic, copy) NSString *previousPage;
@end

@implementation ACCEditTransitionService

@synthesize beforeTransitionSnapshotView = _beforeTransitionSnapshotView;
@synthesize avoidShowBgColorViewWhenDisapper = _avoidShowBgColorViewWhenDisapper;
@synthesize previousPage = _previousPage;

#pragma mark - ACCEditTransitionServiceProtocol

- (instancetype)initWithContainerViewController:(UIViewController<ACCEditTransitionContainerViewControllerProtocol> *)viewController
{
    self = [super init];
    if (self) {
        self.containerViewController = viewController;
        _observers = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }
    return self;
}

- (void)setPreviousPage:(nullable NSString *)page  {
    _previousPage = page;
}

- (void)registerObserver:(id<ACCEditTransitionServiceObserver>)observer
{
    NSAssert([observer conformsToProtocol:@protocol(ACCEditTransitionServiceObserver)], @"Observer: %@ not conform protocol <ACCEditTransitionServiceObserver>!", observer);
    if ([self.observers containsObject:observer]) {
        return;
    }
    if ([observer conformsToProtocol:@protocol(ACCEditTransitionServiceObserver)]) {
        [self.observers addObject:observer];
    }
}

- (void)unregisterObserver:(id<ACCEditTransitionServiceObserver>)observer
{
    NSAssert([observer conformsToProtocol:@protocol(ACCEditTransitionServiceObserver)], @"Observer: %@ not conform protocol <ACCEditTransitionServiceObserver>!", observer);
    [self.observers removeObject:observer];
}

- (void)presentViewController:(UIViewController *)controller completion:(void (^)(void))completion
{
    [self setPreviousPage:NSStringFromClass([controller class])];
    [self p_snapBeforeTransition];
    [self p_addAvoidShowBgColorViewWhenDisapper];
    [self notifyObserverWillPresentController:controller];
    controller.transitioningDelegate = self.bigToSmallModalTransitionDelegate;
    controller.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.containerViewController presentViewController:controller animated:YES completion:^{
        [self notifyObserverDidPresentController:controller];
        [self.avoidShowBgColorViewWhenDisapper removeFromSuperview];
        ACCBLOCK_INVOKE(completion);
    }];
    
}

- (void)dismissViewController:(UIViewController *)controller completion:(void (^ _Nullable)(void))completion
{
    if ([controller conformsToProtocol:@protocol(ACCEditTransitionViewControllerProtocol)] &&
        [controller respondsToSelector:@selector(dismissSnapImage)]) {
        UIImage *snapImage = [(UIViewController <ACCEditTransitionViewControllerProtocol> *)controller dismissSnapImage];
        self.containerViewController.view.backgroundColor = [UIColor colorWithPatternImage:snapImage];
    }

    [self notifyObserverWillDidmissController:controller];
    [controller dismissViewControllerAnimated:YES completion:^{
        [self notifyObserverDidDismissController:controller];
        self.containerViewController.view.backgroundColor = [UIColor blackColor];
        ACCBLOCK_INVOKE(completion);
    }];
}

#pragma mark - Observer Action

- (void)notifyObserverWillPresentController:(UIViewController *)controller
{
    for (id <ACCEditTransitionServiceObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(transitionService:willPresentViewController:)]) {
            [observer transitionService:self willPresentViewController:controller];
        }
    }
}

- (void)notifyObserverDidPresentController:(UIViewController *)controller
{
    for (id <ACCEditTransitionServiceObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(transitionService:didPresentViewController:)]) {
            [observer transitionService:self didPresentViewController:controller];
        }
    }
}

- (void)notifyObserverWillDidmissController:(UIViewController *)controller
{
    for (id <ACCEditTransitionServiceObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(transitionService:willDismissViewController:)]) {
            [observer transitionService:self willDismissViewController:controller];
        }
    }
}

- (void)notifyObserverDidDismissController:(UIViewController *)controller
{
    for (id <ACCEditTransitionServiceObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(transitionService:didDismissViewController:)]) {
            [observer transitionService:self didDismissViewController:controller];
        }
    }
}

#pragma mark - Private

- (void)p_snapBeforeTransition
{
    self.beforeTransitionSnapshotView = [self.containerViewController beforeTransitionSnapshotView];
}

- (void)p_addAvoidShowBgColorViewWhenDisapper
{
    UIView *avoidShowBgColorView = [self.containerViewController.view snapshotViewAfterScreenUpdates:NO];
    [self.containerViewController.view addSubview:avoidShowBgColorView];
    self.avoidShowBgColorViewWhenDisapper = avoidShowBgColorView;
}

#pragma mark - Getter

- (AWEBigToSmallModalDelegate *)bigToSmallModalTransitionDelegate
{
    if (!_bigToSmallModalTransitionDelegate) {
        _bigToSmallModalTransitionDelegate = [[AWEBigToSmallModalDelegate alloc] init];
    }
    return _bigToSmallModalTransitionDelegate;
}

@end
