//
//  BytedCertManager+AliyunPrivate.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2022/3/14.
//

#import "BytedCertManager+AliyunPrivate.h"
#import <AliyunIdentityManager/AliyunIdentityPublicApi.h>


@implementation BytedCertManager (AliyunPrivate)

+ (void)p_initAliyunSDK {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [AliyunSdk init];
    });
}

+ (NSString *)p_aliyunSDKVersion {
    return [AliyunIdentityManager version];
}

+ (NSDictionary *)p_aliyunMetaInfo {
    [self p_initAliyunSDK];
    return [AliyunIdentityManager getMetaInfo];
}

@end
