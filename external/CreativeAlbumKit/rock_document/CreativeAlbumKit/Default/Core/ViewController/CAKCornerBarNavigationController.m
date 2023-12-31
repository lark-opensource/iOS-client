//
//  CAKCornerBarNavigationController.m
//  CreativeAlbumKit
//
//  Created by yuanchang on 2020/12/9.
//

#import "CAKCornerBarNavigationController.h"
#import "UIColor+AlbumKit.h"
#import "UIImage+CAKUIKit.h"

@interface UINavigationBar (CAKChangeBottomBorderColor)

- (void)cak_setBottomBorderColor:(UIColor *)color height:(CGFloat)height;

@end

@implementation UINavigationBar (CAKChangeBottomBorderColor)

- (void)cak_setBottomBorderColor:(UIColor *)color height:(CGFloat)height {
    CGRect bottomBorderRect = CGRectMake(0, CGRectGetHeight(self.frame), CGRectGetWidth(self.frame), height);
    UIView *bottomBorder = [[UIView alloc] initWithFrame:bottomBorderRect];
    [bottomBorder setBackgroundColor:color];
    [self addSubview:bottomBorder];
}

@end

@interface CAKCornerBarNavigationController ()

@end

@implementation CAKCornerBarNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationBar setValue:@(YES) forKey:@"hidesShadow"];
    [self.navigationBar cak_setBottomBorderColor:CAKResourceColor(ACCUIColorConstSDInverse) height:0.5];
    [self.navigationBar setBackgroundImage:[UIImage cak_imageWithColor:CAKResourceColor(ACCUIColorBGContainer) size:CGSizeMake(1, 1)]
                             forBarMetrics:UIBarMetricsDefault];
    [self.navigationBar setShadowImage:nil];
    [self.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:CAKResourceColor(ACCUIColorConstTintPrimary)}];
    [self.navigationBar setTintColor:CAKResourceColor(ACCUIColorBGContainer6)];

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

@end
