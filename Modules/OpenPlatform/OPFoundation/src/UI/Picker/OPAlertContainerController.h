//
//  OPAlertContainerController.h
//  EEMicroAppSDK
//  Created by yi on 2021/3/19.
//

#import <UIKit/UIKit.h>

@protocol OPAlertContentViewProtocol <NSObject>
- (void)showAlertInView:(UIView *)view;
@end

@interface OPAlertContainerController : UIViewController
@property (nonatomic, copy) void (^tapBackgroud)();   // 点击背景取消

- (void)updateAlertView:(UIView<OPAlertContentViewProtocol> *)view size:(CGSize)size;
- (void)dismissViewController;
- (void)dismissViewControllerWithAnimated: (BOOL)animated completion: (void (^ __nullable)(void))completion;
@end
