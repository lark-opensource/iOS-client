//
//  ACCRepoRedPacketModel.m
//  CameraClient-Pods-Aweme
//
//  Created by Howie He on 2020/11/3.
//

#import "ACCRepoRedPacketModel.h"
#import <objc/runtime.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCMacros.h>
#import "ACCFlowerRedPacketHelperProtocol.h"

@implementation ACCFlowerRedPacketInfo

- (instancetype)initWithCreationID:(NSString *)creationID
{
    if (self = [super init]) {
        _uniqueCreationID = [creationID copy];
    }
    return self;
}

- (void)rebuildCreationID
{
    _uniqueCreationID = [[NSUUID UUID] UUIDString];
}

- (ACCFlowerRedPacketAssetType)currentAssetType
{
    if (!ACC_isEmptyString(self.cashRedPacketId)) {
        return ACCFlowerRedPacketAssetTypeCashPay;
    } else if (!ACC_isEmptyString(self.couponId)) {
        return ACCFlowerRedPacketAssetTypeCoupon;
    } else {
        return ACCFlowerRedPacketAssetTypeNone;
    }
}

- (NSString *)outOrderId
{
    if (self.currentAssetType == ACCFlowerRedPacketAssetTypeCashPay) {
        return self.cashOutOrderId;
    } else if (self.currentAssetType == ACCFlowerRedPacketAssetTypeCoupon) {
        return self.uniqueCreationID;
    }
    return nil;
}

@end


@implementation ACCRepoRedPacketModel

- (nonnull id)copyWithZone:(nullable NSZone *)zone
{
    ACCRepoRedPacketModel *model = [[ACCRepoRedPacketModel allocWithZone:zone] init];
    model.redPacketInfo = [self.redPacketInfo copy];
    model.routerCouponId = self.routerCouponId;
    model.didClearedRedpacketInfoOnce = self.didClearedRedpacketInfoOnce;
    model.skipRedpacketCheckWhenBackupPublishFlag = self.skipRedpacketCheckWhenBackupPublishFlag;
    model.needHandleRebuildCreationIDFlag = self.needHandleRebuildCreationIDFlag;
    return model;
}

- (BOOL)didBindRedpacketInfo
{
    return (self.redPacketInfo &&
            self.redPacketInfo.currentAssetType != ACCFlowerRedPacketAssetTypeNone);
}

- (BOOL)isBindCashRedpacketInfo
{
    return self.didBindRedpacketInfo && self.redPacketInfo.currentAssetType == ACCFlowerRedPacketAssetTypeCashPay;
}

- (void)clearRedPacketInfo
{
    if (self.didBindRedpacketInfo) {
        self.didClearedRedpacketInfoOnce = YES;
    }
    self.redPacketInfo.couponId        = nil;
    self.redPacketInfo.couponOrderId   = nil;
    self.redPacketInfo.couponCount     = 0;
    self.redPacketInfo.cashRedPacketId = nil;
    self.redPacketInfo.cashPacketExtra = nil;
    self.redPacketInfo.cashOutOrderId  = nil;
}

- (void)rebuildCreationID
{
    [self.redPacketInfo rebuildCreationID];
    self.needHandleRebuildCreationIDFlag = YES;
}

#pragma mark - ACCRepositoryRequestParamsProtocol - Optional

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    if (!([self didBindRedpacketInfo] && [self didSendAnyRedpacket])) {
        return @{};
    }
    
    if (![ACCFlowerRedPacketHelper() isFlowerRedPacketActivityOn]) {
        return @{};
    }
    
    ACCFlowerRedPacketInfo *redPacketInfo = publishViewModel.repoRedPacket.redPacketInfo;
    
    if (ACC_isEmptyString(redPacketInfo.outOrderId)) {
        NSAssert(NO, @"check");
        return @{};
    }
    
    NSDictionary *redPacketInfoDic = nil;
    
    if (redPacketInfo.currentAssetType == ACCFlowerRedPacketAssetTypeCoupon &&
        !ACC_isEmptyString(redPacketInfo.couponOrderId)) {
        
        redPacketInfoDic =  @{
            @"video_red_packet_order_id" : redPacketInfo.outOrderId?:@"",
            @"video_red_packet_id" : redPacketInfo.couponOrderId?:@"",
            @"video_red_packet_type" : @(1),
            @"coupon_id" : redPacketInfo.couponId?:@""
        };
        
    } else if (redPacketInfo.currentAssetType == ACCFlowerRedPacketAssetTypeCashPay &&
               !ACC_isEmptyString(redPacketInfo.cashRedPacketId)) {
        
        redPacketInfoDic =  @{
            @"video_red_packet_order_id" : redPacketInfo.outOrderId?:@"",
            @"video_red_packet_id" : redPacketInfo.cashRedPacketId?:@"",
            @"video_red_packet_type" : @(0),
            @"extra" : redPacketInfo.cashPacketExtra?:@""
        };
    }
    
    if (!ACC_isEmptyDictionary(redPacketInfoDic)) {
        NSString *redPacketInfoDicJsonString = [redPacketInfoDic acc_safeJsonStringEncoded];
        if (!ACC_isEmptyString(redPacketInfoDicJsonString)) {
            return @{
                @"video_red_packet_info" : redPacketInfoDicJsonString?:@""
            };
        }
    }
    
    return @{};
}


- (NSDictionary *)acc_publishTrackEventParams:(AWEVideoPublishViewModel *)publishViewModel
{
    return [publishViewModel.repoRedPacket trackInfo];
}

- (NSDictionary *)trackInfo
{
    ACCFlowerRedPacketAssetType assetType = self.redPacketInfo.currentAssetType;
    
    if (assetType == ACCFlowerRedPacketAssetTypeCoupon) {
        return @{@"redpacket_type":@"coupon"};
    } else if (assetType == ACCFlowerRedPacketAssetTypeCashPay) {
        return @{@"redpacket_type":@"lucky"};
    }
    return nil;
}

- (BOOL)didSendAnyRedpacket
{
    if (![self didBindRedpacketInfo]){
        return NO;
    }
    if (self.redPacketInfo.currentAssetType == ACCFlowerRedPacketAssetTypeCashPay) {
        return !ACC_isEmptyString(self.redPacketInfo.cashRedPacketId);
    } else if (self.redPacketInfo.currentAssetType == ACCFlowerRedPacketAssetTypeCoupon) {
        return !ACC_isEmptyString(self.redPacketInfo.couponOrderId);
    }
    return NO;
}

@end

@implementation AWEVideoPublishViewModel (RepoRedPacket)

- (ACCRepoRedPacketModel *)repoRedPacket
{
    ACCRepoRedPacketModel *ret =  [self extensionModelOfClass:[ACCRepoRedPacketModel class]];
    NSParameterAssert(ret != nil);
    return ret;
}

- (ACCRepositoryRegisterInfo *)repoRegisterInfo
{
    return [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoRedPacketModel.class];
}

@end
