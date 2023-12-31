//
//  BDTuringPresentView.h
//  BDTuring
//
//  Created by bob on 2019/8/28.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDTuringPresentView : UIWindow

@property (nonatomic, strong, readonly) NSMutableSet<UIView *> *presentingViews;
@property (nonatomic, strong, readonly) NSMutableSet<UIViewController *> *presentingViewControllers;

+ (instancetype)defaultPresentView;

- (void)presentVerifyView:(UIView *)verifyView;
- (void)hideVerifyView:(UIView *)verifyView;
- (void)dismissVerifyView;

- (void)presentTwiceVerifyViewController:(UIViewController *)twiceVerifyViewController;
- (void)hideTwiceVerifyViewController:(UIViewController *)twiceVerifyViewController;

@end

NS_ASSUME_NONNULL_END
