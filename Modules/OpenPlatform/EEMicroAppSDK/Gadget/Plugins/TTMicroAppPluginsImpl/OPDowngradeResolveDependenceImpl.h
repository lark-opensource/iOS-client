//
//  OPDowngradeResolveDependenceImpl.h
//  EEMicroAppSDK
//
//  Created by justin on 2023/1/9.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/OPResolveDependenceUtil.h>
NS_ASSUME_NONNULL_BEGIN

@interface OPDowngradeResolveDependenceImpl : NSObject<OPDowngradeResolveDependenceDelegate>

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
