//
//  OPResolveDependenceUtil.h
//  OPFoundation
//
//  Created by justin on 2023/1/9.
//

#import <Foundation/Foundation.h>
#import "BDPVersionManagerDelegate.h"
#import "BDPPermissionViewControllerDelegate.h"
#import "EMAAppEngineConfig.h"
#import "EMAAppEngineAccount.h"
#import "EMAConfig.h"
#import <ECOProbe/OPTraceProtocol.h>
#import "OPAppUniqueID.h"

NS_ASSUME_NONNULL_BEGIN

@protocol OPDowngradeResolveDependenceDelegate <NSObject>

+(Class<BDPVersionManagerDelegate>)versionManagerClass;

+(Class<BDPPermissionViewControllerDelegate>)permissionViewControllerClass;

+ (EMAAppEngineConfig *)currentAppEngineConfig;

+ (EMAAppEngineAccount *)currentAppEngineAccount;

+ (EMAConfig *)currentAppEngineOnlineConfig;

+ (NSString *)blockIDWithID:(OPAppUniqueID *)uniqueID;

+ (NSString *)hostWithID:(OPAppUniqueID *)uniqueID;

+ (NSString * _Nullable)packageVersionWithID:(OPAppUniqueID *)uniqueID;

+ (id<OPTraceProtocol> _Nullable)blockTraceWithID:(OPAppUniqueID *)uniqueID;

// == BDPPreloadHelper.preHandleEnable()
+ (BOOL)enablePrehandle;

// 内部调用[[BDPWarmBootManager sharedManager] updateMaxWarmBootCacheCount:(int)count];
+ (void)updateMaxWarmBootCacheCount:(int)maxCount;

@end

@interface OPResolveDependenceUtil : NSObject

+(Class<BDPVersionManagerDelegate>)versionManagerClass;

+(Class<BDPPermissionViewControllerDelegate>)permissionViewControllerClass;

+ (EMAAppEngineConfig *)currentAppEngineConfig;

+ (EMAAppEngineAccount *)currentAppEngineAccount;

+ (EMAConfig *)currentAppEngineOnlineConfig;

+ (NSString *)blockIDWithID:(OPAppUniqueID *)uniqueID;

+ (NSString *)hostWithID:(OPAppUniqueID *)uniqueID;

+ (NSString * _Nullable)packageVersionWithID:(OPAppUniqueID *)uniqueID;

+ (id<OPTraceProtocol> _Nullable)blockTraceWithID:(OPAppUniqueID *)uniqueID;

// == BDPPreloadHelper.preHandleEnable()
+ (BOOL)enablePrehandle;

// 内部调用[[BDPWarmBootManager sharedManager] updateMaxWarmBootCacheCount:(int)count];
+ (void)updateMaxWarmBootCacheCount:(int)maxCount;

@end

NS_ASSUME_NONNULL_END
