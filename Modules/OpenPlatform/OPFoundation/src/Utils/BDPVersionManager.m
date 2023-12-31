//
//  BDPVersionManager.m
//  Timor
//
//  Created by muhuai on 2018/2/7.
//  Copyright © 2018年 muhuai. All rights reserved.
//

#import "BDPVersionManager.h"
#import "BDPTimorClient.h"
#import <OPFoundation/OPFoundation-Swift.h>
#import <ECOInfra/BDPLog.h>
#import "OPResolveDependenceUtil.h"

// FROM: BDPVersionManagerV2.m 
NSString * const kLocalTMASwitchKeyV2 = @"TMAkLocalTMASwitchKey";

@implementation BDPVersionManager

// 解耦：新增versionManagerPlugin 用于获取 BDPVersionManagerDelegate 的implement BDPVersionManagerV2
+ (Class<BDPVersionManagerDelegate>)versionManagerPlugin {
    Class<BDPVersionManagerDelegate> versionManagerClass = [OPResolveDependenceUtil versionManagerClass];
    return versionManagerClass;
}

+ (BOOL)localTestEnable
{
    return [[self versionManagerPlugin] localTestEnable];
}

+ (void)setLocalTestEnable:(BOOL)localTestEnable
{
    [[self versionManagerPlugin] setLocalTestEnable:localTestEnable];
}

+ (void)downloadLibWithURL:(NSString *)url
             updateVersion:(NSString *)updateVersion
               baseVersion:(NSString *)baseVersion
                  greyHash:(NSString *)greyHash
                   appType:(OPAppType)appType
                completion:(void (^)(BOOL, NSString *))completion
{
    [[self versionManagerPlugin] downloadLibWithURL:url updateVersion:updateVersion baseVersion:baseVersion greyHash:greyHash appType:appType completion:completion];
}

+ (void)updateLibComplete:(BOOL)isSuccess
{
    [[self versionManagerPlugin] updateLibComplete:isSuccess];
}

+ (BOOL)isNeedUpdateLib:(NSString *)version greyHash:(NSString *)greyHash appType:(OPAppType)appType
{
    return [[self versionManagerPlugin] isNeedUpdateLib:version greyHash:greyHash appType:appType];
}

+ (BOOL)isLocalSdkLowerThanVersion:(NSString *)version
{
    return [[self versionManagerPlugin] isLocalSdkLowerThanVersion:version];
}

+ (BOOL)isLocalLarkVersionLowerThanVersion:(nullable NSString *)minLarkVersion {
    return [[self versionManagerPlugin] isLocalLarkVersionLowerThanVersion:minLarkVersion];
}

+ (BOOL)isValidLarkVersion:(nullable NSString *)larkVersion {
    return [[self versionManagerPlugin] isValidLarkVersion:larkVersion];
}

+ (NSString *)localLarkVersion {
    return [[self versionManagerPlugin] localLarkVersion];
}

+ (NSString *)versionCorrect:(nullable NSString *)version {
    return [[self versionManagerPlugin] versionCorrect:version];
}

+ (BOOL)isValidLocalLarkVersion {
    return [[self versionManagerPlugin] isValidLocalLarkVersion];
}

+ (void)setupBundleVersionIfNeed:(OPAppType)appType
{
    [[self versionManagerPlugin] setupBundleVersionIfNeed:appType];
}

+ (void)setupDefaultVersionIfNeed
{
    [[self versionManagerPlugin] setupDefaultVersionIfNeed];
}

+ (BOOL)serviceEnabled
{
    return [[self versionManagerPlugin] serviceEnabled];
}

+ (void)resetLocalLibVersionCache:(OPAppType)appType
{
    [[self versionManagerPlugin] resetLocalLibVersionCache:appType];
}

+ (void)resetLocalLibCache {
    [[self versionManagerPlugin] resetLocalLibCache];
}

+ (long long)localLibVersion
{
    return [[self versionManagerPlugin] localLibVersion];
}

+ (NSString * _Nullable)localLibVersionString;
{
    return [[self versionManagerPlugin] localLibVersionString];
}

+ (NSString *)localLibVersionString:(OPAppType)appType
{
    return [[self versionManagerPlugin] localLibVersionString:appType];
}

+ (NSString * _Nullable)localLibGreyHash {
    return [[self versionManagerPlugin] localLibGreyHash];
}

+ (NSString * _Nullable)localLibGreyHash:(OPAppType)appType {
    return [[self versionManagerPlugin] localLibGreyHash:appType];
}

+ (long long)localLibBaseVersion
{
    return [[self versionManagerPlugin] localLibBaseVersion];
}

+ (NSString *)localLibBaseVersionString
{
    return [[self versionManagerPlugin] localLibBaseVersionString];
}

+ (long long)localSDKVersion
{
    return [[self versionManagerPlugin] localSDKVersion];
}

+ (NSString *)localSDKVersionString
{
    return [[self versionManagerPlugin] localSDKVersionString];
}

+ (NSInteger)iosVersion2Int:(NSString *)str
{
    return [[self versionManagerPlugin] iosVersion2Int:str];
}

+(NSInteger)compareVersion:(NSString * _Nullable)unsafeV1 with:(NSString * _Nullable)unsafeV2
{
    return [[self versionManagerPlugin] compareVersion:unsafeV1 with:unsafeV2];
}

+(NSString *)returnLargerVersion:(NSString * _Nullable)v1 with:(NSString * _Nullable)v2
{
    return [[self versionManagerPlugin] returnLargerVersion:v1 with:v2];
}

+ (NSString *)versionStringWithContent:(NSString *)content
{
    return [[self versionManagerPlugin] versionStringWithContent:content];
}

+ (void)eventV3WithLibEvent:(NSString *)event
                       from:(NSString *)from
              latestVersion:(NSString *)latestVersion
             latestGreyHash:(NSString *)greyHash
                 resultType:(NSString *)resultTypes
                     errMsg:(NSString *)errMsg
                   duration:(NSUInteger)duration
                    appType:(OPAppType)appType
{
    [[self versionManagerPlugin] eventV3WithLibEvent:event from:from latestVersion:latestVersion latestGreyHash:greyHash resultType:resultTypes errMsg:errMsg duration:duration appType:appType];
}

@end
