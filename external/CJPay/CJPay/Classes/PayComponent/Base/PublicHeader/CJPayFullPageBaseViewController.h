//
//  CJPayFullPageBaseViewController.h
//  AFNetworking
//
//  Created by jiangzhongping on 2018/8/17.
//

#import <UIKit/UIKit.h>

#import "CJPayBaseViewController.h"

@interface CJPayFullPageBaseViewController : CJPayBaseViewController

@property (nonatomic, assign) BOOL isShowErrorView;

- (CGFloat)navigationHeight;

- (UIStatusBarStyle)cjpay_preferredStatusBarStyle;

- (void)adapterIpad;

- (void)closeWithCompletionBlock:(void(^ _Nullable)(void))completionBlock;

@end
