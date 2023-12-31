//
//  EMADebuggerConnection.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/7/23.
//

#import "EMADebuggerConnection.h"
#import <SocketRocket/SRWebSocket.h>
#import <OPFoundation/BDPDeviceHelper.h>
#import "EMADebuggerMetaCommand.h"
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/NSURLComponents+EMA.h>

@interface EMADebuggerConnection() <SRWebSocketDelegate>

@property (nonatomic, copy, readwrite, nullable) NSString *url;
@property (nonatomic, assign, readwrite) EMADebuggerConnectionStatus status;
@property (nonatomic, strong, nullable) SRWebSocket *socket;
@property (nonatomic, strong, nullable) OPAppUniqueID *uniqueID;
@property (nonatomic, copy, nullable) NSString *appName;
@property (nonatomic, assign) NSUInteger mid;   // 最新的消息id
@property (nonatomic, copy) void (^completion)(BOOL success);
@property (nonatomic, assign) BOOL metaPushed;  // 是否已经推送了meta信息

@end

@implementation EMADebuggerConnection

- (instancetype)initWithUrl:(NSString * _Nonnull)url uniqueID:(BDPUniqueID * _Nonnull)uniqueID
{
    self = [super init];
    if (self) {
        _url = url;
        _uniqueID = uniqueID;
        _mid = 0;
        _metaPushed = NO;
        _status = EMADebuggerConnectionStatusDisconnected;
    }
    return self;
}

- (void)dealloc {
    if (self.socket) {
        [self disconnect];
    }
}

- (void)connectWithCompletion:(void (^ _Nullable)(BOOL success))completion {
    BDPLogInfo(@"connect, uniqueID=%@, url=%@", self.uniqueID, self.url);
    self.completion = completion;
    if (self.socket) {
        self.socket.delegate = nil;
        [self.socket close];
        self.socket = nil;
    }

    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:self.url];
    [urlComponents setQueryItemWithKey:@"from" value:@"device"];
    NSURL *url = urlComponents.URL;
    if (!url) {
        BDPLogWarn(@"url is nil");
        if (completion) {
            completion(NO);
            self.completion = nil;
        }
        return;
    }

    self.status = EMADebuggerConnectionStatusConnecting;

    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    
    self.socket = [[SRWebSocket alloc] initWithURLRequest:request.copy];
    self.socket.delegate = self;
    [self.socket open];
}

- (void)disconnect {
    BDPLogInfo(@"disconnect, uniqueID=%@", self.uniqueID);
    [self.socket close];
    [self didSocketClosed];
}

- (BOOL)pushCmd:(EMADebuggerCommand * _Nonnull)cmd {
    if (!cmd) {
        BDPLogWarn(@"cmd is nil");
        return NO;
    }

    if (self.status != EMADebuggerConnectionStatusConnected) {
        BDPLogWarn(@"not connected");
        return NO;
    }

    if (self.socket.readyState != SR_OPEN) {
        BDPLogWarn(@"websocket not open");
        return NO;
    }

    cmd.mid = (self.mid++);
    NSString *message = cmd.jsonMessage;

    if (BDPIsEmptyString(message)) {
        BDPLogWarn(@"message is empty");
        return NO;
    }

    NSError *error = nil;
    [self.socket sendString:message error:&error];
    if (error) {
        BDPLogError(@"send msg error %@", BDPParamStr(error))
        return NO;
    }
    return YES;
}

- (void)setMetaInfo:(NSString *)appName {
    self.appName = appName;

    if (!BDPIsEmptyString(self.appName) && self.status == EMADebuggerConnectionStatusConnected && !self.metaPushed) {
        BDPLogInfo(@"pushCmd setMetaInfo %@", BDPParamStr(self.uniqueID, self.appName));
        EMADebuggerMetaCommand *command = [[EMADebuggerMetaCommand alloc] init];
        command.appId = self.uniqueID.appID;
        command.appName = self.appName;
        command.phoneBrand = [BDPDeviceHelper getDeviceName];
        if ([self pushCmd:command]) {
            self.metaPushed = YES;
        }
    }
}

- (void)didSocketClosed {
    self.status = EMADebuggerConnectionStatusDisconnected;
    if (self.socket) {
        self.socket.delegate = nil;
        self.socket = nil;
    }
    if (self.completion) {
        self.completion(NO);
        self.completion = nil;
    }
}

#pragma mark - SRWebSocketDelegate
- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    BDPLogInfo(@"webSocketDidOpen");
    self.status = EMADebuggerConnectionStatusConnected;
    [self setMetaInfo:self.appName];    // 连接成功后尝试发送MetaInfo
    if (self.completion) {
        self.completion(YES);
        self.completion = nil;
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    BDPLogWarn(@"webSocket fail, e=%@", error);
    [self didSocketClosed];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    BDPLogInfo(@"webSocket close, code=%@, reason=%@, wasClean=%@", @(code), reason, @(wasClean));
    [self didSocketClosed];
}

@end
