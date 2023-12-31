//
//  UIViewController+AWEDismissPresentVCStack.h
//  PresentDemo
//
//  Created by 郝一鹏 on 2017/7/11.
//  Copyright © 2017年 郝一鹏. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (AWEDismissPresentVCStack)

- (void)acc_dismissModalStackAnimated:(bool)animated completion:(void (^)(void))completion;
- (UIViewController *)acc_rootPresentingViewController;

@end

@interface UIViewController (AWEStuidoTag)

@property (nonatomic, assign) NSUInteger acc_stuioTag;

@end
