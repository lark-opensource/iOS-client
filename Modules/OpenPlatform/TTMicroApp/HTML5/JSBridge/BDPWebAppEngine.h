//
//  BDPWebAppEngine.h
//  Timor
//
//  Created by yin on 2020/3/25.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPJSBridgeProtocol.h>
#import <ECOProbe/OPTrace.h>

@interface BDPWebAppEngine : NSObject<BDPEngineProtocol, BDPJSBridgeEngineProtocol>

@property (nonatomic, copy) NSString *url;

#pragma mark BDPEngineProtocol & BDPJSBridgeEngineProtocol
/// 引擎唯一标示符
@property (nonatomic, strong, readonly, nonnull) BDPUniqueID *uniqueID;
/// 开放平台 JSBridge 方法类型
@property (nonatomic, assign, readonly) BDPJSBridgeMethodType bridgeType;
/// 调用 API 所在的 ViewController 环境
@property (nonatomic, weak, readonly, nullable) UIViewController *bridgeController;
/// 权限校验器
@property (nonatomic, strong, nullable) BDPJSBridgeAuthorization authorization;

- (void)bdp_evaluateJavaScript:(NSString * _Nonnull)script
                    completion:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))completion;
- (void)bdp_fireEventV2:(NSString *)event data:(NSDictionary *)data;  // data 支持 arrayBuffer
- (void)bdp_fireEvent:(NSString *)event sourceID:(NSInteger)sourceID data:(NSDictionary *)data;

#pragma mark 普通方法
/// 增加一个shouldUseNewbridgeProtocol的标志位，用于灰度
/// shouldUseNewbridgeProtocol代表是否使用了新的协议，webappengine看了一下代码是和controller生命周期挂钩，但是webvc加载不同的网页的时候，不同网页引入的jssdk可能是新的也可能是老的，需要兼容
+ (instancetype)getInstance:(UIViewController *)controller
                      jsImp:(id)jsImp
 shouldUseNewbridgeProtocol:(BOOL)shouldUseNewbridgeProtocol;
/// 网页调用tt系列API， params 必须封装为如下字典，否则无法兼容本类历史代码的调用和参数取值
/*
{
 "params": {
    业务数据
 },
 "callbackId": ""
}
*/
- (void)invokeMethod:(NSString *)methodName params:(NSDictionary *)params jsImp:(id)jsImp controller: (UIViewController *)controller needAuth:(BOOL)needAuth trace: (OPTrace *)trace webTrace: (OPTrace *)webTrace;

@end



