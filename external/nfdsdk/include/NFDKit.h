//
//  NFDKit.h
//  NFDDemoSDK
//
//  Created by lujunhui.2nd on 2022/11/24.
//

#ifndef NFDKit_h
#define NFDKit_h

#import <Foundation/Foundation.h>
#import "nfd_enum_code_gen.h"
#if __has_include(<LarkSensitivityControl/LarkSensitivityControl-Swift.h>)
#import <Photos/Photos.h>
#import <CoreMotion/CoreMotion.h>
#import <LarkSensitivityControl/LarkSensitivityControl-Swift.h>
#endif

NS_ASSUME_NONNULL_BEGIN



// MARK: - Type Define

typedef void (^NFDKitTrackerFuncCallback)(NSString *event, NSString *params);
typedef void (^NFDKitScanCallback)(NSString *paramJson, NFDKitScanErrorCode errorCode);
typedef void (^NFDKitBlePermissionCallback)(int state);


// MARK: - Protocol
@protocol NFDKitDelegate <NSObject>
@required
- (void)onNFDKitLogging:(NFDKitLogLevel)level andContent:(NSString *)content;
@required
- (void)onNFDKitTracking:(NSString *)event andParams:(NSString *)params;
@end

// MARK: - NFDKit
@interface NFDKit : NSObject

// MARK: - init

/// 注册日志、埋点的回调
- (NFDKitReturnValue)initSDK:(id<NFDKitDelegate>)delegate;

- (NFDKitReturnValue) applyBlePermission:(NFDKitBlePermissionCallback) callBack;

- (instancetype)init;
- (void)uninit;

+ (NFDKit *)shared;

+ (instancetype)sharedInstance;

+ (NSMutableDictionary *) getInstanceMap;

@property(readwrite) int scannerID;
@property(readwrite) NSNumber* instanceID;
#if __has_include(<LarkSensitivityControl/LarkSensitivityControl-Swift.h>)
@property(strong) Token* token;
#endif

@end

#endif /* NFDKit_h */
NS_ASSUME_NONNULL_END
