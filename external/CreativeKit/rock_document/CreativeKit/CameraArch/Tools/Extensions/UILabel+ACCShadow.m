//
//  UILabel+ACCShadow.m
//  CameraClient
//
//  Created by luochaojing on 2020/1/5.
//

#import "UILabel+ACCShadow.h"

@implementation UILabel (ACCShadow)

- (void)acc_showShadow {
    self.layer.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.5].CGColor;
    self.layer.shadowOffset = CGSizeZero;
    self.layer.shouldRasterize = YES;
    self.layer.shadowRadius = 1.0;
    self.layer.shadowOpacity = 1.0;
}

@end
