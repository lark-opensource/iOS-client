//
//  TMAPluginWebSocket.m
//  Timor
//
//  Created by muhuai on 2018/1/24.
//  Copyright © 2018年 muhuai. All rights reserved.
//

#import "TMAPluginWebSocket.h"
#import <ECOInfra/BDPLog.h>
#import <OPFoundation/BDPSDKConfig.h>
#import <OPFoundation/BDPUserAgent.h>
#import <OPFoundation/BDPTimorClient.h>
#import "BDPTaskManager.h"
#import <OPFoundation/BDPNotification.h>
#import <OPFoundation/BDPCommonManager.h>
#import "BDPURLProtocolManager.h"
#import "BDPInterruptionManager.h"
#import "BDPAPIInterruptionManager.h"
#import "TMAWebSocket.h"

#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <ECOInfra/BDPLog.h>

#import <SocketRocket/SRWebSocket.h>
#import <objc/runtime.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import "OPAPIDefine.h"
#import "TMAPluginNetworkDefines.h"

#define BACKGROUND_GUARD \
    if ([[BDPAPIInterruptionManager sharedManager] shouldInterruptionV2ForAppUniqueID:engine.uniqueID]) {   \
        response.errMsg = @"app in background"; \
        [response callback:OPGeneralAPICodeBackground];  \
        return; \
    }

static NSString *kSocketTaskIDKey = @"kSocketTaskIDKey";
static NSString *kBDPSocketTaskArrayBufferKey = @"kBDPSocketTaskArrayBufferKey";

@interface TMAPluginWebSocket() <SRWebSocketDelegate>

@property (nonatomic, assign) NSInteger lastestTaskID;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, TMAWebSocket *> *sockets;
@property (nonatomic, weak) BDPJSBridgeEngine engine;

@end

@implementation TMAPluginWebSocket

#pragma mark - Initialize
/*-----------------------------------------------*/
//             Initialize - 初始化相关
/*-----------------------------------------------*/

+ (BDPJSBridgePluginMode)pluginMode
{
    return BDPJSBridgePluginModeLifeCycle;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _lastestTaskID = 1;
        _sockets = [[NSMutableDictionary alloc] initWithCapacity:2];
        [self setupObserver];
    }
    return self;
}

- (void)dealloc
{
    [_sockets enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, TMAWebSocket * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj close];
    }];
}

#pragma mark - Function Implementation
/*-----------------------------------------------*/
//       Function Implementation - 功能实现
/*-----------------------------------------------*/
- (void)createSocketTaskWithParam:(NSDictionary *)param callback:(BDPJSBridgeCallback)callback engine:(BDPJSBridgeEngine)engine controller:(UIViewController *)controller
{
    OP_API_RESPONSE(OPAPIResponse)
    BACKGROUND_GUARD
    self.engine = engine;
    NSString *url = [param bdp_stringValueForKey:@"url"];
    OPAppUniqueID *uniqueID = engine.uniqueID;
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];

    if (engine.uniqueID.appType == OPAppTypeBlock) {
        NSString *failErrMsg = nil;
        id<BDPJSBridgeAuthorizationProtocol> auth = engine.authorization;
        if ([auth isKindOfClass:BDPAuthorization.class]) {
            BDPAuthorization *authorization = (BDPAuthorization *)auth;
            NSURL *realUrl = [NSURL URLWithString:url];
            BOOL canOpenSchema = [authorization checkSchema:&realUrl uniqueID:uniqueID errorMsg:&failErrMsg];
            if (!canOpenSchema) {
                OP_INVOKE_GUARD_NEW(YES, [response callback:CreateSocketTaskAPICodeInvalidUrl], @"[Block] url 权限校验失败")
            }
        }
    } else {
        OP_INVOKE_GUARD_NEW(![common.auth checkAuthorizationURL:url authType:BDPAuthorizationURLDomainTypeWebSocket], [response callback:CreateSocketTaskAPICodeInvalidUrl], @"url 权限校验失败")
    }
    
    NSMutableDictionary *mutableHeader = [param bdp_dictionaryValueForKey:@"header"] ? [[param bdp_dictionaryValueForKey:@"header"] mutableCopy] : [[NSMutableDictionary alloc] init];
    [mutableHeader setValue:[self referWithUniqueID:engine.uniqueID] forKey:BDP_REFERER_FIELD];
    NSDictionary *header = [mutableHeader copy];
    NSArray *protocols = [param bdp_arrayValueForKey:@"protocols"];
    //2018-11-1 如果外部传入空数组这里直接置nil，否则主端使用的SocketRocket-0.5.1版本会处理为空字符串导致socket连接失败
    if ([protocols count] <= 0) {
        protocols = nil;
    }
    NSString *method = [param stringValueForKey:@"method" defaultValue:@"GET"];

    NSURL *URL = [NSURL URLWithString:url];
    OP_INVOKE_GUARD_NEW(!URL, [response callback:RequestAPICodeInvalidUrl], ([NSString stringWithFormat:@"url is not valid domain, url == %@", url]))
    BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:engine.uniqueID];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
    request.timeoutInterval = task.config.networkTimeout.connectSocketTime.doubleValue / 1000;
    request.HTTPMethod = method;
    request.allHTTPHeaderFields = header;
    [request setValue:[BDPUserAgent getUserAgentString] forHTTPHeaderField:@"User-Agent"];
    TMAWebSocket *socket = [[TMAWebSocket alloc] initWithURLRequest:request.copy protocols:protocols];
    socket.delegate = self;
    [socket open];
    NSNumber *taskID = @([self generateTaskID]);
    
    objc_setAssociatedObject(socket, &kSocketTaskIDKey, taskID, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(socket, &kBDPSocketTaskArrayBufferKey, param[kBDPArrayBufferParam], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self.sockets setObject:socket forKey:taskID];
    
    OP_CALLBACK_WITH_DATA([response callback:OPGeneralAPICodeOk], @{@"socketTaskId": taskID})

    [TMAPluginWebSocketMonitorUtils startWithTaskId:taskID.integerValue
                                           uniqueId:engine.uniqueID
                                             params:@{
        kTMAPluginNetworkMonitorDomain: URL.host ?: @"",
        kTMAPluginNetworkMonitorPath: URL.path ?: @""
    }];
}

- (void)operateSocketTaskWithParam:(NSDictionary *)param callback:(BDPJSBridgeCallback)callback engine:(BDPJSBridgeEngine)engine controller:(UIViewController *)controller
{
    OP_API_RESPONSE(OPAPIResponse)
    BACKGROUND_GUARD
    self.engine = engine;

    NSInteger socketTaskId = [param bdp_integerValueForKey:@"socketTaskId"];
    NSString *operationType = [param bdp_stringValueForKey:@"operationType"];
    BDPLogInfo(@"[websocket API] operate (%@) socket (  %@)", operationType, @(socketTaskId));
    
    TMAWebSocket *socket = [self socketWithTaskID:socketTaskId];
    OP_INVOKE_GUARD_NEW(!socket, [response callback:OperateSocketTaskAPICodeSocketNoCreateSocketId], ([NSString stringWithFormat:@"socket no create socketId == %ld", (long)socketTaskId]))

    if ([operationType isEqualToString:@"send"]) {
        [self sendSocket:socket param:param];
        [response callback:OPGeneralAPICodeOk];
    } else if ([operationType isEqualToString:@"close"]) {
        socket.closeCode = SocketCloseTypeByUser;
        [self closeSocket:socket param:param];
        [response callback:OPGeneralAPICodeOk];
    }else{
        [response callback:OperateSocketTaskAPICodeIllegalOperationType];
    }
}

#pragma mark - SRWebSocketDelegate
/*-----------------------------------------------*/
//      SRWebSocketDelegate - WebSocket代理
/*-----------------------------------------------*/
- (void)sendSocket:(TMAWebSocket *)socket param:(NSDictionary *)param
{
    // Get Data
    id data = [param objectForKey:@"data"];
    
    // Check Data Legality
    if (data) {
        // Dictionary to NSString
        if ([data isKindOfClass:[NSDictionary class]]) {
            data = [TMAPluginWebSocket dictionaryToJsonStr:data];
        } else if ([data isKindOfClass:[NSNumber class]]) {
            data = [(NSNumber *)data stringValue];
        }
    } else if ([param bdp_arrayValueForKey:@"__nativeBuffers__"] && self.engine.uniqueID.appType == OPAppTypeBlock) {
        // data字段和__nativeBuffers字段是互斥关系，目前暂不用支持传ArrayBuffer

//        NSArray<NSDictionary *> *buffers = [param bdp_arrayValueForKey:@"__nativeBuffers__"];
//        id encodedString = [buffers objectAtIndex:0][@"base64"];
        id errMsg = @"Sending ArrayBuffer is not supported";
        [socket send:errMsg];
        return;
    }

    // Check After Process
    if (data && (![data isKindOfClass:[NSString class]] && ![data isKindOfClass:[NSData class]])) {
        data = nil;
    }

    // Send
    [socket send:data];
}

- (void)closeSocket:(TMAWebSocket *)socket param:(NSDictionary *)param
{
    NSInteger taskID = [self taskIDWithSocket:socket];
    NSInteger code = [param integerValueForKey:@"code" defaultValue:1000];
    NSString *reason = [param bdp_stringValueForKey:@"reason"];

    BDPLogInfo(@"[websocket API] close socket (%@) code: %@ reason: %@", @(taskID), @(code), reason);
    [socket closeWithCode:code reason:reason];
    [self.sockets removeObjectForKey:@(taskID)];
    [TMAPluginWebSocketMonitorUtils removeWithTaskId:taskID];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    NSInteger taskID = [self taskIDWithSocket:webSocket];
    id data = [message isKindOfClass:[NSString class]] || [message isKindOfClass:[NSData class]]? message: nil;
    // 如果是block的话单独走这个逻辑
    if (self.engine.uniqueID.appType == OPAppTypeBlock) {
        if (data && [data isKindOfClass:[NSData class]]) {
            data = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
    }
    NSMutableDictionary *resp = @{@"state": @"message",
                                  @"socketTaskId": @(taskID)}.mutableCopy;
    
    [resp setValue:data forKey:@"data"];
    if ([objc_getAssociatedObject(webSocket, &kBDPSocketTaskArrayBufferKey) boolValue]) {
        [self.engine bdp_fireEventV2:@"onSocketTaskStateChange" data:resp.copy];
    } else {
        [self.engine bdp_fireEvent:@"onSocketTaskStateChange" sourceID:NSNotFound data:resp.copy];
    }
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    NSInteger taskID = [self taskIDWithSocket:webSocket];
    BDPLogInfo(@"[websocket API] recieve socket (%@) opened callback", @(taskID));

    CFHTTPMessageRef message = [webSocket receivedHTTPHeaders];
    CFDictionaryRef headerRef = CFHTTPMessageCopyAllHeaderFields(message);
    NSDictionary *header = (__bridge NSDictionary *)headerRef;

    [self.engine bdp_fireEvent:@"onSocketTaskStateChange"
                      sourceID:NSNotFound
                          data:@{@"state": @"open",
                                 @"socketTaskId": @(taskID),
                                 @"header": header ?: @{}}];
    [TMAPluginWebSocketMonitorUtils endWithTaskId:taskID success:YES error:nil];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    NSInteger taskID = [self taskIDWithSocket:webSocket];
    BDPLogError(@"[websocket API] recieve socket (%@) failed callback, error: %@", @(taskID), error.localizedDescription);
    
    //2018-11-1 socket连接失败后，对外透出error信息
    NSMutableDictionary *dataDic = [[NSMutableDictionary alloc] init];
    if ([NetworkLarkFeatureGatingDependcy addSocketCloseInfoEnable]) {
        [self.sockets removeObjectForKey:@(taskID)];
        [dataDic setObject:@"close" forKey:@"state"];
        [dataDic setObject:@(SocketCloseTypeOccurError) forKey:@"closeType"];
        [dataDic setObject:[self socketCloseMsgForType:SocketCloseTypeOccurError] forKey:@"closeMsg"];
    } else {
        [dataDic setObject:@"error" forKey:@"state"];
        if (error) {
            NSString *errorString = [NSString stringWithFormat:@"%ld : %@", (long)error.code, error.localizedDescription];
            [dataDic setObject:errorString forKey:@"errMsg"];
            BDPLogInfo(@"[websocket API] socket (%@) error, errorString: %@", @(taskID), errorString);
        }
    }
    
    [dataDic setObject:@(taskID) forKey:@"socketTaskId"];
    
    [self.engine bdp_fireEvent:@"onSocketTaskStateChange" sourceID:NSNotFound data:[dataDic copy]];
    [TMAPluginWebSocketMonitorUtils endWithTaskId:taskID success:NO error:error];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    NSInteger taskID = [self taskIDWithSocket:webSocket];
    [TMAPluginWebSocketMonitorUtils removeWithTaskId:taskID];
    BDPLogInfo(@"[websocket API] recieve socket (%@) closed callback, code: %@, reason: %@, wasClean: %@", @(taskID), @(code), reason, @(wasClean));

    if ([NetworkLarkFeatureGatingDependcy addSocketCloseInfoEnable]) {
        SocketCloseType closeCode = SocketCloseTypeUnknown;
        if ([webSocket isKindOfClass:[TMAWebSocket class]]) {
            TMAWebSocket *socket = (TMAWebSocket *)webSocket;
            closeCode = socket.closeCode;
        }
        NSString *closeReason = [self socketCloseMsgForType:closeCode];
        BDPLogInfo(@"[websocket API] socket (%@) closed, code: %@, reason: %@, wasClean: %@", @(taskID), @(closeCode), closeReason, @(wasClean));
        [self.engine bdp_fireEvent:@"onSocketTaskStateChange"
                          sourceID:NSNotFound
                              data:@{@"state": @"close",
                                     @"socketTaskId": @(taskID), @"closeType": @(closeCode), @"closeMsg": closeReason}];
    } else {
        [self.engine bdp_fireEvent:@"onSocketTaskStateChange"
                          sourceID:NSNotFound
                              data:@{@"state": @"close",
                                     @"socketTaskId": @(taskID)}];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload
{
    __unused NSInteger taskID = [self taskIDWithSocket:webSocket];
}

#pragma mark - Notification Observer
/*-----------------------------------------------*/
//         Notification Observer - 通知
/*-----------------------------------------------*/
- (void)setupObserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleInterruption:)
                                                 name:kBDPAPIInterruptionV2Notification object:nil];
}

- (void)handleInterruption:(NSNotification *)aNotification
{
    BDPUniqueID *uniqueID = [aNotification.userInfo bdp_objectForKey:kBDPUniqueIDUserInfoKey ofClass:[BDPUniqueID class]];
    BDPInterruptionStatus status = [aNotification.userInfo bdp_integerValueForKey:kBDPInterruptionUserInfoStatusKey];

    BDPLogInfo(@"[websocket API] handle interruption, status: %@, unique id: %@, current unique id: %@", @(status), uniqueID, self.engine.uniqueID);

    if (![uniqueID isEqual:self.engine.uniqueID]) {
        BDPLogError(@"[websocket API] handle interruption, unique id %@ not equal to current:%@", uniqueID, self.engine.uniqueID);
        return;
    }
    
    if (status == BDPInterruptionStatusBegin) {
        NSArray<TMAWebSocket *> *allTasks = self.sockets.allValues;
        [allTasks enumerateObjectsUsingBlock:^(TMAWebSocket * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.closeCode = SocketCloseTypeAppInBackground;
            [self closeSocket:obj param:@{@"code": @(1000),
                                          @"reason": @"app in background"}];
        }];
    }
}

#pragma mark - Utils
/*-----------------------------------------------*/
//                  Utils - 工具
/*-----------------------------------------------*/
- (NSInteger)taskIDWithSocket:(SRWebSocket *)socket
{
    NSNumber *taskID = objc_getAssociatedObject(socket, &kSocketTaskIDKey);
    return [taskID integerValue];
}

- (TMAWebSocket *)socketWithTaskID:(NSInteger)taskID
{
    return [self.sockets objectForKey:@(taskID)];
}

- (NSInteger)generateTaskID
{
    return _lastestTaskID++;
}

+ (NSString *)dictionaryToJsonStr:(NSDictionary *)dict
{
    NSString *jsonString = nil;
    if ([NSJSONSerialization isValidJSONObject:dict])
    {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
        jsonString =[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        if (error) {
            BDPLogError(@"CsoWhy Log:[DictToJson Error]%@" , error);
        }
    }
    return jsonString;
}

- (NSString *)referWithUniqueID:(OPAppUniqueID *)uniqueID
{
    BDPPlugin(networkPlugin, BDPNetworkPluginDelegate);
    NSString *referString;
    if ([networkPlugin respondsToSelector:@selector(bdp_customReferWithUniqueID:)]) {
        referString = [networkPlugin bdp_customReferWithUniqueID:uniqueID];
    } else {
        BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
        referString = [BDPURLProtocolManager serviceReferer:common.uniqueID version:common.model.version];
    }
    return referString;
}

- (NSString *)socketCloseMsgForType:(SocketCloseType)type
{
    switch (type) {
        case SocketCloseTypeUnknown:
            return @"socket closed: unknown";
        case SocketCloseTypeByUser:
            return @"socket closed: by user";
        case SocketCloseTypeAppInBackground:
            return @"socket closed: app in background";
        case SocketCloseTypeOccurError:
            return @"socket closed: occur error";
        default:
            return @"";
    }
}

@end
