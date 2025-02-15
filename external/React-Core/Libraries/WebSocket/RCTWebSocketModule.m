/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <React/RCTWebSocketModule.h>

#import <objc/runtime.h>

#import <React/RCTConvert.h>
#import <React/RCTUtils.h>

#import <React/RCTSRWebSocket.h>

@implementation RCTSRWebSocket (React)

- (NSNumber *)reactTag
{
  return objc_getAssociatedObject(self, _cmd);
}

- (void)setReactTag:(NSNumber *)reactTag
{
  objc_setAssociatedObject(self, @selector(reactTag), reactTag, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end

@interface RCTWebSocketModule () <RCTSRWebSocketDelegate>

@end

@implementation RCTWebSocketModule
{
  NSMutableDictionary<NSNumber *, RCTSRWebSocket *> *_sockets;
  NSMutableDictionary<NSNumber *, id<RCTWebSocketContentHandler>> *_contentHandlers;
}

RCT_EXPORT_MODULE()

// Used by RCTBlobModule
@synthesize methodQueue = _methodQueue;

- (NSArray *)supportedEvents
{
  return @[@"websocketMessage",
           @"websocketOpen",
           @"websocketFailed",
           @"websocketClosed"];
}

- (void)invalidate
{
  _contentHandlers = nil;
  for (RCTSRWebSocket *socket in _sockets.allValues) {
    socket.delegate = nil;
    [socket close];
  }
}

RCT_EXPORT_METHOD(connect:(NSURL *)URL protocols:(NSArray *)protocols options:(NSDictionary *)options socketID:(nonnull NSNumber *)socketID)
{
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];

  // We load cookies from sharedHTTPCookieStorage (shared with XHR and
  // fetch). To get secure cookies for wss URLs, replace wss with https
  // in the URL.
  NSURLComponents *components = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:true];
  if ([components.scheme.lowercaseString isEqualToString:@"wss"]) {
    components.scheme = @"https";
  }

  // Load and set the cookie header.
  NSArray<NSHTTPCookie *> *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:components.URL];
  request.allHTTPHeaderFields = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];

  // Load supplied headers
  [options[@"headers"] enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
    [request addValue:[RCTConvert NSString:value] forHTTPHeaderField:key];
  }];

  RCTSRWebSocket *webSocket = [[RCTSRWebSocket alloc] initWithURLRequest:request protocols:protocols];
  [webSocket setDelegateDispatchQueue:_methodQueue];
  webSocket.delegate = self;
  webSocket.reactTag = socketID;
  if (!_sockets) {
    _sockets = [NSMutableDictionary new];
  }
  _sockets[socketID] = webSocket;
  [webSocket open];
}

RCT_EXPORT_METHOD(send:(NSString *)message forSocketID:(nonnull NSNumber *)socketID)
{
  [_sockets[socketID] send:message];
}

RCT_EXPORT_METHOD(sendBinary:(NSString *)base64String forSocketID:(nonnull NSNumber *)socketID)
{
  [self sendData:[[NSData alloc] initWithBase64EncodedString:base64String options:0] forSocketID:socketID];
}

- (void)sendData:(NSData *)data forSocketID:(nonnull NSNumber *)socketID
{
  [_sockets[socketID] send:data];
}

RCT_EXPORT_METHOD(ping:(nonnull NSNumber *)socketID)
{
  [_sockets[socketID] sendPing:NULL];
}

RCT_EXPORT_METHOD(close:(NSInteger)code reason:(NSString *)reason socketID:(nonnull NSNumber *)socketID)
{
  [_sockets[socketID] closeWithCode:code reason:reason];
  [_sockets removeObjectForKey:socketID];
}

- (void)setContentHandler:(id<RCTWebSocketContentHandler>)handler forSocketID:(NSString *)socketID
{
  if (!_contentHandlers) {
    _contentHandlers = [NSMutableDictionary new];
  }
  _contentHandlers[socketID] = handler;
}

#pragma mark - RCTSRWebSocketDelegate methods

- (void)webSocket:(RCTSRWebSocket *)webSocket didReceiveMessage:(id)message
{
  NSString *type;

  NSNumber *socketID = [webSocket reactTag];
  id contentHandler = _contentHandlers[socketID];
  if (contentHandler) {
    message = [contentHandler processWebsocketMessage:message forSocketID:socketID withType:&type];
  } else {
    if ([message isKindOfClass:[NSData class]]) {
      type = @"binary";
      message = [message base64EncodedStringWithOptions:0];
    } else {
      type = @"text";
    }
  }

  [self sendEventWithName:@"websocketMessage" body:@{
    @"data": message,
    @"type": type,
    @"id": webSocket.reactTag
  }];
}

- (void)webSocketDidOpen:(RCTSRWebSocket *)webSocket
{
  [self sendEventWithName:@"websocketOpen" body:@{
    @"id": webSocket.reactTag,
    @"protocol": webSocket.protocol ? webSocket.protocol : @""
  }];
}

// 这里修改了源码
// 为了解决构造字典 value 可能为 nil 的情况
// https://bytedance.feishu.cn/space/doc/doccnSEVVSNeNflTUVDbDgI2svd#
- (void)webSocket:(RCTSRWebSocket *)webSocket didFailWithError:(NSError *)error
{
  NSNumber *socketID = [webSocket reactTag];
  _contentHandlers[socketID] = nil;
  _sockets[socketID] = nil;

  NSString *message = error.localizedDescription;

  if (message == nil) {
    message = @"Doc UnKnown Error Localized Description";
  }

  [self sendEventWithName:@"websocketFailed" body:@{
    @"message": message,
    @"id": socketID
  }];
}

- (void)webSocket:(RCTSRWebSocket *)webSocket
 didCloseWithCode:(NSInteger)code
           reason:(NSString *)reason
         wasClean:(BOOL)wasClean
{
  NSNumber *socketID = [webSocket reactTag];
  _contentHandlers[socketID] = nil;
  _sockets[socketID] = nil;
  [self sendEventWithName:@"websocketClosed" body:@{
    @"code": @(code),
    @"reason": RCTNullIfNil(reason),
    @"clean": @(wasClean),
    @"id": socketID
  }];
}

@end

@implementation RCTBridge (RCTWebSocketModule)

- (RCTWebSocketModule *)webSocketModule
{
  return [self moduleForClass:[RCTWebSocketModule class]];
}

@end
