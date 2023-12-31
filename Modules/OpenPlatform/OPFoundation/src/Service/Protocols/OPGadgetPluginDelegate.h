//
//  OPGadgetPluginDelegate.h
//  OPFoundation
//
//  Created by justin on 2023/1/3.
//

#import <Foundation/Foundation.h>
#import "BDPBasePluginDelegate.h"
#import "BDPUniqueID.h"
#import <ECOProbe/OPTraceProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@protocol OPGadgetPluginDelegate <BDPBasePluginDelegate>

@required
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
