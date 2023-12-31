//
//  ACCEditTransitionServiceProtocol.h
//  Pods
//
//  Created by haoyipeng on 2020/8/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCEditTransitionServiceProtocol;


@protocol ACCEditTransitionServiceObserver <NSObject>

@optional
- (void)transitionService:(id<ACCEditTransitionServiceProtocol>)transitionService willPresentViewController:(UIViewController *)viewController;
- (void)transitionService:(id<ACCEditTransitionServiceProtocol>)transitionService didPresentViewController:(UIViewController *)viewController;

- (void)transitionService:(id<ACCEditTransitionServiceProtocol>)transitionService willDismissViewController:(UIViewController *)viewController;
- (void)transitionService:(id<ACCEditTransitionServiceProtocol>)transitionService didDismissViewController:(UIViewController *)viewController;

@end

@protocol ACCEditTransitionViewControllerProtocol <NSObject>

@optional
- (UIImage *)dismissSnapImage;

@end

@protocol ACCEditTransitionContainerViewControllerProtocol <NSObject>

- (UIView *)beforeTransitionMediaSnapshotView;
- (UIView *)beforeTransitionSnapshotView;

@end

@protocol ACCEditTransitionServiceProtocol <NSObject>

@property (nonatomic, strong) UIView *beforeTransitionSnapshotView;
@property (nonatomic, strong) UIView *avoidShowBgColorViewWhenDisapper;
@property (nonatomic, copy, readonly) NSString *previousPage;

- (instancetype)initWithContainerViewController:(UIViewController<ACCEditTransitionContainerViewControllerProtocol> *)viewController;

- (void)setPreviousPage:(nullable NSString *)page;

- (void)registerObserver:(id<ACCEditTransitionServiceObserver>)observer;
- (void)unregisterObserver:(id<ACCEditTransitionServiceObserver>)observer;

- (void)presentViewController:(UIViewController *)controller completion:(void (^ _Nullable)(void))completion;
- (void)dismissViewController:(UIViewController *)controller completion:(void (^ _Nullable)(void))completion;


@end

NS_ASSUME_NONNULL_END
