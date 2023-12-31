//
//  ACCRouterCoordinatorProtocol.h
//  Pods
//
//  Created by songxiangwu on 2019/7/26.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCRouterCoordinatorProtocol <NSObject>

@property (nonatomic, weak) UIViewController *sourceViewController;
@property (nonatomic, strong) id _Nullable sourceViewControllerInputData;

@property (nonatomic, strong) id _Nullable targetViewControllerInputData;

- (instancetype)initWithSourceViewController:(UIViewController *)sourceViewController targetViewControllerInputData:(id _Nullable)targetViewControllerInputData;

- (id)handleTargetViewControllerInputData;
- (void)routeWithAnimated:(BOOL)animated completion:(void(^ _Nullable)(void))completion;

@end

NS_ASSUME_NONNULL_END
