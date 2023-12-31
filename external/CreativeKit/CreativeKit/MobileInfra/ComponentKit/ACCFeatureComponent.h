//
//  ACCFeatureComponent.h
//  Pods
//
//  Created by leo on 2020/2/5.
//

#import <Foundation/Foundation.h>
#import "ACCComponentController.h"
#import "ACCViewModelFactory.h"
#import "ACCComponentViewModelProvider.h"
#import "ACCServiceBinding.h"
#import <IESInject/IESInject.h>
#import "ACCServiceBindable.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, ACCFeatureComponentLoadPhase) {
    ACCFeatureComponentLoadPhaseLazy = 1 << 0,
    ACCFeatureComponentLoadPhaseEager = 1 << 1,
    ACCFeatureComponentLoadPhaseBeforeFirstRender = 1 << 2,
};

@protocol ACCFeatureComponent <NSObject>

@optional
@property (nonatomic, assign, getter=isMounted) BOOL mounted;
- (void)loadComponentView;
- (void)componentDidMount;
- (void)componentWillAppear;
- (void)componentDidAppear;
- (void)componentWillDisappear;
- (void)componentDidDisappear;
- (void)componentWillUnmount;
- (void)componentDidUnmount;
- (void)componentWillLayoutSubviews;
- (void)componentDidLayoutSubviews;
- (void)componentReceiveMemoryWarning;
- (void)componentWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator;
- (ACCFeatureComponentLoadPhase)preferredLoadPhase;

- (Class)componentViewModelClass;
- (void)bindViewModel;

- (ACCServiceBinding *)serviceBinding;
- (NSArray<ACCServiceBinding *> *)serviceBindingArray;

@end

@class AWEVideoPublishViewModel;

@interface ACCFeatureComponent : NSObject <ACCFeatureComponent, ACCComponentViewModelProvider, ACCServiceBindable>

@property (nonatomic, weak, readonly) id<ACCComponentController> controller;
@property (nonatomic, weak, readonly) id<ACCViewModelFactory> modelFactory;
@property (nonatomic, weak, readonly) id<IESServiceProvider> serviceProvider;
@property (nonatomic, weak, readonly) AWEVideoPublishViewModel *repository;

- (instancetype)initWithContext:(id<IESServiceProvider>)context NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
