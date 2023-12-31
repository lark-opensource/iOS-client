//
//  BDAutoTrackURLHostItemVA.m
//  RangersAppLog
//
//  Created by 朱元清 on 2020/8/6.
//

#import "BDAutoTrackURLHostItemVA.h"
#import "BDAutoTrackURLHostProvider.h"
#import "BDAutoTrackURLHostItem.h"
#import "RangersAppLogConfig.h"

BDAutoTrackServiceVendor const BDAutoTrackServiceVendorVA = @"va";
static NSString * const VendorDomain =  @"itobsnssdk.com";

@interface BDAutoTrackURLHostItemVA : BDAutoTrackURLHostItem

@end

__attribute__((constructor)) void bdauto_host_item_va() {
    RangersAppLogConfig *config = [RangersAppLogConfig sharedInstance];
    if (config.defaultVendor == nil) {
        config.defaultVendor = BDAutoTrackServiceVendorVA;
    }
    BDAutoTrackURLHostItemVA *hostItem = [BDAutoTrackURLHostItemVA new];
    [[BDAutoTrackURLHostProvider sharedInstance] registerHostItem:hostItem];
}

@implementation BDAutoTrackURLHostItemVA

- (NSString *)hostDomain {
    return VendorDomain;
}

- (BDAutoTrackServiceVendor)vendor {
    return BDAutoTrackServiceVendorVA;
}

@end
