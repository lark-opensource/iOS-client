//
//  BDPCommonMonitorHelper.h
//  Timor
//
//  Created by houjihu on 2020/6/4.
//

#ifndef BDPCommonMonitorHelper_h
#define BDPCommonMonitorHelper_h

#import "BDPModuleEngineType.h"
#import "BDPMonitorEvent.h"
#import "BDPMonitorHelper.h"
#import "BDPTracingManager.h"

@protocol BDPEngineProtocol;

NS_ASSUME_NONNULL_BEGIN

/// 根据eventName，快速生成指定应用唯一标识和应用类型相关的MonitorEvent
FOUNDATION_EXPORT BDPMonitorEvent *CommonMonitorWithNameIdentifierType(NSString *eventName, BDPUniqueID *uniqueID);

/// 根据monitorCode，快速生成指定应用唯一标识和应用类型相关的MonitorEvent
FOUNDATION_EXPORT BDPMonitorEvent *CommonMonitorWithCodeIdentifierType(OPMonitorCode *monitorCode, BDPUniqueID *uniqueID);

/// 无法取到应用唯一标识时，根据eventName快速生成MonitorEvent
FOUNDATION_EXPORT BDPMonitorEvent *CommonMonitorWithName(NSString *eventName);

/// 无法取到应用唯一标识时，根据monitorCode快速生成MonitorEvent
FOUNDATION_EXPORT BDPMonitorEvent *CommonMonitorWithCode(OPMonitorCode *monitorCode);

/// 用于根据Engine创建埋点的方式，同时兼容小程序 & H5
FOUNDATION_EXPORT BDPMonitorEvent * BDPMonitorWithNameAndEngine(NSString * eventName, id<BDPEngineProtocol> engine);
/*---------------------------------------------*/
//               定义 Event Name
/*---------------------------------------------*/
// event_name -> kEventName_event_name
BDP_DEFINE_EVENT_NAME(op_common_meta_request_start)
/// 应用meta请求结果
BDP_DEFINE_EVENT_NAME(op_common_meta_request_result)

/// meta加载开始
BDP_DEFINE_EVENT_NAME(op_common_load_meta_start)
/// meta加载结果
BDP_DEFINE_EVENT_NAME(op_common_load_meta_result)

/// 包加载开始
BDP_DEFINE_EVENT_NAME(op_common_load_package_start)
/// 包加载结果
BDP_DEFINE_EVENT_NAME(op_common_load_package_result)

/// 开始安装更新（预加载或者异步更新）
BDP_DEFINE_EVENT_NAME(op_common_install_update_start)
/// 安装更新结果（预加载或者异步更新）
BDP_DEFINE_EVENT_NAME(op_common_install_update_result)

/// 开始从网络下载包
BDP_DEFINE_EVENT_NAME(op_common_package_download_start)
/// 从网络下载包结果
BDP_DEFINE_EVENT_NAME(op_common_package_download_result)
/// 开始安装包
BDP_DEFINE_EVENT_NAME(op_common_package_install_start)
/// 安装包结果
BDP_DEFINE_EVENT_NAME(op_common_package_install_result)

/// 开始从网络下载大组件
BDP_DEFINE_EVENT_NAME(op_common_component_download_start)
/// 从网络下载大组件结果
BDP_DEFINE_EVENT_NAME(op_common_component_download_result)
/// 大组件开始安装
BDP_DEFINE_EVENT_NAME(op_common_component_install_start)
/// 大组件安装结果
BDP_DEFINE_EVENT_NAME(op_common_component_install_result)
/// 打开小程序时，依赖的大组件是否已经下载完成
BDP_DEFINE_EVENT_NAME(op_common_component_status)
/// 由于大组件下载失败导致 App 启动失败
BDP_DEFINE_EVENT_NAME(op_common_component_app_start_failed)

/// 应用卡片Meta请求
BDP_DEFINE_EVENT_NAME(op_app_card_meta_request)
/// 应用卡片批量Meta请求
BDP_DEFINE_EVENT_NAME(op_app_card_meta_request_batch)
/// 应用卡片 包安装
BDP_DEFINE_EVENT_NAME(op_app_card_package_install)

/// ODR 相关埋点
BDP_DEFINE_EVENT_NAME(op_odr_download_start)
BDP_DEFINE_EVENT_NAME(op_odr_download_result)

NS_ASSUME_NONNULL_END

#endif /* BDPCommonMonitorHelper_h */
