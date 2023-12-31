
/*!@header @p HMDFrameRecoverManager.h
   @author somebody
   @abstract Heimdallr Mach / NSException 防护依赖组件
             非 Heimdallr 内部请勿直接访问接口
 */

#import <Foundation/Foundation.h>
#import "HMDFrameRecoverExceptionData.h"
#import "HMDFrameRecoverMachData.h"
#include "HMDFrameRecoverQuery.h"
#include "HMDMachRecoverDeclaration.h"
#include "HMDMachRestartableDeclaration.h"
#include "HMDFrameRecoverPublicMacro.h"

NS_ASSUME_NONNULL_BEGIN

/*!@interface HMDFrameRecoverManager
   @abstract Heimdallr Mach / NSException 防护
 */
@interface HMDFrameRecoverManager : NSObject

#pragma mark - [第一步] 设置 image 查询方法

/*!@method setQueryBegin:enumeration:finish:
   @discussion 设置 Binary Image 查询方法，对齐 Heimdallr Shared Binary Image List 实现，
   @note 其直接使用方只有 machO query 时刻，并无其他使用地方 ( 维护方便
 */
+ (void)setQueryBegin:(HMDFC_begin_func_t        _Nonnull)begin
          enumeration:(HMDFC_enum_section_func_t _Nonnull)enum_section
               finish:(HMDFC_finish_func_t       _Nonnull)finish;

/*!@method setEnumImage:
   @discussion 查询 Image 相关信息, 例如 UUID Path 等数据
   @note 其直接使用方只有 machO query 时刻，并无其他使用地方 ( 维护方便
   @version FrameRecover >= 1.16.0
 */
+ (void)setEnumImage:(HMDFC_enum_image_func_t _Nonnull)enum_image;

/*!@method setQueryListStatus:
   @discussion 当前 Binary Image 信息是否准备完成，用于等待机制实现
   @note Mach 异常防护云控下发功能时刻，如果启动时间过早而 Binary Image 尚未准备成功
   @version FrameRecover >= 1.20.0
 */
+ (void)setQueryListStatus:(HMDFC_list_finish_func_t _Nonnull)list_finish;

/*!@method markImageListFinished
   @discussion 触发 Binary Image 信息等待机制时刻，等待注册的信息进行立即注册
   @note Mach 异常防护云控下发功能时刻，如果启动时间过早而 Binary Image 尚未准备成功
   @version FrameRecover >= 1.20.0
 */
+ (void)markImageListFinished;

#pragma mark - [第二步] 开启全局初始化

/*!@method setup
   @discussion 全局初始化，与 Slardar 配置下发同步
 */
+ (void)setup;

#pragma mark - [第三步] 设置 NSException handler

#pragma mark 设置 NSException 处理回调

/*!@method objcExceptionCallback:
   @discussion 当发生 NSException 防护之后，将通过该接口回调防护信息
   @note 设置处理回调应该早于获取 @p +[HMDFrameRecoverManager_exceptionHandler]
 */
+ (void)objcExceptionCallback:(HMDFCExceptionCallback _Nonnull)callback;

#pragma mark 获取 Exception handler

/*!@method exceptionHandler
   @discussion 该接口是传递接管 Exception 异常抛出接口的处理接口
   @return 处理回调格式 @code void (*)(void *, std::type_info *, void(*)(void*)) @endcode
 */
+ (void * _Nullable)exceptionHandler;

#pragma mark - [第四步] 获取 Mach handler

#pragma mark scope

/*!@property scopeEnabled
   @discussion 是否启用 Mach 异常防护 Scope 功能，该功能下属管辖 Try-catch 以及 Cloud-Control 功能
   @version FrameRecover >= 1.14.0
 */
@property(class, getter=isScopeEnabled) BOOL scopeEnabled;

/*!@method scopePrefix:
   @abstract 注册 scope 前缀匹配规则，默认应该传递 @p com.bytedance
   @version FrameRecover >= 1.14.0
 */
+ (void)scopePrefix:(const char * _Nonnull)prefix;

/*!@method scopeWhiteList:
   @abstract 注册 scope 白名单规则，优先级晚于黑名单
   @version FrameRecover >= 1.14.0
 */
+ (void)scopeWhiteList:(const char * _Nonnull)scope;

/*!@method scopeBlackList:
   @abstract 注册 scope 黑名单规则，优先级早于白名单
   @version FrameRecover >= 1.14.0
 */
+ (void)scopeBlackList:(const char * _Nonnull)scope;

#pragma mark 设置 Mach 处理回调

/*!@method machExceptionCallback:
   @abstract Mach 异常防护异常回调接口
   @version FrameRecover >= 1.14.0
 */
+ (void)machExceptionCallback:(HMDFCMachCallback _Nonnull)callback;

#pragma mark 获取 mach handler

/*!@method machHandler
   @discussion 该接口是传递接管 Mach 异常抛出接口的处理接口
   @return 处理回调格式 @code bool(*)(task_t,thread_t, NDR_record_t, exception_type_t, mach_msg_type_number_t) @endcode
   @version FrameRecover >= 1.14.0
 */
+ (void * _Nullable)machHandler;

#pragma mark Mach 保护调用

/*!@function @p HMDFrameRecoverManager_protectMachException
   @discussion 该接口是 Mach 异常防护 try-catch 接口
   @return 返回值为 true 意味着发生了崩溃，否则程序正常平稳运行
   @version FrameRecover >= 1.14.0
 */
HMDFC_EXTERN bool HMDFrameRecoverManager_protectMachException(const char * _Nonnull scope,
                                                              HMDMachRecoverOption option,
                                                              HMDMachRecoverContextRef _Nullable context,
                                                              void(^ _Nonnull block)(void));
/*!@method updateMachExceptionCloudControl:
   @discussion 该接口是 Mach 异常防护 Cloud-Control 云控下发接口
   @version FrameRecover >= 1.16.0
 */
+ (void)updateMachExceptionCloudControl:(NSArray<NSString *> * _Nonnull)settings;

/*!@function @p HMDFrameRecoverManager_machRestartable_range_register
   @discussion 该接口是 Mach 异常防护 Restartable Range 接口
   @version FrameRecover >= 1.17.0
 */
HMDFC_EXTERN bool HMDFrameRecoverManager_machRestartable_range_register(HMDMachRestartable_range_ref _Nonnull range);

/*!@function @p HMDFrameRecoverManager_machRestartable_range_unregister
   @discussion 该接口是 Mach 异常防护 Restartable Range 接口
   @version FrameRecover >= 1.17.0
 */
HMDFC_EXTERN bool HMDFrameRecoverManager_machRestartable_range_unregister(HMDMachRestartable_range_ref _Nonnull range);

#pragma mark Mach 开启

/*!@property machExceptionEnable
   @abstract 是否启用 Mach 异常防护功能，是同步 Slardar 云端配置控制 Mach 异常防护 Try-Catch 和 Cloud Control 功能
   @version FrameRecover >= 1.14.0
   @note 自 FrameRecover >= 1.21.0 版本，machExceptionEnable 不再控制 Mach 异常 Restartable Range 功能的开启和关闭
 */
@property(class, getter=isMachExceptionEnable) bool machExceptionEnable;

/*!@property machRestartableEnable
   @abstract 是否启用 Mach Restartable 防护功能，不与 Slardar 云端配置同步
   @version FrameRecover >= 1.21.0
 */
@property(class, getter=isMachRestartableEnable) bool machRestartableEnable;

#pragma mark Verson

/*!@property version
   @abstract FrameRecover 版本号
   @example FrameRecover 版本号为 x.y.z 时刻，例如 1.5.0 返回值为
   @code version = x * 10000 + y * 100 + z = 10500
   @endcode
 */
@property(class, readonly) NSUInteger version;

#pragma mark Deprecated Attribute

/*!@method protectMachException:option:context:block:
   @deprecated 请使用函数 @p HMDFrameRecoverManager_protectMachException
   @version FrameRecover >= 1.14.0
 */
+ (bool)protectMachException:(const char * _Nonnull)scope
                      option:(HMDMachRecoverOption)option
                     context:(void * _Nullable)context
                       block:(void(^ _Nonnull)(void))block
HMDFC_MSG_DEPRECATED("replace with HMDFrameRecoverManager_protectMachException");

@end

NS_ASSUME_NONNULL_END
