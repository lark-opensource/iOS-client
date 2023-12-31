//
//  BDPAuthorizationSettingManager.h
//  Timor
//
//  Created by liuxiangxin on 2019/6/27.
//

#import <Foundation/Foundation.h>
#import "BDPUniqueID.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPAuthorizationSettingManager : NSObject

+ (instancetype)sharedManager;

- (BOOL)shouldUseCombineAuthorizeForUniqueID:(BDPUniqueID *)uniqueID;

@end

NS_ASSUME_NONNULL_END
