//
//  IESEffectModel+DStickerAddditions.m
//  CameraClient-Pods-CameraClient
//
//  Created by Howie He on 2021/3/22.
//

#import "IESEffectModel+DStickerAddditions.h"
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitInfra/NSString+ACCAdditions.h>

NSString * const AWEEffectTagIsDouyinCard = @"douyin_card";
NSString * const kACCEffectTagFlower = @"2021_flower";
NSString * const kACCEffectTagFlowerAudit = @"flower_test";

NSString * const kACCEffectTagGroot = @"groot";

@implementation IESEffectModel (DStickerAddditions)

- (BOOL)isDouyinCard
{
    return [self.tags containsObject:AWEEffectTagIsDouyinCard];
}

- (BOOL)karaokeBanned
{
    NSDictionary *extraJson = [self acc_analyzeSDKExtra];
    return extraJson[@"support_ktv"] != nil && ![extraJson acc_boolValueForKey:@"support_ktv"];
}

- (BOOL)forbidFavorite
{
    return [[self.extra acc_jsonValueDecoded] acc_boolValueForKey:@"forbid_favorite"];
}

- (BOOL)needReloadWhenApply
{
    NSDictionary *extraJson = [self acc_analyzeSDKExtra];
    return [extraJson acc_boolValueForKey:@"needReload"];
}

- (BOOL)isFlowerBooking
{
    return [self.pixaloopSDKExtra acc_boolValueForKey:@"isFlowerBooking"];
}

- (BOOL)isFlowerProp
{
    return [self.tags containsObject:kACCEffectTagFlower];
}

- (BOOL)isFlowerPropAduit
{
    return [self.tags containsObject:kACCEffectTagFlowerAudit];
}

- (BOOL)isGrootProp
{
    return [self.tags containsObject:kACCEffectTagGroot];
}

@end
