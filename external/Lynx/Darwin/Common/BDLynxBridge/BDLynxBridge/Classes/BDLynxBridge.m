//
//  BDLynxBridge.m
//
//  Created by li keliang on 2020/2/9.
//  Copyright © 2020 Lynx. All rights reserved.
//

#import "BDLynxBridge+Internal.h"
#import "BDLynxBridgeListenerManager+Internal.h"
#import "BDLynxBridgeListenerManager.h"
#import "LynxServiceInfo.h"

NSString *const BDLynxBridgeDefaultNamescope = @"host";

static NSMutableArray<BDLynxBridgeMethod *> *kLynxGlobalBridgeMethods(void) {
  static NSMutableArray<BDLynxBridgeMethod *> *_globalMethods = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _globalMethods = [NSMutableArray new];
  });
  return _globalMethods;
};

@interface BDLynxBridge ()

@property(nonatomic, readwrite, strong) NSMutableArray<BDLynxBridgeMethod *> *methods;
@property(nonatomic, strong) NSMutableArray<id<BDLynxBridgeExecutor>> *executors;
@property(nonatomic, copy, readwrite, nullable) NSString *namescope;

@end

@implementation BDLynxBridge

- (instancetype)init {
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:@"Use -[BDLynxBridge initWithLynxView:], not init"
                               userInfo:nil];
  return [self initWithLynxView:[LynxView new]];
}

- (instancetype)initWithLynxView:(LynxView *)lynxView {
  self = [super init];
  if (self) {
    _lynxView = lynxView;
    _methods = [[NSMutableArray alloc] initWithArray:kLynxGlobalBridgeMethods()];
  }
  return self;
}

- (instancetype)initWithoutLynxView {
  self = [super init];
  if (self) {
    _methods = [[NSMutableArray alloc] initWithArray:kLynxGlobalBridgeMethods()];
  }
  return self;
}

- (void)attachLynxView:(nonnull LynxView *)lynxView {
  _lynxView = lynxView;
}

- (NSArray<id<BDLynxBridgeExecutor>> *)executors {
  if (!_executors) {
    _executors = NSMutableArray.array;
  }
  return _executors;
}

- (void)setNamescope:(NSString *)namescope {
  _namescope = namescope;
}

#pragma mark - Register Handler

+ (void)registerGlobalHandler:(BDLynxBridgeHandler)handler forMethod:(NSString *)method {
  [self registerGlobalHandler:handler forMethod:method namescope:nil];
}

+ (void)registerGlobalHandler:(BDLynxBridgeHandler)handler
                    forMethod:(NSString *)methodName
                    namescope:(NSString *)namescope {
  [self _registerHandler:handler
          sessionHandler:nil
               forMethod:methodName
               namescope:namescope
             intoMethods:kLynxGlobalBridgeMethods()];
}

+ (void)registerGlobalSessionHandler:(BDLynxBridgeSessionHandler)handler
                           forMethod:(NSString *)method
                           namescope:(nullable NSString *)namescope {
  [self _registerHandler:nil
          sessionHandler:handler
               forMethod:method
               namescope:namescope
             intoMethods:kLynxGlobalBridgeMethods()];
}

- (void)registerHandler:(BDLynxBridgeHandler)handler forMethod:(NSString *)method {
  [self registerHandler:handler forMethod:method namescope:nil];
}

- (void)registerHandler:(BDLynxBridgeHandler)handler
              forMethod:(NSString *)methodName
              namescope:(NSString *)namescope {
  [self.class _registerHandler:handler
                sessionHandler:nil
                     forMethod:methodName
                     namescope:namescope
                   intoMethods:self.methods];
}

- (void)registerSessionHandler:(BDLynxBridgeSessionHandler)handler
                     forMethod:(NSString *)method
                     namescope:(nullable NSString *)namescope {
  [self.class _registerHandler:nil
                sessionHandler:handler
                     forMethod:method
                     namescope:namescope
                   intoMethods:self.methods];
}

- (void)addExecutor:(id<BDLynxBridgeExecutor>)executor {
  @synchronized(self.executors) {
    [self.executors addObject:executor];
    [self.executors sortUsingComparator:^NSComparisonResult(id<BDLynxBridgeExecutor> obj1,
                                                            id<BDLynxBridgeExecutor> obj2) {
      NSUInteger priority1 = 0;
      NSUInteger priority2 = 0;

      if ([obj1 respondsToSelector:@selector(priority)]) {
        priority1 = obj1.priority;
      }

      if ([obj2 respondsToSelector:@selector(priority)]) {
        priority2 = obj2.priority;
      }
      return priority1 > priority2 ? NSOrderedAscending : NSOrderedDescending;
    }];
  }
}

#pragma mark - Call Event

+ (void)callEvent:(NSString *)event
      containerID:(nullable NSString *)containerID
           params:(nullable NSDictionary *)params {
  [self callEvent:event containerID:containerID params:params code:BDLynxBridgeCodeSucceed];
}

+ (void)callEvent:(NSString *)event
      containerID:(nullable NSString *)containerID
           params:(nullable NSDictionary *)params
             code:(BDLynxBridgeStatusCode)code {
  if (!containerID) {
    [BDLynxBridgesPool enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
      [obj callEvent:event params:params code:code];
    }];
  } else {
    BDLynxBridge *bridge = [BDLynxBridgesPool bridgeForContainerID:containerID];
    [bridge callEvent:event params:params code:code];
  }
}

- (void)callEvent:(NSString *)event params:(nullable NSDictionary *)params {
  [self callEvent:event params:params code:BDLynxBridgeCodeSucceed];
}

- (void)callEvent:(NSString *)event
           params:(nullable NSDictionary *)params
             code:(BDLynxBridgeStatusCode)code {
  if (!_lynxView) {
    [NSException
        exceptionWithName:@"BDLynxBridgeException"
                   reason:[NSString
                              stringWithFormat:@"BDLynxBridge %@ reference lynxView is null", self]
                 userInfo:nil];
    return;
  }

  BDLynxBridgeSendMessage *message =
      [BDLynxBridgeSendMessage messageWithContainerID:self.lynxView.containerID];
  message.data = params;
  message.code = code;

  [BDLynxBridgeListenerManager notifyWillCallEvent:self message:message];
  [self.lynxView sendGlobalEvent:event withParams:@[ message.encodedMessage ?: @{} ]];
  [BDLynxBridgeListenerManager notifyDidCallEvent:self message:message];
}

#pragma mark - Private

- (BOOL)_handleWithLynx:(LynxView *)lynxView
                handler:(BDLynxBridgeHandler)handler
         sessionHandler:(BDLynxBridgeSessionHandler)sessionHandler
                message:(BDLynxBridgeReceivedMessage *)message
               callback:(LynxCallbackBlock)callback {
  if (!handler && !sessionHandler) {
    return NO;
  }

  void (^responseBlock)(BDLynxBridgeStatusCode, NSDictionary *_Nullable) =
      ^(BDLynxBridgeStatusCode code, id _Nullable data) {
        [BDLynxBridgeListenerManager notifyDidHandleMethod:self message:message];

        BDLynxBridgeSendMessage *callbackMessage =
            [BDLynxBridgeSendMessage messageWithContainerID:lynxView.containerID];
        callbackMessage.invokeMessage = message;
        callbackMessage.code = code;
        callbackMessage.data = data;
        if (callback) {
          [BDLynxBridgeListenerManager notifyWillCallback:self message:callbackMessage];
          callback(callbackMessage.encodedMessage);
          [BDLynxBridgeListenerManager notifyDidCallback:self message:callbackMessage];
        }
      };

  if (message.useUIThread) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (sessionHandler) {
        LynxServiceInfo *sessionInfo = [[LynxServiceInfo alloc] init];
        sessionInfo.context = [lynxView getLynxContext];
        sessionInfo.extra = [message.rawData objectForKey:@"extra"];
        sessionHandler(lynxView, message.methodName, message.data, sessionInfo, responseBlock);
      } else {
        handler(lynxView, message.methodName, message.data, responseBlock);
      }
    });
  } else {
    if (sessionHandler) {
      LynxServiceInfo *sessionInfo = [[LynxServiceInfo alloc] init];
      sessionInfo.extra = [message.rawData objectForKey:@"extra"];
      sessionInfo.context = [lynxView getLynxContext];
      sessionHandler(lynxView, message.methodName, message.data, sessionInfo, responseBlock);
    } else {
      handler(lynxView, message.methodName, message.data, responseBlock);
    }
  }

  return YES;
}

- (void)_executeMethodWithMessage:(BDLynxBridgeReceivedMessage *)message
                         callback:(LynxCallbackBlock)callback {
  BDLynxBridgeSessionHandler sessionHandler = [self _getSessionHandlerWithMessage:message];
  BDLynxBridgeHandler handler;
  if (!sessionHandler) {
    handler = [self _getHandlerWithMessage:message];
  }
  [BDLynxBridgeListenerManager notifyWillHandleMethod:self message:message];
  if (message.isDefaultOfUseUIThread &&
      [self.directPerformMethods containsObject:message.methodName]) {
    [message useUIThreadDisable];
  }
  __block BOOL processed = [self _handleWithLynx:self.lynxView
                                         handler:handler
                                  sessionHandler:sessionHandler
                                         message:message
                                        callback:callback];
  if (!processed) {
    __weak typeof(self) weakSelf = self;
    [self.executors enumerateObjectsUsingBlock:^(id<BDLynxBridgeExecutor> _Nonnull obj,
                                                 NSUInteger idx, BOOL *_Nonnull stop) {
      processed = [obj
          executeMethodWithMessage:message
                          onBridge:self
                          callback:^(BDLynxBridgeStatusCode code, NSDictionary *_Nullable data) {
                            __strong typeof(self) strongSelf = weakSelf;
                            [BDLynxBridgeListenerManager notifyDidHandleMethod:strongSelf
                                                                       message:message];

                            BDLynxBridgeSendMessage *callbackMessage = [BDLynxBridgeSendMessage
                                messageWithContainerID:message.containerID];
                            callbackMessage.invokeMessage = message;
                            callbackMessage.data = data;
                            callbackMessage.code = code;
                            [BDLynxBridgeListenerManager notifyWillCallback:strongSelf
                                                                    message:callbackMessage];
                            if (callback) {
                              callback(callbackMessage.encodedMessage);
                            }
                            [BDLynxBridgeListenerManager notifyDidCallback:strongSelf
                                                                   message:callbackMessage];
                          }];
      *stop = processed;
    }];
  }

  if (!processed) {
    BDLynxBridgeSendMessage *noHandlerErrorMsg =
        [BDLynxBridgeReceivedMessage noHandleErrorMessage:message.containerID];
    noHandlerErrorMsg.invokeMessage = message;
    [BDLynxBridgeListenerManager notifyWillCallback:self message:noHandlerErrorMsg];
    if (callback) {
      callback(noHandlerErrorMsg.encodedMessage);
    }
    [BDLynxBridgeListenerManager notifyDidCallback:self message:noHandlerErrorMsg];
  }
}

- (BDLynxBridgeHandler)_getHandlerWithMessage:(BDLynxBridgeReceivedMessage *)message {
  // message namescope -> lynxview namescope(or BDLynxBridge's namescope when lynxview is destroyed)
  // -> host namescope
  BDLynxBridgeHandler handler = [self _getHandlerWithMessage:message namescope:message.namescope];

  if (!handler && message.namescope.length == 0) {
    handler = [self _getHandlerWithMessage:message namescope:self.lynxView.namescope];
  }

  // If lynxview has been destroyed, use BDLynxBridge's namescope to find handler.
  if (!handler && self.lynxView == nil) {
    handler = [self _getHandlerWithMessage:message namescope:self.namescope];
  }

  if (!handler) {
    handler = [self _getHandlerWithMessage:message namescope:BDLynxBridgeDefaultNamescope];
    ;
  }
  return handler;
}

- (BDLynxBridgeSessionHandler)_getSessionHandlerWithMessage:(BDLynxBridgeReceivedMessage *)message {
  // message namescope -> lynxview namescope(or BDLynxBridge's namescope when lynxview is destroyed)
  // -> host namescope
  BDLynxBridgeSessionHandler handler = [self _getSessionHandlerWithMessage:message
                                                                 namescope:message.namescope];

  if (!handler && message.namescope.length == 0) {
    handler = [self _getSessionHandlerWithMessage:message namescope:self.lynxView.namescope];
  }

  // If lynxview has been destroyed, use BDLynxBridge's namescope to find handler.
  if (!handler && self.lynxView == nil) {
    handler = [self _getSessionHandlerWithMessage:message namescope:self.namescope];
  }

  if (!handler) {
    handler = [self _getSessionHandlerWithMessage:message namescope:BDLynxBridgeDefaultNamescope];
    ;
  }
  return handler;
}

- (BDLynxBridgeSessionHandler)_getSessionHandlerWithMessage:(BDLynxBridgeReceivedMessage *)message
                                                  namescope:(NSString *)namescope {
  if (namescope.length == 0) {
    return nil;
  }
  @synchronized(self.methods) {
    __block BDLynxBridgeSessionHandler handler;
    [self.methods enumerateObjectsUsingBlock:^(BDLynxBridgeMethod *_Nonnull obj, NSUInteger idx,
                                               BOOL *_Nonnull stop) {
      if ([obj.namescope isEqualToString:namescope] &&
          [obj.methodName isEqualToString:message.methodName]) {
        handler = obj.sessionHandler;
        *stop = YES;
      }
    }];
    return handler;
  }
}

- (BDLynxBridgeHandler)_getHandlerWithMessage:(BDLynxBridgeReceivedMessage *)message
                                    namescope:(NSString *)namescope {
  if (namescope.length == 0) {
    return nil;
  }

  @synchronized(self.methods) {
    __block BDLynxBridgeHandler handler;
    [self.methods enumerateObjectsUsingBlock:^(BDLynxBridgeMethod *_Nonnull obj, NSUInteger idx,
                                               BOOL *_Nonnull stop) {
      if ([obj.namescope isEqualToString:namescope] &&
          [obj.methodName isEqualToString:message.methodName]) {
        handler = obj.handler;
        *stop = YES;
      }
    }];
    return handler;
  }
}

+ (void)_registerHandler:(BDLynxBridgeHandler)handler
          sessionHandler:(BDLynxBridgeSessionHandler)sessionHandler
               forMethod:(NSString *)methodName
               namescope:(NSString *)namescope
             intoMethods:(NSMutableArray *)methods {
  @synchronized(methods) {
    namescope = namescope ?: BDLynxBridgeDefaultNamescope;

    [methods enumerateObjectsUsingBlock:^(BDLynxBridgeMethod *_Nonnull obj, NSUInteger idx,
                                          BOOL *_Nonnull stop) {
      if ([obj.methodName isEqualToString:methodName] &&
          [namescope isEqualToString:obj.namescope]) {
        [methods removeObject:obj];
        *stop = YES;
      }
    }];

    BDLynxBridgeMethod *method = [[BDLynxBridgeMethod alloc] initWithMethodName:methodName
                                                                        handler:handler
                                                                 sessionHandler:sessionHandler
                                                                      namescope:namescope];
    [methods insertObject:method atIndex:0];
  }
}

@end
