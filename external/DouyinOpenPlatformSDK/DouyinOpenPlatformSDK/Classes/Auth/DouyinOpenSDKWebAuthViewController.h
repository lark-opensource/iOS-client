//
//  DouyinOpenSDKWebAuthViewController.h
//
//  Created by ByteDance on 18/9/2017.
//  Copyright (c) 2018年 ByteDance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DouyinOpenSDKAuth.h"

@interface DouyinOpenSDKWebAuthViewController :UIViewController

@property (nonatomic, strong) DouyinOpenSDKAuthRequest *req;
@property (nonatomic, copy) DouyinOpenSDKAuthCompleteBlock callBack;

- (void)reload;

@end

