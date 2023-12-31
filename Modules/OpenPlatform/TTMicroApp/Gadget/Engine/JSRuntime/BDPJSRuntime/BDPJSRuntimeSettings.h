//
//  BDPJSRuntimeSettings.h
//  TTMicroApp
//
//  Created by MJXin on 2021/12/16.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

@class OPAppUniqueID;
@interface BDPJSRuntimeSettings : NSObject
+ (NSDictionary<NSString *, NSNumber *> *)getNetworkAPISettingsWithUniqueID:(OPAppUniqueID *)uniqueID;
+ (BOOL)isUseNewNetworkAPIWithUniqueID:(OPAppUniqueID *)uniqueID;
+ (NSString *)generateRandomID:(NSString *)source;
@end

NS_ASSUME_NONNULL_END
