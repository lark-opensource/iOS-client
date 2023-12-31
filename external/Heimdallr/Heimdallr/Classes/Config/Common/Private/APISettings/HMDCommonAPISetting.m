//
//  HMDCommonAPISetting.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/5/23.
//

#import "HMDCommonAPISetting.h"
#import "NSObject+HMDAttributes.h"

@implementation HMDCommonAPISetting

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP(hosts, hosts)
        HMD_ATTR_MAP_DEFAULT(enableEncrypt, enable_encrypt, @(YES), @(YES))
    };
}

@end
