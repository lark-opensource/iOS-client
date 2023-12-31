//
//  GeneralJSRuntimeDelegate.h
//  OPJSEngine
//
//  Created by justin on 2022/12/22.
//

#import <Foundation/Foundation.h>
#import "BDPJSRuntimeSocketConnection.h"
#import <UIKit/UIKit.h>

// FROM: OPJSEngineProtocol.h 
@class JSValue;
@class BDPJSRuntimeSocketConnection;
@class BDPJSRuntimeSocketMessage;
@protocol GeneralJSRuntimeDelegate <NSObject>
// runtime 加载完成
- (void)runtimeLoad;
@optional
// runtime exception
- (void)runtimeException: (NSDictionary * _Nullable)data exception: (JSValue * _Nullable)exception;
// runtime 中断
- (void)runtimeInterrupt:(BOOL)stop;
// runtime publish消息到渲染层
- (void)runtimePublish:(NSString *)event param:(NSDictionary *)param appPageIDs:(NSArray<NSNumber *> *)appPageIDs useNewPublish:(BOOL)useNewPublish;
// 前端触发的onDocumentReady
- (void)runtimeOnDocumentReady;

// runtime 的bridge controller
- (UIViewController * __nullable) runtimeBridgeController;

// socket debug相关

- (void)socketDidConnected;
- (void)socketDidFailWithError:(NSError *)error;
- (void)socketDidCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;

// 连接状态变化，在JS线程调用
- (void)connection:(BDPJSRuntimeSocketConnection *)connection statusChanged:(BDPJSRuntimeSocketStatus)status;
// 收到消息，在JS线程调用
- (void)connection:(BDPJSRuntimeSocketConnection *)connection didReceiveMessage:(BDPJSRuntimeSocketMessage *)message;

// trace
- (void)bindCurrentThreadTracing;
- (void)bindCurrentThreadTracingFromUniqueID;

@end

