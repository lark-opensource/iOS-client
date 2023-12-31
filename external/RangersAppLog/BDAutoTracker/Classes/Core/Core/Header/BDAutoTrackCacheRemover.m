//
//  BDAutoTrackCacheRemover.m
//  RangersAppLog
//
//  Created by 朱元清 on 2020/11/2.
//

#import "BDAutoTrackCacheRemover.h"

// for cache removal
#import "BDAutoTrackDefaults.h"
#import "BDAutoTrackKeychain.h"


@implementation BDAutoTrackCacheRemover

// for cache removal

- (void)removeDefaultsForAppID:(NSString *)appID {
    BDAutoTrackDefaults *defaults = [BDAutoTrackDefaults defaultsWithAppID:appID];
    [defaults clearAllData];
}

- (void)removeCurrentBundleFromStandardDefaultsSearchList {
    NSString *bundleID = [NSBundle.mainBundle bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removeSuiteNamed:bundleID];
}

- (void)removeCurrentBundleFromStandardDefaults {
    NSString *bundleID = [NSBundle.mainBundle bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:bundleID];
}

- (void)removeKeychainForAppID:(NSString *)appID serviceVendor:(BDAutoTrackServiceVendor)vendor {
    /// 如果存数据的存储Key改了或者有增添，这里也要相应地改和增添
    static NSString *const kAppLogOpenUDIDKey   = @"openUDID";
    static NSString *const kAppLogCDKey         = @"kAppLogCDKey";
    static NSString *const kAppLogDeviceIDKey   = @"kAppLogBDDidKey";

    // remove openUDID
    bd_keychain_delete(kAppLogOpenUDIDKey);
    
    // remove cdkey
    bd_keychain_delete([self storageKeyWithPrefix:kAppLogCDKey serviceVendor:vendor]);
    
    // remove deviceID
    NSString *deviceIDKey = [self storageKeyWithPrefix:kAppLogDeviceIDKey serviceVendor:vendor];
    NSString *deviceIDKeychain = [deviceIDKey stringByAppendingFormat:@"_%@", appID];
    bd_keychain_delete(deviceIDKeychain);
}

/// 如果存数据的前缀函数改了，这里的前缀函数也要改
- (NSString *)storageKeyWithPrefix:(NSString *)prefix serviceVendor:(BDAutoTrackServiceVendor)vendor  {
    NSString *key = prefix;
    
    // vendor is a String Enum
    // use vendor's raw value as a suffix
    if (vendor && vendor.length > 0) {
        key = [key stringByAppendingFormat:@"_%@", vendor];
    }

    return key;
}

@end
