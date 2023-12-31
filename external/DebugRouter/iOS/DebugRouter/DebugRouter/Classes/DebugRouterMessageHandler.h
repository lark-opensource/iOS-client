// Copyright 2023 The Lynx Authors. All rights reserved.

#import "DebugRouterMessageHandleResult.h"

NS_ASSUME_NONNULL_BEGIN
/**
 * MessageHandler is used to process message received by DebugRouter.
 *
 * we can use:
 *
 * DebugRouter#addMessageHandler
 *
 * to add MessageHandler for processing specific message.
 */

@protocol DebugRouterMessageHandler <NSObject>

/**
 * DebugRouter dispatch message according to MessageHandler's name,

 * when a MessageHandler's name match the received message, the
 * MessageHandler will handle this message(the handle method of the
 * MessageHandler will be called)

 * when handler need return extra result asynchronously,
 * you can use:
 * DebugRouterEventSender#sender
 *
 * params: handler's params: resolved from the message
 * return: return handler's result
 */
- (DebugRouterMessageHandleResult *)handleMessageWithParams:
    (NSMutableDictionary<NSString *, NSString *> *)params;

/**
 * MessageHandler's name
 *
 * unique identifier for MessageHandler.
 *
 * It indicates which message this handler can handle.
 */
- (NSString *)getName;

@end

NS_ASSUME_NONNULL_END
