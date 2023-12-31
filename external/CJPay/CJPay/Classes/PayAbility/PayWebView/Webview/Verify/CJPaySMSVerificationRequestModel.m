//
//  CJPaySMSVerificationRequestModel.m
//  CJPay
//
//  Created by liyu on 2020/7/12.
//

#import "CJPaySMSVerificationRequestModel.h"

@implementation CJPaySMSVerificationRequestModel


+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"titleText": @"title",
                @"phoneNumberText": @"mobile",
                @"qaURLString": @"qa_url",
                @"qaTitle": @"qa_title",
//                @"": @"back_button_icon",
                @"codeCount": @"number_of_inputs",
//                @"": @"animation_direction",
                @"countDownSeconds": @"timer",
                @"animationType": @"animation_direction",
                @"usesCloseButton": @"back_button_icon",
                @"identify": @"id",

            }];
}


+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (void)setAnimationTypeWithNSString:(NSString *)animationTypeString
{
    if ([animationTypeString isEqualToString:@"left"]) {
        _animationType = HalfVCEntranceTypeFromRight;
    } else {
        _animationType = HalfVCEntranceTypeFromBottom;
    }
}

- (void)setUsesCloseButtonWithNSString:(NSString *)backButtonIconString
{
    if ([backButtonIconString isEqualToString:@"close"]) {
        _usesCloseButton = YES;
    } else {
        _usesCloseButton = NO;
    }
}

@end
