//
//  BDPJSRuntimeSocketConnection.h
//  Timor
//
//  Created by tujinqiu on 2020/4/7.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "BDPJSRunningThreadAsyncDispatchQueue.h"

NS_ASSUME_NONNULL_BEGIN

// 参考 https://bytedance.feishu.cn/docs/doccndgXUKFyxsOckM004XjDdyl 定义
// 用于建立IDE和真机之间的socket链接，接受IDE的消息并解析，发送消息给IDE

@interface BDPJSRuntimeSocketMessage : NSObject

@property (nonatomic, copy) NSString *name; // 调用的名称，invoke, invokeHandler, ... 等
@property (nonatomic, copy) NSString *event; // 具体API名称，比如setStorage，或者断点的paused，resumed等
@property (nonatomic, copy) NSString *params; // api的参数
@property (nonatomic, copy) NSDictionary *paramsDict; // api的参数，用于call调用中
@property (nonatomic, strong) NSNumber *callbackId; // 回调id
@property (nonatomic, copy) NSString *webviewIds; // webviewid列表
@property (nonatomic, copy) NSString *timerType; // setTimer中的参数：类型
@property (nonatomic, assign) NSInteger timerId; // setTimer中的参数：timer的id
@property (nonatomic, assign) NSInteger time; // setTimer中的参数：时长
@property (nonatomic, copy) NSString *result; // 同步调用的返回值参数
@property (nonatomic, copy) NSString *data; // ttJSBridge调用的参数
@property (nonatomic, strong) NSNumber *webviewId; // ttJSBridge调用的webview id
@property (nonatomic, copy) NSDictionary *workerInitParams; // 真机调试时的 jsruntime 初始化参数

// 将从ide获取到的数据解析成message
+ (instancetype)messageWithString:(NSString *)string;
// 将message转成string，用于发送给ide
- (NSString *)string;
// 是否是命中断点的消息
- (BOOL)isPausedInspector;
// 是否是继续断点的消息
- (BOOL)isResumedInspector;

@end

typedef NS_ENUM(NSUInteger, BDPJSRuntimeSocketStatus) {
    BDPJSRuntimeSocketStatusDisconnected = 0, // 未连接
    BDPJSRuntimeSocketStatusConnecting,   // 连接中
    BDPJSRuntimeSocketStatusConnected,    // 已连接
    BDPJSRuntimeSocketStatusFailed,     // 连接失败
};

@class BDPJSRuntimeSocketConnection;

@protocol BDPJSRuntimeSocketConnectionDelegate <NSObject>

@required
// 连接状态变化，在JS线程调用
- (void)connection:(BDPJSRuntimeSocketConnection *)connection statusChanged:(BDPJSRuntimeSocketStatus)status;
// 收到消息，在JS线程调用
- (void)connection:(BDPJSRuntimeSocketConnection *)connection didReceiveMessage:(BDPJSRuntimeSocketMessage *)message;

@optional
- (void)socketDidConnected;
- (void)socketDidFailWithError:(NSError *)error;
- (void)socketDidCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;

@end

@interface BDPJSRuntimeSocketConnection : NSObject

@property (nonatomic, assign, readonly) BDPJSRuntimeSocketStatus status;

// 是否存在链接，主线程调用
+ (BOOL)hasConnection;
// 创建连接对象，在JS线程调用
+ (instancetype)createConnectionWithAddress:(NSString *)address
                                    jsQueue:(BDPJSRunningThreadAsyncDispatchQueue *)jsQueue
                                   delegate:(id<BDPJSRuntimeSocketConnectionDelegate>)delegate;

// 开始连接，在JS线程调用
- (void)connect;
// 断开连接，在JS线程调用
- (void)disConnect;
// 发送消息，在JS线程调用
- (BOOL)sendMessage:(BDPJSRuntimeSocketMessage *)message;

@end

NS_ASSUME_NONNULL_END
