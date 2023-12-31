//
//  BDNetworkTagManager.h
//
//  Created by zoujianfeng on 2021/4/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    BDNetworkTagTypeAuto,
    BDNetworkTagTypeManual,
} BDNetworkTagType;


FOUNDATION_EXTERN NSString *const BDNetworkTagRequestKey;

@interface BDNetworkTagManager : NSObject

/// Default auto trigger tag info, include trigger & new_user
+ (nonnull NSDictionary *)autoTriggerTagInfo;

/// Default manual trigger tag info, include trigger & new_user
+ (nonnull NSDictionary *)manualTriggerTagInfo;

/// Gets the tag info by type
/// @param type BDNetworkTagType
+ (nullable NSDictionary *)tagForType:(BDNetworkTagType)type;

/// Get the tag info from the context through the BDNetworkTagRequestKey
/// @param context contains tag info
+ (nullable NSDictionary *)filterTagFromContext:(NSDictionary *)context;

/// Whether it is a new user, includes a new install and uninstall reinstall
+ (BOOL)isNewUser;

/// Disable tag for request
+ (void)disableTagCapacity:(BOOL)disable;

@end

NS_ASSUME_NONNULL_END
