//
//  ACCCornerBarNaviController.m
//  Aweme
//
//  Created by 郝一鹏 on 2017/3/23.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import "UINavigationBar+ACCChangeBottonBorderColor.h"
#import "ACCCornerBarNaviController.h"
#import <CreativeKit/UIColor+CameraClientResource.h>
#import "UIImage+ACCUIKit.h"

@interface ACCCornerBarNaviController ()

@end

@implementation ACCCornerBarNaviController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationBar setValue:@(YES) forKey:@"hidesShadow"];
    [self.navigationBar setBottomBorderColor:ACCResourceColor(ACCUIColorConstSDInverse) height:0.5];
    [self.navigationBar setBackgroundImage:[UIImage acc_imageWithColor:ACCResourceColor(ACCUIColorBGContainer) size:CGSizeMake(1, 1)]
                             forBarMetrics:UIBarMetricsDefault];
    [self.navigationBar setShadowImage:nil];
    [self.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:ACCResourceColor(ACCUIColorConstTintPrimary)}];
    [self.navigationBar setTintColor:ACCResourceColor(ACCUIColorBGContainer6)];

    [self buildShapeLayer];
}

- (void)buildShapeLayer {
    if ([UIDevice currentDevice].systemVersion.floatValue >= 9.0) {
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.view.bounds byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(10, 10)].CGPath;
        self.view.layer.mask = shapeLayer;
    }
}

- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    [self buildShapeLayer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
