//
//  BDAutoTrackIdentifier.m
//  RangersAppLog
//
//  Created by SoulDiver on 2022/10/10.
//

#import "BDAutoTrackIdentifier.h"
#import "BDAutoTrackDeviceHelper.h"
#import "RangersAppLogConfig.h"
#import "BDAutoTrack+Private.h"

#import "BDAutoTrackDefaults.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackKeychain.h"

@interface BDAutoTrackIdentifier ()

@property (nonatomic, weak) BDAutoTrack *tracker;

@end

@implementation BDAutoTrackIdentifier

- (instancetype)initWithTracker:(id)tracker
{
    self = [super init];
    if (self) {
        self.tracker = tracker;
    }
    return self;
}


- (NSString *)mock_vendorID
{
    static NSString *mock_vendorID;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mock_vendorID = [NSUUID UUID].UUIDString;
    });
    return mock_vendorID;
}

- (NSString *)vendorID
{
    if (self.mockEnabled) {
        return [self mock_vendorID];
    }
    return bd_device_IDFV();
}

- (NSString *)mock_advertisingID
{
    static NSString *mock_advertisingID;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mock_advertisingID = [NSUUID UUID].UUIDString;
    });
    return mock_advertisingID;
}

- (NSString *)advertisingID
{
    if (self.mockEnabled) {
        return [self mock_advertisingID];
    }
    return [[RangersAppLogConfig sharedInstance].handler uniqueID];
}


- (void)clearIDs
{
    BDAutoTrackDefaults *defaults = [BDAutoTrackDefaults defaultsWithAppID:self.tracker.appID];
    [defaults clearAllData];
    
    NSString *cdKey = [self suffixedKey:@"kAppLogCDKey"];
    bd_keychain_delete(cdKey);
    NSString *deviceIDKey = [self suffixedKey:@"kAppLogBDDidKey"];
    NSString *deviceIDKeychain = [deviceIDKey stringByAppendingFormat:@"_%@",self.tracker.appID];
    bd_keychain_delete(deviceIDKeychain);
}

- (NSString *)suffixedKey:(NSString *)key {
    
    BDAutoTrackServiceVendor vendor = self.serviceVendor;
    if (vendor && vendor.length > 0) {
        key = [key stringByAppendingFormat:@"_%@", vendor];
    }
    return key;
}


@end
