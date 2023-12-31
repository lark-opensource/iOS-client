//
//  ACCViewController.h
//  CameraClient
//
//  Created by Liu Deping on 2020/7/10.
//

#import <UIKit/UIKit.h>
#import "ACCComponentManager.h"
#import "ACCBusinessConfiguration.h"
#import "ACCUIViewControllerProtocol.h"
#import "ACCRouterService.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCViewController <ACCUIViewControllerProtocol>

@property (nonatomic, assign) BOOL routerAnimated;

- (void)popSelf;
- (nullable id)handleTargetViewControllerInputData;
- (void)prepareForLoadComponent;
- (void)beforeLoadBeforeFirstRenderComponent;
- (void)beforeLoadEagerComponent;
- (void)beforeLoadLazyComponent;
- (NSTimeInterval)loadPageUICost;
- (id<ACCComponentManager>_Nonnull)creatComponentManager;
@end


@interface ACCViewController : UIViewController <ACCViewController, ACCComponentController, ACCRouterService, ACCComponentManagerLoadPhaseDelegate>

- (instancetype)initWithBusinessConfiguration:(id<ACCBusinessConfiguration>)business;

@property (nonatomic, strong, readonly) id inputData;
@property (nonatomic, strong, readonly) id<IESServiceProvider> serviveProvider;
@property (nonatomic, strong, readonly) id<ACCComponentManager> componentManager;

@end

NS_ASSUME_NONNULL_END
