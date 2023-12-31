//
//  BDClientABManagerUtil.m
//  ABTest
//
//  Created by ZhangLeonardo on 16/1/24.
//  Copyright © 2016年 ZhangLeonardo. All rights reserved.
//

#import "BDClientABManagerUtil.h"
#import "BDClientABDefine.h"

extern const NSInteger kBDClientABTestMaxRegion;

@implementation BDClientABManagerUtil

+ (NSInteger)genARandomNumber
{
    int randomValue = arc4random() % (kBDClientABTestMaxRegion + 1);
    return randomValue;
}

+ (NSString *)appVersion
{
    NSString * version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    return version;
}

static NSString *abManager_channel_name = nil;

+ (NSString *)channelName
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        abManager_channel_name = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CHANNEL_NAME"];
    });
    return abManager_channel_name;
}

+ (NSString *)_rmSuffix:(NSString *)suffix forStr:(NSString *)str
{
    if (isEmptyString_forABManager(suffix) || isEmptyString_forABManager(str)) {
        return str;
    }
    NSString * result = str;
    while ([result hasSuffix:suffix]) {
        result = [result substringToIndex:[result length] - [suffix length]];
    }
    return result;
}

+ (BDClientABVersionCompareType)compareVersion:(NSString *)leftVersion toVersion:(NSString *)rightVersion
{
    leftVersion = [self _rmSuffix:@".0" forStr:leftVersion];
    rightVersion = [self _rmSuffix:@".0" forStr:rightVersion];
    
    if (isEmptyString_forABManager(leftVersion) || isEmptyString_forABManager(rightVersion)) {
        return BDClientABVersionCompareTypeEqualTo;
    }
    
    if ([leftVersion isEqualToString:rightVersion]) {
        return BDClientABVersionCompareTypeEqualTo;
    }
    
    NSArray<NSString *> * leftComponents = [leftVersion componentsSeparatedByString:@"."];
    NSArray<NSString *> * rightComponents = [rightVersion componentsSeparatedByString:@"."];
    
    for (int i = 0; i < MIN([leftComponents count], [rightComponents count]); i++) {
        NSInteger leftPart = 0;
        NSString *leftCompString = leftComponents[i];
        if (leftCompString && [leftCompString respondsToSelector:@selector(longLongValue)]) {
            leftPart = [leftComponents[i] longLongValue];
        }
        
        NSInteger rightPart = 0;
        NSString *rightCompString = rightComponents[i];
        if (rightCompString && [rightCompString respondsToSelector:@selector(longLongValue)]) {
            rightPart = [rightCompString longLongValue];
        }
        
        if (leftPart < rightPart) {
            return BDClientABVersionCompareTypeLessThan;
        }
        else if (leftPart > rightPart) {
            return BDClientABVersionCompareTypeGreateThan;
        }
        else { // equal
            continue;
        }
    }
    
    if ([leftComponents count] > [rightComponents count]) {
        return BDClientABVersionCompareTypeGreateThan;
    }
    else {
        return BDClientABVersionCompareTypeLessThan;
    }
}

@end
