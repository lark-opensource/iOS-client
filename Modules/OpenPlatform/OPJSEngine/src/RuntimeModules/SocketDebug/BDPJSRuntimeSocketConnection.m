//
//  BDPJSRuntimeSocketConnection.m
//  Timor
//
//  Created by tujinqiu on 2020/4/7.
//

#import "BDPJSRuntimeSocketConnection.h"
#import <ECOInfra/JSONValue+BDPExtension.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
//#import "BDPUtils.h"
#import "OPJSEngineMacroUtils.h"
#import <ECOInfra/OPMacroUtils.h>
#import <ECOInfra/BDPUtils.h>

#import <OPJSEngine/OPJSEngine-Swift.h>
#import <ECOInfra/BDPLog.h>

#import <SocketRocket/SRWebSocket.h>
//#import "NSURLComponents+BDPExtension.h"


NS_ASSUME_NONNULL_BEGIN

@interface NSURLComponents (OPExtension)

// 给url添加参数的便捷方法
- (void)op_setQueryItemWithKey:(NSString * _Nonnull)key value:(NSString * _Nullable)value;

@end

NS_ASSUME_NONNULL_END


@implementation NSURLComponents (OPExtension)

- (void)op_setQueryItemWithKey:(NSString * _Nonnull)key value:(NSString * _Nullable)value {
    if (BDPIsEmptyString(key)) {
        return;
    }
    NSMutableArray *queryItems = NSMutableArray.array;
    BOOL added = NO;
    for (NSURLQueryItem * queryItem in self.queryItems) {
        if (![key isEqualToString:queryItem.name]) {
            [queryItems addObject:queryItem];
        } else {
            if (!BDPIsEmptyString(value)) {
                [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:value]];
                added = YES;
            }
        }
    }
    if (!added && !BDPIsEmptyString(value)) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:value]];
    }
    self.queryItems = queryItems.copy;
}

@end

@implementation BDPJSRuntimeSocketMessage

+ (instancetype)messageWithString:(NSString *)string
{
    NSDictionary *dict = [self _dictWithString:string];
    if (BDPIsEmptyDictionary(dict)) {
        return nil;
    }
    BDPJSRuntimeSocketMessage *message = [BDPJSRuntimeSocketMessage new];
    message.name = [dict bdp_stringValueForKey:@"name"];
    message.event = [dict bdp_stringValueForKey:@"event"];
    // params 在 call 调用中是 dict，其他时候为 string
    NSDictionary *paramsDict = [dict bdp_dictionaryValueForKey:@"params"];
    if (!BDPIsEmptyDictionary(paramsDict)) {
        message.paramsDict = paramsDict;
    } else {
        message.params = [dict bdp_stringValueForKey:@"params"];
    }
    message.callbackId = @([dict bdp_integerValueForKey:@"callbackId"]);
    message.webviewIds = [dict bdp_stringValueForKey:@"webviewIds"];
    message.timerType = [dict bdp_stringValueForKey:@"timerType"];
    message.timerId = [dict bdp_integerValueForKey:@"timerId"];
    message.time = [dict bdp_integerValueForKey:@"time"];

    return message;
}

- (NSString *)string
{
    NSMutableDictionary *dict = [NSMutableDictionary new];
    if (!BDPIsEmptyString(self.name)) {
        [dict setValue:self.name forKey:@"name"];
    }
    if (!BDPIsEmptyString(self.event)) {
        [dict setValue:self.event forKey:@"event"];
    }
    if (!BDPIsEmptyDictionary(self.paramsDict)) {
        [dict setValue:self.paramsDict forKey:@"params"];
    }
    if (!BDPIsEmptyString(self.params)) {
        [dict setValue:self.params forKey:@"params"];
    }
    if (self.callbackId) {
        [dict setValue:self.callbackId forKey:@"callbackId"];
    }
    if (!BDPIsEmptyString(self.webviewIds)) {
        [dict setValue:self.webviewIds forKey:@"webviewIds"];
    }
    if (!BDPIsEmptyString(self.result)) {
        [dict setValue:self.result forKey:@"result"];
    }
    if (!BDPIsEmptyString(self.data)) {
        [dict setValue:self.data forKey:@"data"];
    }
    if (self.webviewId) {
        [dict setValue:self.webviewId forKey:@"webviewId"];
    }
    if (!BDPIsEmptyDictionary(self.workerInitParams)) {
        [dict setValue:self.workerInitParams forKey:@"data"];
    }
    return [dict JSONRepresentation];
}

- (BOOL)isPausedInspector
{
    return [self.name isEqualToString:@"inspector"] && [self.event isEqualToString:@"paused"];
}

- (BOOL)isResumedInspector
{
    return [self.name isEqualToString:@"inspector"] && [self.event isEqualToString:@"resumed"];
}

+ (NSDictionary *)_dictWithString:(NSString *)string
{
    NSDictionary *dict = nil;
    id paramDict = [string JSONValue];
    if ([paramDict isKindOfClass:[NSString class]]) {
        dict = [(NSString *)paramDict JSONValue];
    } else if ([paramDict isKindOfClass:[NSDictionary class]]) {
        dict = [paramDict decodeNativeBuffersIfNeed];
    }
    if ([dict isKindOfClass:[NSDictionary class]]) {
        return dict;
    }
    return nil;
}

@end






static BOOL g_hasConnection = NO;

@interface BDPJSRuntimeSocketConnection ()<SRWebSocketDelegate>

@property (nonatomic, copy) NSString *address;
@property (nonatomic, strong) SRWebSocket *socket;
@property (nonatomic, weak) id<BDPJSRuntimeSocketConnectionDelegate> delegate;
@property (nonatomic, strong) BDPJSRunningThreadAsyncDispatchQueue *jsQueue;

@end

@implementation BDPJSRuntimeSocketConnection

+ (BOOL)hasConnection
{
    return g_hasConnection;
}

+ (instancetype)createConnectionWithAddress:(NSString *)address
                                    jsQueue:(BDPJSRunningThreadAsyncDispatchQueue *)jsQueue
                                   delegate:(id<BDPJSRuntimeSocketConnectionDelegate>)delegate
{
    __block BOOL hasConnection = NO;
    [[[OPJSEngineService shared] utils] executeOnMainQueueSync:^{
        hasConnection = g_hasConnection;
    }];
    if (hasConnection) {
        return nil;
    }
    return [[BDPJSRuntimeSocketConnection alloc] initWithAddress:address jsQueue:jsQueue delegate:delegate];
}

- (instancetype)initWithAddress:(NSString *)address
                        jsQueue:(BDPJSRunningThreadAsyncDispatchQueue *)jsQueue
                       delegate:(id<BDPJSRuntimeSocketConnectionDelegate>)delegate
{
    if (self = [super init]) {
        _address = address.copy;
        _jsQueue = jsQueue;
        _delegate = delegate;
        [self connect];
    }
    [[[OPJSEngineService shared] utils] executeOnMainQueue:^{
        g_hasConnection = YES;
    }];
    return self;
}

- (void)dealloc {
    if (self.socket) {
        [self disConnect];
    }
    [[[OPJSEngineService shared] utils] executeOnMainQueue:^{
        g_hasConnection = NO;
    }];
}

- (void)connect
{
    if (self.status != BDPJSRuntimeSocketStatusDisconnected) {
        return;
    }
    if (self.socket) {
        self.socket.delegate = nil;
        [self.socket close];
        self.socket = nil;
    }

    self.status = BDPJSRuntimeSocketStatusConnecting;

    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:self.address];
    // 通过url后面加参数的方式告知ide一些必要的环境参数
    [urlComponents op_setQueryItemWithKey:@"from" value:@"for_device_debug"];
    [urlComponents op_setQueryItemWithKey:@"platform" value:@"ios"];
    NSURL *url = urlComponents.URL;
    if (!url) {
        BDPLogWarn(@"url is nil");
        self.status = BDPJSRuntimeSocketStatusDisconnected;
        return;
    }

    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    self.socket = [[SRWebSocket alloc] initWithURLRequest:request.copy];
    self.socket.delegateDispatchQueue = dispatch_queue_create("com.bytedance.bdpjssocket", DISPATCH_QUEUE_CONCURRENT);
    self.socket.delegate = self;
    [self.socket open];
}

- (void)disConnect
{
    if (self.status == BDPJSRuntimeSocketStatusDisconnected) {
        return;
    }
    if (self.socket == nil) {
        return;
    }
    [self.socket close];
    [self _connectionDidClosed];
}

- (BOOL)sendMessage:(BDPJSRuntimeSocketMessage *)message
{
    NSString *string = [message string];
    if (BDPIsEmptyString(string)) {
        BDPLogWarn(@"empty");
        return NO;
    }
    if (self.status != BDPJSRuntimeSocketStatusConnected) {
        BDPLogWarn(@"not connected for name:%@", message.name);
        return NO;
    }
    if (self.socket.readyState != SR_OPEN) {
        BDPLogWarn(@"websocket not open");
        return NO;
    }
    NSError *error = nil;
    [self.socket sendString:string error:&error];
    if (error) {
        BDPLogError(@"send msg error %@", BDPParamStr(error))
        return NO;
    }
    return YES;
}

- (void)_connectionDidClosed
{
    self.socket.delegate = nil;
    self.socket = nil;
    self.status = BDPJSRuntimeSocketStatusDisconnected;
    [[[OPJSEngineService shared] utils] executeOnMainQueue:^{
        g_hasConnection = NO;
    }];
}

- (void)_connectionFailed
{
    self.socket.delegate = nil;
    self.socket = nil;
    self.status = BDPJSRuntimeSocketStatusFailed;
    [[[OPJSEngineService shared] utils] executeOnMainQueue:^{
        g_hasConnection = NO;
    }];
}

- (void)setStatus:(BDPJSRuntimeSocketStatus)status
{
    if (_status != status) {
        _status = status;
        if ([self.delegate respondsToSelector:@selector(connection:statusChanged:)]) {
            [self.delegate connection:self statusChanged:status];
        }
    }
}

#pragma mark - SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    BDPLogInfo(@"webSocketDidOpen, address=%@", self.address);
    WeakSelf;
    [self.jsQueue dispatchASync:^{
        StrongSelfIfNilReturn
        self.status = BDPJSRuntimeSocketStatusConnected;
    }];

    if ([self.delegate respondsToSelector:@selector(socketDidConnected)]) {
        [self.delegate socketDidConnected];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    BDPLogWarn(@"webSocket didFailWithError, address=%@, error=%@", self.address, error);
    WeakSelf;
    [self.jsQueue dispatchASync:^{
        StrongSelfIfNilReturn
        [self _connectionFailed];
    }];
    if ([self.delegate respondsToSelector:@selector(socketDidFailWithError:)]) {
        [self.delegate socketDidFailWithError:error];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    BDPLogInfo(@"webSocket didCloseWithCode, address=%@, code=%@, reason=%@, wasClean=%@", self.address, @(code), reason, @(wasClean));
    WeakSelf;
    [self.jsQueue dispatchASync:^{
        StrongSelfIfNilReturn
        [self _connectionDidClosed];
    }];
    if ([self.delegate respondsToSelector:@selector(socketDidCloseWithCode:reason:wasClean:)]) {
        [self.delegate socketDidCloseWithCode:code reason:reason wasClean:wasClean];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessageWithString:(NSString *)string
{
    BDPLogInfo(@"receive message, address=%@", self.address);
    WeakSelf;
    [self.jsQueue dispatchASync:^{
        StrongSelfIfNilReturn
        BDPJSRuntimeSocketMessage *message = [BDPJSRuntimeSocketMessage messageWithString:string];
        if (message) {
            if ([self.delegate respondsToSelector:@selector(connection:didReceiveMessage:)]) {
                [self.delegate connection:self didReceiveMessage:message];
            }
        }
    }];
}

@end
