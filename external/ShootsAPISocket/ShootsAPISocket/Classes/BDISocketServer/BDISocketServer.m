//
//  BDISocketServer.m
//  BDiOSpy
//
//  Created by byte dance on 2021/7/29.
//

#import "BDISocketServer.h"

#if __has_include(<CocoaAsyncSocket/GCDAsyncSocket.h>)
#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#else
#import "GCDAsyncSocket.h"
#endif

#import "BDIAPIHandler.h"
#import <objc/runtime.h>
#import "BDIRPCResponse.h"

@interface BDISocketServer () <GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket *serverSocket;
@property (nonatomic, strong) NSMutableArray<GCDAsyncSocket *> *clientSockets;
@property (nonatomic, strong) NSMutableDictionary *bufferDict;
@property (nonatomic, strong) dispatch_queue_t socketQueue;

@property (nonatomic, strong) NSMutableDictionary<NSString *, BDIRPCRoute *> *routeDict;
@property (nonatomic, assign) BOOL keepAlive;
@property (nonatomic, assign) BOOL started;

@end

@implementation BDISocketServer

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            NSDictionary *envs = [[NSProcessInfo processInfo] environment];
            if ([envs valueForKey:@"SHOOTS_ENABLE_API_SOCKET"]) {
                [[BDISocketServer sharedServer] startServer:NO];
            }
        }];
    });
}

+ (instancetype)sharedServer
{
    static BDISocketServer *sharedServer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedServer = [[self alloc] init];
    });
    return sharedServer;
}

+ (int)getPort
{
    BDISocketServer *sharedServer = [BDISocketServer sharedServer];
    return sharedServer.serverSocket.localPort;
}

+ (BOOL)pushMessage:(id)message
{
    BDISocketServer *sharedServer = [BDISocketServer sharedServer];
    for (GCDAsyncSocket *clientSocket in sharedServer.clientSockets){
        BDIRPCResponse *pushResponse = [BDIRPCResponse responsePushMessage:message];
        [sharedServer sendJson:pushResponse.JSON toSock:clientSocket];
    }
    return YES;
}

- (instancetype)init
{
    if (self = [super init])
    {
        _socketQueue = dispatch_queue_create("org.shoots.server", DISPATCH_QUEUE_SERIAL);
        _serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_socketQueue];
        _clientSockets = [NSMutableArray array];
        _bufferDict = [NSMutableDictionary dictionary];
        _routeDict = [NSMutableDictionary dictionary];
        _started = NO;
    }
    return self;
}

- (void)startServer:(BOOL)needRunloop
{
    [self registerRouteHandlers:@[NSClassFromString(@"BDIDemoAPIs")]];
    
    NSError *error = nil;
    BOOL success = [self.serverSocket acceptOnPort:0 error:&error];
    if (success) {
        NSFileManager *fs = [NSFileManager defaultManager];
        NSString *tmp = NSTemporaryDirectory();
        NSString *port_file_name = [NSString stringWithFormat:@"%d.rpc_port", [NSProcessInfo processInfo].processIdentifier];
        NSString *rpc_port_file = [tmp stringByAppendingPathComponent:port_file_name];
        NSArray *tmpItems = [fs contentsOfDirectoryAtPath:tmp error:nil];
        for (NSString *item in tmpItems){
            if ([item hasSuffix:@".rpc_port"]){
                NSString *itemFilePath = [tmp stringByAppendingPathComponent:item];
                [fs removeItemAtPath:itemFilePath error:nil];
            }
        }
        NSString *port_str = [NSString stringWithFormat:@"%d", self.serverSocket.localPort];
        [port_str writeToFile:rpc_port_file atomically:YES encoding:NSUTF8StringEncoding error:nil];
        self.started = YES;
        NSLog(@"[SHOOTS_API_TEST]start socket server at: %@", port_str);
    } else {
        NSLog(@"[SHOOTS_API_TEST]start socket server failed: %@", error.description);
    }
    
    if (needRunloop) {
        self.keepAlive = YES;
        NSRunLoop *runloop = [NSRunLoop mainRunLoop];
        while (self.keepAlive && [runloop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    }
    
}

+ (void)start:(BOOL)needRunloop
{
    BDISocketServer *socketServer = [BDISocketServer sharedServer];
    if (!socketServer.started) {
        [[BDISocketServer sharedServer] startServer:needRunloop];
    }
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    NSLog(@"[SHOOTS_API_TEST]socket did connect to host and enableBackgroundingOnSocket.");
    [self.serverSocket performBlock:^{
        [self.serverSocket enableBackgroundingOnSocket];
    }];
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(nonnull GCDAsyncSocket *)newSocket
{
    NSLog(@"[SHOOTS_API_TEST]accept new socket (%@,%d)", newSocket.connectedHost, newSocket.connectedPort);
    if (![self.clientSockets containsObject:newSocket]){
        [self.clientSockets addObject:newSocket];
    }
    
    NSString *sockBufferKey = [NSString stringWithFormat:@"%@", @(newSocket.hash)];
    // create a new buffer for accepted new socket
    self.bufferDict[sockBufferKey] = [NSMutableData data];
    [newSocket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString *sockBufferKey = [NSString stringWithFormat:@"%@", @(sock.hash)];
    [self.bufferDict[sockBufferKey] appendData:data];
    unsigned long bufferLength = ((NSMutableData *)self.bufferDict[sockBufferKey]).length;
    while (bufferLength >= 4){
        unsigned long dataLength = 0;
        // 4 bytes header
        [self.bufferDict[sockBufferKey] getBytes:&dataLength length:4];
        if (bufferLength >= dataLength && dataLength >= 4){
            NSData *bodyData = [(NSMutableData *)self.bufferDict[sockBufferKey] subdataWithRange:NSMakeRange(4, dataLength - 4)].mutableCopy;
            self.bufferDict[sockBufferKey] = [(NSMutableData *)self.bufferDict[sockBufferKey] subdataWithRange:NSMakeRange(dataLength, bufferLength - dataLength)].mutableCopy;
            bufferLength -= dataLength;
//            NSString *requestString = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
//            NSLog(@"[API_TEST_REQUEST] %@", requestString);
            NSDictionary *payload = [NSJSONSerialization JSONObjectWithData:bodyData options:NSJSONReadingMutableContainers error:nil];
            if (!payload){
                NSLog(@"[SHOOTS_API_TEST]data is not valid json %@", bodyData);
                [self sendJson:[BDIRPCResponse responseErrorWithStatus:[BDIRPCStatus invalidRequestErrorWithMessage:@"data is not valid json."]].JSON toSock:sock];
                return;
            }
            
            BDIRPCRequest *request = [BDIRPCRequest instantiateWithPayload:payload];
            NSString *api = payload[@"method"];
            if (!api){
                NSLog(@"[SHOOTS_API_TEST]lack of request method.");
                [self sendJson:[BDIRPCResponse responseErrorWithStatus:[BDIRPCStatus invalidRequestErrorWithMessage:@"lack of request method."]].JSON toSock:sock];
                return;
            }
            
            [self handleJsonRpcRequest:request socket:sock];
            
        } else {
            break;
        }
    }
    [sock readDataWithTimeout:-1 tag:tag];
}

- (void)handleJsonRpcRequest:(BDIRPCRequest *) request socket:(GCDAsyncSocket *)sock {
    BDIRPCRoute *route = self.routeDict[request.method];
    if (!route){
        NSLog(@"[SHOOTS_API_TEST]api not found %@.", request.method);
        [self sendJson:[BDIRPCResponse responseErrorTo:request WithStatus:[BDIRPCStatus methodNotFoundErrorWithMessage:[NSString stringWithFormat:@"method %@ not found.", request.method]]].JSON toSock:sock];
        return;
    }
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block BDIRPCResponse *response = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        response = [route dispatchJsonRpcRequest:request];
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    [self sendJson:response.JSON toSock:sock];
}

- (void)sendJson:(NSDictionary *)json toSock:(GCDAsyncSocket *)sock
{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
    if (!jsonData){
        NSLog(@"[SHOOTS_API_TEST]fail to transfer response dict to json %@", json);
        return;
    }
//    NSString *responseString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//    NSLog(@"[API_TEST_RESPONSE] %@", responseString);
    unsigned long len = jsonData.length + 4;
    NSData *lenData = [NSData dataWithBytes:&len length:4];
    NSMutableData *sendData = [NSMutableData data];
    [sendData appendData:lenData];
    [sendData appendData:jsonData];
    [sock writeData:sendData.copy withTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(nonnull GCDAsyncSocket *)sock withError:(NSError *)err
{
    if ([self.clientSockets containsObject:sock]){
        [self.clientSockets removeObject:sock];
    }
    if (err){
        NSLog(@"[SHOOTS_API_TEST]socket disconnect error: %@", err.description);
    } else {
        NSLog(@"[SHOOTS_API_TEST]socket disconnect: (%@,%d)", sock.connectedHost, sock.connectedPort);
    }
}

- (void)registerRouteHandlers:(NSArray *)apiHandlerClasses
{
    for (Class<BDIAPIHandler> apiHandler in apiHandlerClasses){
        NSArray *routes = [apiHandler routes];
        for (BDIRPCRoute *route in routes){
            [self.routeDict setObject:route forKey:route.api];
        }
    }
}

+ (void)registerAPIHandlers:(NSArray *)apiHandlerClasses
{
    NSMutableArray *collection = [NSMutableArray array];
    for (Class handlerClass in apiHandlerClasses){
        if (class_conformsToProtocol(handlerClass, @protocol(BDIAPIHandler))){
            [collection addObject:handlerClass];
        }
    }
    [[BDISocketServer sharedServer] registerRouteHandlers:collection];
}

+ (NSArray<Class<BDIAPIHandler>> *)collectAPIHandlerClasses
{
    NSArray *handlerClasses = [[self class] classesThatConformsToProtocol:@protocol(BDIAPIHandler)];
    NSMutableArray *handlers = [NSMutableArray array];
    for (Class aClass in handlerClasses){
        if ([aClass respondsToSelector:@selector(shouldRegisterAutomatically)]) {
            if (![aClass shouldRegisterAutomatically]){
                continue;
            }
        }
        [handlers addObject:aClass];
    }
    return [handlers copy];
}

+ (NSArray<Class> *)classesThatConformsToProtocol:(Protocol *)protocol
{
    Class *classes = NULL;
    NSMutableArray *collection = [NSMutableArray array];
    int numClasses = objc_getClassList(NULL, 0);
    if (numClasses == 0) {
        return @[];
    }
    
    classes = (__unsafe_unretained Class*)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    for (int index = 0; index < numClasses; index++) {
        Class aClass = classes[index];
        if (class_conformsToProtocol(aClass, protocol)) {
            [collection addObject:aClass];
        }
    }
    free(classes);
    return [collection copy];
}

@end
