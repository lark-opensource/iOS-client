//
//  ACCFilterEffectItem.m
//  CameraClient-Pods-Aweme
//
//  Created by zhangyuanming on 2020/9/11.
//

#import "ACCFilterEffectItem.h"

@implementation ACCFilterEffectItem


+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"maxPercent": @"max",
             @"minPercent": @"min",
             @"defaultPercent": @"value",
             @"tag": @"tag",
             @"name": @"name"
             };
}

- (float)defaultIntensity {
    /* Rules for calculating the true intensity of a filter
    maximum value = maximum effect parameter * 100.
    Default value = Default parameter / Maximum effect parameter * 100
    Maximum effect value cannot be greater than 1, greater than 1 takes 1
     */
    CGFloat calculateValue = ((self.maxPercent - self.minPercent) * self.defaultPercent / 100.0 + self.minPercent) / 100.0;
    return calculateValue;
}

@end
