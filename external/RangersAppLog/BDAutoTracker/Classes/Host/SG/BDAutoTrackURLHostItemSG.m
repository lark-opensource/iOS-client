//
//  BDAutoTrackURLHostItemSG.m
//  RangersAppLog
//
//  Created by 朱元清 on 2020/8/6.
//

#import "BDAutoTrackURLHostItemSG.h"
#import "BDAutoTrackURLHostProvider.h"
#import "BDAutoTrackURLHostItem.h"
#import "RangersAppLogConfig.h"

BDAutoTrackServiceVendor const BDAutoTrackServiceVendorSG = @"sg";
static NSString * const VendorDomain =  @"tobsnssdk.com";

@interface BDAutoTrackURLHostItemSG : BDAutoTrackURLHostItem

@end

__attribute__((constructor)) void bdauto_host_item_sg() {
    RangersAppLogConfig *config = [RangersAppLogConfig sharedInstance];
    if (config.defaultVendor == nil) {
        config.defaultVendor = BDAutoTrackServiceVendorSG;
    }
    
    BDAutoTrackURLHostItemSG *hostItem = [BDAutoTrackURLHostItemSG new];
    [[BDAutoTrackURLHostProvider sharedInstance] registerHostItem:hostItem];
}

@implementation BDAutoTrackURLHostItemSG

- (NSString *)hostDomain {
    return VendorDomain;
}

- (BDAutoTrackServiceVendor)vendor {
    return BDAutoTrackServiceVendorSG;
}

@end
