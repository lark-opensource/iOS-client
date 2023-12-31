//
//  NFDKit.m
//  NFDDemoSDK
//
//  Created by lujunhui.2nd on 2022/11/24.
//

#import <Foundation/Foundation.h>
#import "NFDKit.h"
#import "NFDSDK.hpp"
#import <CoreBluetooth/CoreBluetooth.h>
#import "P_NFDKit+PSDA.h"

@interface NFDKit()
@property(weak) id<NFDKitDelegate> delegate;
@property(readwrite) NFDKitScanCallback scanCallback;
@property(readwrite) NFDKitBlePermissionCallback blePermissionCallback;

@end

void loggerCB(int instanceID, NFDLogLevel level, const char* content) {
    @autoreleasepool {
        NFDKit* instance = [[NFDKit getInstanceMap] objectForKey:[NSNumber numberWithInt:instanceID]];
        if (instance == nullptr) {
            return;
        }
        id<NFDKitDelegate> delegate = instance.delegate;
        if (delegate != nullptr && content != nullptr) {
            [delegate onNFDKitLogging:(NFDKitLogLevel)level andContent:[NSString stringWithCString:content encoding:NSUTF8StringEncoding]];
        }
    }
};

void trackerFuncCB(int instanceID, const char *event, const char *params) {
    @autoreleasepool {
        NFDKit* instance = [[NFDKit getInstanceMap] objectForKey:[NSNumber numberWithInt:instanceID]];
        if (instance == nullptr) {
            return;
        }
        id<NFDKitDelegate> delegate = instance.delegate;
        if (delegate != nullptr && event != nullptr && params != nullptr) {
            NSString* eventStr = [NSString stringWithCString:event encoding:NSUTF8StringEncoding];
            NSString* paramsStr = [NSString stringWithCString:params encoding:NSUTF8StringEncoding];
            [delegate onNFDKitTracking:eventStr andParams:paramsStr];
        }
    }
};

void applyBlePermissionCB(NFDBlePermissionState state) {
    @autoreleasepool {
        for (id value in [NFDKit getInstanceMap].allValues) {
            NFDKit* instance = value;
            if (instance == nullptr) {
                continue;
            }
            if (instance.blePermissionCallback != nullptr) {
                instance.blePermissionCallback(state);
                instance.blePermissionCallback = nullptr;
            }
        }
    }
};

#if __has_include(<LarkSensitivityControl/LarkSensitivityControl-Swift.h>)
int NFDKitiOSBleScanImp(void * manager) {
    @autoreleasepool {
        CBCentralManager *realmanger = (__bridge CBCentralManager *)(manager);
        NSError* error;
        if ([NFDKit p_getBleScanPSDAToken] == nullptr) {
            return NFDKit_BLE_PSDA_ERROR;
        }
        [DeviceInfoEntry
         scanForPeripheralsForToken:[NFDKit p_getBleScanPSDAToken]
         manager:realmanger
         withServices:NULL
         options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@true}
         error:&error
        ];

        if (error != nullptr) {
            return NFDKit_BLE_PSDA_ERROR;
        }
        [NFDKit p_setBleScanPSDAToken:nullptr];
        return NFDKit_SUCCESS;
    }
}
#endif



@implementation NFDKit

static NSMutableDictionary *instanceMap = [[NSMutableDictionary alloc] init];

+(NSMutableDictionary *) getInstanceMap {
    return  instanceMap;
}

// MARK: - init
- (NFDKitReturnValue) initSDK:(id<NFDKitDelegate>) delegate; {
    self.delegate = delegate;
    self.scannerID = NFDGenerateScannerInstanceID();
    self.instanceID = [NSNumber numberWithInt:self.scannerID];
    [self setSDKCallbacks];
#if __has_include(<LarkSensitivityControl/LarkSensitivityControl-Swift.h>)
    setIOSBleScanImp(NFDKitiOSBleScanImp);
#endif
    [instanceMap setObject:self forKey:self.instanceID];
    return (NFDKitReturnValue)NFD_SUCCESS;
}

- (void) setSDKCallbacks {
    NFDSDKInit(self.scannerID, loggerCB, trackerFuncCB);
}

// 单例
+ (instancetype)sharedInstance
{
    static NFDKit *instance = nil;
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:nil] init];
    });
    return instance;
}

+ (NFDKit*)shared
{
    return [NFDKit sharedInstance];
}

- (instancetype)init {
    self = [super init];
    return self;
}

- (void)uninit {
    [instanceMap removeObjectForKey:self.instanceID];
}

- (NFDKitReturnValue) applyBlePermission:(NFDKitBlePermissionCallback) callBack; {
    self.blePermissionCallback = callBack;
    return (NFDKitReturnValue)NFDApplyBlePermission(self.scannerID, applyBlePermissionCB);
}


@end
