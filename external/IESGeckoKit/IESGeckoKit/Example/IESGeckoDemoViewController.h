//
//  IESGeckoDemoViewController.h
//  IESGeckoKit_Example
//
//  Created by 陈煜钏 on 2020/7/16.
//  Copyright © 2020 Fang Wei. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol IESGeckoDemoViewControllerDelegate <NSObject>

- (void)showDebugPageWithNavigationController:(UINavigationController *)navigationController;

- (void)showAquamanPageWithNavigationController:(UINavigationController *)navigationController;;

- (void)showGDMPage;

@end

@interface IESGeckoDemoViewController : UIViewController

@property (nonatomic, weak) id<IESGeckoDemoViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
