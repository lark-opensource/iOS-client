//
//  HMDServerStateService.h
//  Heimdallr
//
//  Created by Nickyo on 2023/7/21.
//

#import <Foundation/Foundation.h>
#import "HMDServerStateDefinition.h"
// Utility
#import "HMDPublicMacro.h"

HMD_EXTERN_SCOPE_BEGIN

#pragma mark - 通用容灾API

/// 是否丢弃全部数据
BOOL hmd_drop_all_data(HMDReporter report);

/// 是否丢弃数据
BOOL hmd_drop_data(HMDReporter report);

/// 服务是否可用
BOOL hmd_is_server_available(HMDReporter report);

/// 更新服务数据，返回当前服务状态
HMDServerState hmd_update_server_checker(HMDReporter report, NSDictionary * _Nullable result, NSInteger statusCode);

#pragma mark - 存在 SDK 上报场景时使用

/// 是否丢弃全部数据
BOOL hmd_drop_all_data_sdk(HMDReporter report, NSString * _Nullable aid);

/// 是否丢弃数据
BOOL hmd_drop_data_sdk(HMDReporter report, NSString * _Nullable aid);

/// 服务是否可用
BOOL hmd_is_server_available_sdk(HMDReporter report, NSString * _Nullable aid);

/// 更新服务数据，返回当前服务状态
HMDServerState hmd_update_server_checker_sdk(HMDReporter report, NSString * _Nullable aid, NSDictionary * _Nullable result, NSInteger statusCode);

HMD_EXTERN_SCOPE_END
