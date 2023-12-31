//
//  ADFeelGoodURLConfig.m
//  FeelGoodDemo
//
//  Created by bytedance on 2020/8/26.
//  Copyright © 2020 huangyuanqing. All rights reserved.
//

#import "ADFeelGoodURLConfig.h"
#import "ADFeelGoodParamKeysDefine.h"

// 测试联调页面
//NSString * const ADFGBaseURLCN = @"https://ttdj2k.web.bytedance.net/";
// 正式页面
NSString * const ADFGBaseURLCN = @"https://survey.feelgood.cn/embed-survey";
NSString * const ADFGBaseURLVA = @"https://ads.tiktok.com/athena/survey/embed-survey";

NSString * const ADFGCheckURLCN = @"https://api.feelgood.cn/athena/survey/platform/action/report/";
NSString * const ADFGCheckURLVA = @"https://feelgood-api.tiktok.com/athena/survey/platform/action/report/";

NSString * const ADFGHeaderOriginURLCN = @"https://api.feelgood.cn";
NSString * const ADFGHeaderOriginURLVA = @"https://ads.tiktok.com";

@implementation ADFeelGoodURLConfig
+ (nonnull NSString *)baseURLWithChannel:(nonnull NSString *)channel{
    if([channel isEqualToString:ADFGChannelVA]){
        return ADFGBaseURLVA;
    }
    return ADFGBaseURLCN;
}

+ (nonnull NSString *)checkURLWithChannel:(nonnull NSString *)channel{
    if([channel isEqualToString:ADFGChannelVA]){
        return ADFGCheckURLVA;
    }
    
    return ADFGCheckURLCN;
}

+ (nonnull NSString *)headerOriginURLWithChannel:(nonnull NSString *)channel{
    if([channel isEqualToString:ADFGChannelVA]){
        return ADFGHeaderOriginURLVA;
    }
    
    return ADFGHeaderOriginURLCN;
}
@end
