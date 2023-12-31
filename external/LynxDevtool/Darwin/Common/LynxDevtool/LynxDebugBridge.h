// Copyright 2020 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LynxDebugBridge : NSObject

@property(readwrite, nonatomic) NSDictionary *hostOptions;
@property(readwrite, nonatomic) NSString *monitorWindowUrl;
@property(readwrite, nonatomic) NSString *debugState;

// this will be used in .m(objective-c). so this statement can't convert to c++ using expression.
typedef void (^LynxDebugBridgeOpenCardCallback)(NSString *);

+ (instancetype)singleton;

- (BOOL)isEnabled;
- (BOOL)hasSetOpenCardCallback;
- (BOOL)enable:(NSURL *)url withOptions:(NSDictionary *)options;
- (void)sendDebugStateEvent;
- (void)setOpenCardCallback:(LynxDebugBridgeOpenCardCallback)callback;
- (void)openCard:(NSString *)url;
- (void)onMessage:(NSString *)message withType:(NSString *)type;
- (void)onTracingComplete:(NSString *)traceFilePath;
- (void)recordResource:(NSData *)data withKey:(NSString *)key;
- (void)setAppInfo:(NSDictionary *)hostOptions;

@end

NS_ASSUME_NONNULL_END
