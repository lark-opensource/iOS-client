//
//  IESGurdAPI.m
//  IESGurdKit
//
//  Created by willorfang on 2018/5/17.
//

#import "IESGeckoAPI.h"
#import "IESGeckoKit+Private.h"
#import "IESGurdConfig.h"
#import "IESGurdKit+Experiment.h"

NSString *IESGurdSettingsAPIVersion = @"v2";

@implementation IESGurdAPI

+ (NSString *)packagesInfo
{
    NSAssert([self platformDomain], @"IESGurdKit platformDomain should not be nil");
    return [NSString stringWithFormat:@"%@://%@/gkx/api/resource/v6", [self schema], [self platformDomain]];
}

+ (NSString *)polling
{
    NSAssert([self platformDomain], @"IESGurdKit platformDomain should not be nil");
    return [NSString stringWithFormat:@"%@://%@/gkx/api/combine/v3", [self schema], [self platformDomain]];
}

+ (NSString *)settings
{
    NSAssert([self platformDomain], @"IESGurdKit platformDomain should not be nil");
    return [NSString stringWithFormat:@"%@://%@/gkx/api/settings/%@", [self schema], [self platformDomain], IESGurdSettingsAPIVersion];
}

#pragma mark - Private

+ (NSString *)platformDomain
{
    return IESGurdKitInstance.domain ? : [IESGurdConfig platformDomain];
}

+ (NSString *)schema
{
    return IESGurdKitInstance.schema ? : @"https";
}


@end
