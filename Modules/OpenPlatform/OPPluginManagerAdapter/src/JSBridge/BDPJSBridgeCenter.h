//
//  BDPJSBridgeCenter.h
//  Timor
//
//  Created by 王浩宇 on 2019/8/29.
//

#import "BDPJSBridgeBase.h"
#import <OPFoundation/BDPJSBridgeMethod.h>
#import <OPFoundation/BDPJSBridgeProtocol.h>


typedef Class BDPJSBridgeInstanceClass;
typedef void(^BDPJSBridgeContextMethod)(NSDictionary *params, BDPJSBridgeCallback callback);

/**
 JSBridge 核心模块，负责方法(API)注册，方法调用及回掉，参数获取等核心能力
 调用方法的引擎为实现 <BDPJSBridgeEngineProtocol> 协议的对象，目前为BDPWebView, BDPJSRuntime, BDPH5WebView
 */
@interface BDPJSBridgeCenter : NSObject

/**
 @brief                     初始化
 @return                    BDPJSBridgeCenter 实例
 */
+ (instancetype)defaultCenter;

/**
 @brief                     注册类实例方法(API)
 @param method              调用方法(API)名
 @param isSynchronize       是否为同步方法(API)
 @param isOnMainThread      是否需要在主线程调用
 @param class               方法(API)所在类
 @param type                方法(API)类型
 */
+ (void)registerInstanceMethod:(NSString *)method
                 isSynchronize:(BOOL)isSynchronize
                isOnMainThread:(BOOL)isOnMainThread
                         class:(BDPJSBridgeInstanceClass)myclass
                          type:(BDPJSBridgeMethodType)type;

/**
 @brief                     注册上下文方法(API)
 @param method              调用方法(API)名
 @param isSynchronize       是否为同步方法(API)
 @param isOnMainThread      是否需要在主线程调用
 @param type                方法(API)类型
 @param handler             方法(API)处理逻辑 Block
 */
+ (void)registerContextMethod:(NSString *)method
                isSynchronize:(BOOL)isSynchronize
               isOnMainThread:(BOOL)isOnMainThread
                       engine:(BDPJSBridgeEngine)engine
                         type:(BDPJSBridgeMethodType)type
                      handler:(BDPJSBridgeContextMethod)handler;

/**
 @brief                     清理小程序上下文方法(API)
 @param uniqueID            小程序 uniqueID
 */
+ (void)clearContextMethod:(BDPUniqueID *)uniqueID;

/**
 @brief                     获取方法(API)同/异步模式
 @param method              调用方法(API)实例
 @param engine              调用引擎(BDPJSRuntime, BDPWebView, BDPH5WebView)
 @return                    是否为同步方法(API)
 */
+ (BOOL)obtainMethodSynchronize:(BDPJSBridgeMethod *)method
                         engine:(BDPJSBridgeEngine)engine;

/**
 @brief                     调用方法(API)
 @param method              调用方法(API)实例
 @param engine              调用引擎(BDPJSRuntime, BDPWebView, BDPH5WebView)
 @param completion          完成回调(同/异步模式取决于 API 实现是否为同步)
 */
+ (void)invokeMethod:(BDPJSBridgeMethod *)method
              engine:(BDPJSBridgeEngine)engine
          completion:(BDPJSBridgeCallback)completion;

/**
@brief                     API是否在主线程调用
@param fullName            API名.type的拼接
*/
- (BOOL)isOnMainThreadFullName:(NSString *)fullName;

/**
@brief                     API实现所在的类
@param fullName            API名.type的拼接
*/
- (Class)classForFullName:(NSString *)fullName;

+ (void)monitorDowngradeAPIWithMethod:(BDPJSBridgeMethod *)method uniqueID:(OPAppUniqueID *)uniqueID;

@end



