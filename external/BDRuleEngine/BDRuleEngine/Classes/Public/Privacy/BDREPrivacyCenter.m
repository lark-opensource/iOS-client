//
//  BDREPrivacyCenter.m
//  BDAlogProtocol
//
//  Created by Chengmin Zhang on 2022/6/27.
//

#import "BDREPrivacyCenter.h"
#import "BDREPrivacyCommon.h"

@implementation BDREPrivacyCenter

+ (void)registerExtensions
{
    [BDREPrivacyCommon registerExtension];
}

+ (void)appWillEnterForeground
{
    [BDREPrivacyCommon appWillEnterForeground];
}

+ (void)appDidEnterBackground
{
    [BDREPrivacyCommon appDidEnterBackground];
}

@end
