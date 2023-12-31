//
//  ACCEditPageStrokeConfig.m
//  CameraClient-Pods-Aweme
//
//  Created by Fengfanhua.byte on 2020/5/26.
//

#import "ACCEditPageStrokeConfig.h"

@implementation ACCEditPageStrokeConfig


+ (instancetype)strokeWithWidth:(CGFloat)width color:(UIColor *)color lineJoin:(CGLineJoin)lineJoin
{
    ACCEditPageStrokeConfig *config = [ACCEditPageStrokeConfig new];
    config.width = width;
    config.color = color;
    config.lineJoin = lineJoin;
    return config;
}

@end
