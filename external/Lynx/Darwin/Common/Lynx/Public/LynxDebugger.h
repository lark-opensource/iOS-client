// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_LYNXDEBUGGER_H_
#define DARWIN_COMMON_LYNX_LYNXDEBUGGER_H_

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^LynxOpenCardCallback)(NSString *);

@protocol LynxDebuggerProtocol <NSObject>

@required

+ (instancetype)singleton;

- (BOOL)enable:(NSURL *)url withOptions:(NSDictionary *)options;

- (void)setOpenCardCallback:(LynxOpenCardCallback)callback;

@end

@interface LynxDebugger : NSObject

+ (BOOL)enable:(NSURL *)schema withOptions:(NSDictionary *)options;

+ (void)setOpenCardCallback:(LynxOpenCardCallback)callback
    __attribute__((deprecated("Use addOpenCardCallback instead after lynx 2.6")));
;

+ (void)addOpenCardCallback:(LynxOpenCardCallback)callback;

+ (void)onTracingComplete:(NSString *)traceFile;

+ (void)recordResource:(NSData *)data withKey:(NSString *)key;

+ (BOOL)hasSetOpenCardCallback;

// only be used by macOS
+ (BOOL)openDebugSettingPanel;

@end

NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_LYNXDEBUGGER_H_
