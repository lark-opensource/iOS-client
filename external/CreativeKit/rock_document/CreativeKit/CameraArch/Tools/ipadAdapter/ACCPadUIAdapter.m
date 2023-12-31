//
//  ACCPadUIAdapter.m
//  AWEAuth
//
//  Created by Shuang on 2022/3/23.
//

#import "ACCPadUIAdapter.h"

@implementation ACCPadUIAdapter

static CGFloat ACC_iPadScreenWidth = 0.f;
static CGFloat ACC_iPadScreenHeight = 0.f;

+ (CGFloat)iPadScreenWidth
{
    return ACC_iPadScreenWidth;
}

+ (void)setIPadScreenWidth:(CGFloat)width
{
    ACC_iPadScreenWidth = width;
}

+ (CGFloat)iPadScreenHeight
{
    return ACC_iPadScreenHeight;
}

+ (void)setIPadScreenHeight:(CGFloat)height
{
    ACC_iPadScreenHeight = height;
}

@end
