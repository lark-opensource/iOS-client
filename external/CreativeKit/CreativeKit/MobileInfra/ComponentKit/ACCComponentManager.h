//
//  ACCComponentManager.h
//  Pods
//
//  Created by DING Leo on 2020/2/6.
//

#import <Foundation/Foundation.h>
#import "ACCFeatureComponent.h"
#import "ACCComponentLogDelegate.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ACCComponentMountState) {
    ACCComponentMountStateMounted,
    ACCComponentMountStateUnmounting,
    ACCComponentMountStateUnmounted,
};

typedef NS_ENUM(NSUInteger, ACCComponentViewState) {
    ACCComponentViewStateUnkown,
    ACCComponentViewStateAppearing,
    ACCComponentViewStateAppeared,
    ACCComponentViewStateDisappearing,
    ACCComponentViewStateDisappeared
};

NS_INLINE BOOL ACCMountStateIsUnmounted(ACCComponentMountState mountState) {
    return mountState == ACCComponentMountStateUnmounted;
}

NS_INLINE BOOL ACCMountStateIsUnavailable(ACCComponentMountState mountState) {
    return mountState != ACCComponentMountStateMounted;
}

@protocol ACCComponentManager;

@protocol ACCComponentManagerLoadPhaseDelegate <NSObject>

- (void)componentManager:(id <ACCComponentManager>)manager willLoadPhase:(ACCFeatureComponentLoadPhase)phase;

@end

@protocol ACCComponentManager <NSObject>

- (void)addComponent:(id<ACCFeatureComponent>)component;

// Bind the object's life with the component, so that when the component deallocated, the object could also be released.
- (void)bindLife:(id)object with:(id<ACCFeatureComponent>)component;

- (void)prepareForViewDidLoad;

- (void)prepareForWillAppear;

- (void)prepareForDidAppear;

- (void)prepareForWillDisappear;

- (void)prepareForDidDisappear;

- (void)prepareForWillLayoutSubviews;

- (void)prepareForDidLayoutSubviews;

- (void)prepareForViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator;

- (void)prepareForUnmount;

- (void)unmountComponents;

- (void)prepareForReceiveMemoryWarning;

- (void)registerMountCompletion:(dispatch_block_t)completion;

- (void)registerLoadViewCompletion:(dispatch_block_t)completion;

@property (nonatomic, weak) id<ACCComponentLogDelegate> delegate;

@property (nonatomic, weak) id<ACCComponentManagerLoadPhaseDelegate> loadPhaseDelegate;

@optional

- (void)loadComponentsView;

- (void)finishFirstRenderTask;

- (void)forceLoadComponentsWhenInteracting;

@end

@interface ACCComponentManager : NSObject <ACCComponentManager>

@end

NS_ASSUME_NONNULL_END

