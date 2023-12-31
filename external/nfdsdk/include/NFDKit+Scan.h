//
//  NFDKit+Scan.h
//  nfdsdk
//
//  Created by lujunhui.2nd on 2023/1/30.
//
#import <Foundation/Foundation.h>
#import "NFDKit.h"

NS_ASSUME_NONNULL_BEGIN

@interface NFDKit (Scan)


// MARK: - Scan

///
/// 初始化 Scan 实例。
///
/// 在 SDK C 内部会生成一个全局实例，由 C 持有。
///
/// - important: 需要在使用 Scan 功能之前调用，整个 App 运行周期内只需要调用一次。
- (void)initScanner;

///
/// 判断 Scan 是否初始化过。
///
/// - returns: 如果 C 中存在 Scan 的实例，则返回 `true`，否则返回 `false`
- (bool)isScannerInit;

///
/// 配置 Scan 的扫描信息。
///
/// - parameter configJson: 服务端下发的配置信息的 json 格式字符串。
/// - returns: 返回调用是否成功，如果是 `NFD_SUCCESS`，则表示成功；否则皆为失败，内容是失败原因。
/// - important: 需要在 Scan init 、Scan stop 时调用。
- (NFDKitReturnValue)configScan:(NSString *)configJson;

///
/// 启动扫描。
///
/// 不支持并发的扫描，同一时刻只能执行一个扫描。
///
/// - parameter timeout: 超时时间，单位时毫秒。
/// - parameter mode: 扫描的模式，支持超声波、蓝牙、混合多种情况。
/// - parameter callback: 扫描结果的回调，如果开启了蓝牙扫描，那么会高频回调多次；`Error_Code` 是 `NFD_NO_ERROR` 则表示没有错误，否则表示有错误，内容即是错误原因。
/// - returns: 返回调用是否成功，如果是 `NFD_SUCCESS`，则表示成功；否则皆为失败，内容是失败原因。
/// - important: 调用错误不会在 callback 中体现，需要主动观察调用的返回值，即调用失败，callback 是不会触发的。
/// - important: 当 `callback` 中的 `Error_Code` 表示错误时，表示没有有效的结果；如果是混合扫描的模式，那么表示所有的扫描方式都没有获得到有效的结果。
- (NFDKitReturnValue)startScan:(int)timeout andMode:(NFDKitScanMode)mode andUsage:(NFDKitUsage)usage andCallback:(NFDKitScanCallback)callback;

///
/// 关闭扫描。
///
/// - returns: 返回调用是否成功，如果是 `NFD_SUCCESS`，则表示成功；否则皆为失败，内容是失败原因。
- (NFDKitReturnValue)stopScan;

///
/// 销毁 C 中存储的 Scan 实例。
- (void)uninitScan;
@end

NS_ASSUME_NONNULL_END
