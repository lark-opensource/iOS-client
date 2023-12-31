// Copyright 2023 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern const NSString *NOT_IMPLETEMTED_MESSAGE;
extern const int CODE_NOT_IMPLEMENTED;
extern const int CODE_HANDLE_FAILED;
extern const int CODE_HANDLE_SUCCESSFULLY;

@interface DebugRouterMessageHandleResult : NSObject {
  int code;
  const NSString *message;
}

@property(getter=data) NSMutableDictionary<NSString *, id> *data;

// Error
- (id)initWithCode:(int)code message:(const NSString *)message;

// Success with data
- (id)init:(nullable NSMutableDictionary<NSString *, id> *)data;

// Default result:(Success without any data)
- (id)init;

- (NSString *)toJsonString;

- (NSMutableDictionary<NSString *, id> *)toDict;

- (NSMutableDictionary<NSString *, NSString *> *)toStringDict;

@end

NS_ASSUME_NONNULL_END
