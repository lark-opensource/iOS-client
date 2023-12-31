//
//  AWEStudioBaseViewController.h
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/4/13.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACCCameraClient.h"

typedef void(^AWEStudioBaseViewControllerLifeBlock)(BOOL animated);

@interface AWEStudioBaseViewController : UIViewController

@property (nonatomic, copy) AWEStudioBaseViewControllerLifeBlock willAppearBlock;
@property (nonatomic, copy) AWEStudioBaseViewControllerLifeBlock didAppearBlock;
@property (nonatomic, copy) AWEStudioBaseViewControllerLifeBlock willDisappearBlock;
@property (nonatomic, copy) AWEStudioBaseViewControllerLifeBlock didDisappearBlock;

@end
