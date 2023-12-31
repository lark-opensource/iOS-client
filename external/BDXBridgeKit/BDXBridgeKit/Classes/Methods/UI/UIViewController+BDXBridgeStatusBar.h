//
//  UIViewController+BDXBridgeStatusBar.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/15.
//

#import <UIKit/UIKit.h>
#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@class BDXBridgeConfigureStatusBarMethodParamModel;

@interface UIViewController (BDXBridgeStatusBar)

@property (nonatomic, assign) BOOL bdx_statusBarHidden;
@property (nonatomic, assign) UIStatusBarStyle bdx_statusBarStyle;

- (void)bdx_configureStatusBarWithParamModel:(BDXBridgeConfigureStatusBarMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END
