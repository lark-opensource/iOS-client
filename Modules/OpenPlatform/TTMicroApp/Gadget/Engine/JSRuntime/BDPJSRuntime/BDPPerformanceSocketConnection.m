//
//  BDPPerformanceSocketConnection.m
//  TTMicroApp
//
//  Created by ChenMengqi on 2022/12/12.
//

#import "BDPPerformanceSocketConnection.h"
#import <SocketRocket/SRWebSocket.h>
#import <ECOInfra/BDPUtils.h>
#import <ECOInfra/BDPLog.h>

static BOOL g_hasConnection = NO;

@interface BDPPerformanceSocketConnection()<SRWebSocketDelegate>

@property (nonatomic, copy) NSString *address;
@property (nonatomic, strong) SRWebSocket *socket;
@property (nonatomic, weak) id<BDPPerformanceSocketConnectionDelegate> delegate;
@property (nonatomic, assign, readwrite) BDPPerformanceSocketStatus status;


@end

@implementation BDPPerformanceSocketConnection

+ (instancetype)createConnectionWithAddress:(NSString *)address
                                   delegate:(id<BDPPerformanceSocketConnectionDelegate>)delegate{
    if (g_hasConnection) {
        return nil;
    }
    return [[BDPPerformanceSocketConnection alloc] initWithAddress:address delegate:delegate];
}

- (instancetype)initWithAddress:(NSString *)address
                       delegate:(id<BDPPerformanceSocketConnectionDelegate>)delegate
{
    if (self = [super init]) {
        _address = address.copy;
        _delegate = delegate;
        [self connect];
        BDPLogInfo(@"[PerformanceProfile] get connect");
    }
    g_hasConnection = YES;
    return self;
}

- (void)dealloc {
    if (self.socket) {
        [self disConnect];
    }
    g_hasConnection = NO;
}

- (void)connect {
    if (self.status != BDPPerformanceSocketStatusDisconnected) {
        return;
    }
    if (self.socket) {
        self.socket.delegate = nil;
        [self.socket close];
        self.socket = nil;
    }

    self.status = BDPPerformanceSocketStatusConnecting;

    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:self.address];
    NSURL *url = urlComponents.URL;
    if (!url) {
        BDPLogWarn(@"[PerformanceProfile] performance profile address url is nil");
        self.status = BDPPerformanceSocketStatusDisconnected;
        return;
    }

    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    self.socket = [[SRWebSocket alloc] initWithURLRequest:request.copy];
    self.socket.delegateDispatchQueue = dispatch_queue_create("com.bytedance.bdpperformancesocket", DISPATCH_QUEUE_CONCURRENT);
    self.socket.delegate = self;
    [self.socket open];

}

- (void)disConnect {
    if (self.status == BDPPerformanceSocketStatusDisconnected) {
        return;
    }
    if (self.socket == nil) {
        return;
    }
    [self.socket close];
    [self _connectionDidClosed];

}

- (BOOL)sendMessage:(BDPPerformanceSocketMessage *)message{
    NSString *string = [message string];
    NSError *error = nil;
    [self.socket sendString:string error:&error];
    if (error) {
        BDPLogError(@"[PerformanceProfile] socket sendMessage error %@", error.localizedDescription);
        return NO;
    }
    return YES;
}

-(void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message{
    BDPPerformanceSocketMessage *socketMessage = [BDPPerformanceSocketMessage messageWithString:message];
    BDPLogInfo(@"[PerformanceProfile] Profile didReceiveMessage %@", message);
    if (socketMessage) {
        if ([self.delegate respondsToSelector:@selector(connection:didReceiveMessage:)]) {
            [self.delegate connection:self didReceiveMessage:socketMessage];
        }
    }
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    BDPLogInfo(@"[PerformanceProfile] webSocketDidOpen, address=%@", self.address);
    self.status = BDPPerformanceSocketStatusConnected;

    if ([self.delegate respondsToSelector:@selector(socketDidConnected)]) {
        [self.delegate socketDidConnected];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    BDPLogWarn(@"[PerformanceProfile] webSocket didFailWithError, address=%@, error=%@", self.address, error);
    [self _connectionFailed];
    if ([self.delegate respondsToSelector:@selector(socketDidFailWithError:)]) {
        [self.delegate socketDidFailWithError:error];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    BDPLogInfo(@"[PerformanceProfile] webSocket didCloseWithCode, address=%@, code=%@, reason=%@, wasClean=%@", self.address, @(code), reason, @(wasClean));
    [self _connectionDidClosed];
    if ([self.delegate respondsToSelector:@selector(socketDidCloseWithCode:reason:wasClean:)]) {
        [self.delegate socketDidCloseWithCode:code reason:reason wasClean:wasClean];
    }
}


- (void)_connectionDidClosed {
    self.socket.delegate = nil;
    self.socket = nil;
    self.status = BDPPerformanceSocketStatusDisconnected;
    g_hasConnection = NO;
}

- (void)_connectionFailed {
    self.socket.delegate = nil;
    self.socket = nil;
    self.status = BDPPerformanceSocketStatusFailed;
    g_hasConnection = NO;
}

- (void)setStatus:(BDPPerformanceSocketStatus)status {
    if (_status != status) {
        _status = status;
        if ([self.delegate respondsToSelector:@selector(connection:statusChanged:)]) {
            [self.delegate connection:self statusChanged:status];
        }
    }
}


@end
