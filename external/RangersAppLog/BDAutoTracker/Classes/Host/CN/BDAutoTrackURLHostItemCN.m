//
//  BDAutoTrackURLHostItemCN.m
//  RangersAppLog-RangersAppLog
//
//  Created by 朱元清 on 2020/8/6.
//

#import "BDAutoTrackURLHostItemCN.h"
#import "BDAutoTrackURLHostItem.h"
#import "BDAutoTrackURLHostProvider.h"
#import "RangersAppLogConfig.h"
#import "BDCommonDefine.h"

BDAutoTrackServiceVendor const BDAutoTrackServiceVendorCN = @"";
static NSString * const VendorDomain =  @"volceapplog.com";

@interface BDAutoTrackURLHostItemCN : BDAutoTrackURLHostItem

@end


__attribute__((constructor)) void bdauto_host_item_cn(void) {
    [RangersAppLogConfig sharedInstance].defaultVendor = BDAutoTrackServiceVendorCN;
    BDAutoTrackURLHostItemCN *hostItem = [BDAutoTrackURLHostItemCN new];
    [[BDAutoTrackURLHostProvider sharedInstance] registerHostItem:hostItem];
}


@implementation BDAutoTrackURLHostItemCN

- (NSString *)hostDomain {
    return VendorDomain;
}

- (BDAutoTrackServiceVendor)vendor {
    return BDAutoTrackServiceVendorCN;
}

- (NSString *)thirdLevelDomainForURLType:(BDAutoTrackRequestURLType)type {
    NSString *thirdLevelDomain;
    if (type == BDAutoTrackRequestURLSettings ||
        type == BDAutoTrackRequestURLLog ||
        type == BDAutoTrackRequestURLProfile) {
        thirdLevelDomain = @"toblog";
    }
    if (type == BDAutoTrackRequestURLRegister ||
        type == BDAutoTrackRequestURLActivate ||
        type == BDAutoTrackRequestURLOneIDBind) {
        thirdLevelDomain = @"klink";
    }
    if (type == BDAutoTrackRequestURLALinkLinkData ||
        type == BDAutoTrackRequestURLALinkAttributionData) {
        thirdLevelDomain = @"alink";
    }
    if (type == BDAutoTrackRequestURLABTest) {
        thirdLevelDomain = @"abtest";
    }
    if (type == BDAutoTrackRequestURLLogBackup) {
        thirdLevelDomain = @"tobapplog";
    }
    return thirdLevelDomain;
}

@end
