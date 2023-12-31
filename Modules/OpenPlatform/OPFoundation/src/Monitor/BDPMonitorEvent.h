//
//  BDPMonitorEvent.h
//  Timor
//
//  Created by yinyuan on 2018/12/9.
//

#import <Foundation/Foundation.h>
#import <ECOProbe/OPMonitor.h>
#import "BDPTracing.h"
#import "BDPModuleEngineType.h"
#import "BDPUniqueID.h"

@class BDPMonitorEvent;

@class BDPEngineProtocol;

/**
 *  语法糖:
 *  创建一个新的事件对象，事件名为name
 */
FOUNDATION_EXPORT BDPMonitorEvent * _Nonnull BDPMonitorWithName(NSString * _Nonnull eventName, BDPUniqueID * _Nullable uniqueID) NS_SWIFT_UNAVAILABLE("Please use OPMonitor in swift instead.");

/**
*  语法糖:
*  创建一个新的 monitorCode 事件对象
*/
FOUNDATION_EXPORT BDPMonitorEvent * _Nonnull BDPMonitorWithCode(OPMonitorCode * _Nonnull monitorCode, BDPUniqueID * _Nullable uniqueID) NS_SWIFT_UNAVAILABLE("Please use OPMonitor in swift instead.");

/**
*  语法糖:
*  创建一个新的 monitorCode 事件对象
*/
FOUNDATION_EXPORT BDPMonitorEvent * _Nonnull BDPMonitorWithNameAndCode(NSString * _Nullable eventName, OPMonitorCode * _Nullable monitorCode, BDPUniqueID * _Nullable uniqueID) NS_SWIFT_UNAVAILABLE("Please use OPMonitor in swift instead.");

@interface BDPMonitorEvent : OPMonitorEvent <NSCopying>

- (BDPMonitorEvent * _Nonnull (^ _Nonnull)(BDPUniqueID * _Nonnull uniqueID))setUniqueID;

@end

@interface OPMonitorEvent (BDPExtension)

/**
 *  记录 trace_id，传入 BDPTracing 对象
 *  相当于 .kv(@"trace_id", trace.traceId)
 */
- (OPMonitorEvent * _Nonnull (^ _Nonnull)(BDPTracing * _Nullable trace))bdpTracing DEPRECATED_MSG_ATTRIBUTE("use tracing api,bdpTracing just forward to it");

@end

//
///**
// *  用于支持 kv 接口传入对象类型或者基本类型或者一些常见的结构体
// *  value 可以是对象类型，可以传入nil
// *  value 可以是基本类型
// *  value 可以是一些常见的结构体: CGPoint, CGSize, CGVector, CGRect, CGAffineTransform, UIEdgeInsets, NSDirectionalEdgeInsets, UIOffset
// *  其他类型的结构体，请转换为NSValue对象或者自行处理
// */
#define kv(key, value)  addCategoryValue(key, value)
