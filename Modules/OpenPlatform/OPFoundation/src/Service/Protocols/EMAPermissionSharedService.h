//
//  EMAPermissionSharedService.h
//  TTMicroApp
//
//  Created by baojianjun on 2023/5/29.
//

#import <Foundation/Foundation.h>
#import "BDPBasePluginDelegate.h"
#import "BDPUniqueID.h"
#import "EMAPermissionData.h"

NS_ASSUME_NONNULL_BEGIN

@protocol EMAPermissionSharedService <BDPBasePluginDelegate>

/**
 获取应用权限数据
 
 @param uniqueID uniqueID
 @return 权限数组
 */
- (NSArray<EMAPermissionData *> *)getPermissionDataArrayWithUniqueID:(BDPUniqueID *)uniqueID;

@end

NS_ASSUME_NONNULL_END
