//
//  ACCComponentController.h
//  Pods
//
//  Created by DING Leo on 2020/2/5.
//

#import <Foundation/Foundation.h>
@class ACCViewModelContainer;
@protocol ACCComponentManager;
NS_ASSUME_NONNULL_BEGIN

@protocol ACCComponentController <NSObject>

- (UIViewController *)root; // temporary substitute ComponentBus.rootViewController
- (ACCViewModelContainer *)viewModelContainer;
- (id <ACCComponentManager>)componentManager;

- (void)close;

- (void)controllerTaskFinished;

@optional

- (id)getViewModel:(Class)clazz;

- (BOOL)enableFirstRenderOptimize;

@end

NS_ASSUME_NONNULL_END
