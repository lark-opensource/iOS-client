// Copyright 2023 The Lynx Authors. All rights reserved.

#import "DebugRouterMessageHandler.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger { WebSocket, USB } ConnectionType;

@protocol DebugRouterStateListener <NSObject>

@required
- (void)onOpen:(ConnectionType)type;
- (void)onClose;
- (void)onMessage:(id)message;
- (void)onError;

@end

typedef enum : NSUInteger {
  DISCONNECTED,
  CONNECTING,
  CONNECTED
} ConnectionState;

@class DebugRouterSlot;
@protocol DebugRouterGlobalHandler;

@interface DebugRouter : NSObject

@property(nonatomic, readwrite) NSMutableDictionary *slots;
@property(nonatomic, readwrite) NSMapTable *views;
@property(nonatomic, readwrite) NSString *room_id;
@property(nonatomic, readwrite) NSMutableArray *global_handlers;
@property(nonatomic, readwrite) NSMutableDictionary *messageHandlers;
@property(nonatomic, readwrite) NSString *server_url;
@property(nonatomic, readwrite) ConnectionState connection_state;
@property(nonatomic, readwrite) NSMutableDictionary *app_info;
@property(nonatomic, readonly) BOOL cronet_initialized;
@property(atomic, readwrite, nullable) void *cronet_engine;
@property(nonatomic, readonly) int usb_port;

+ (DebugRouter *)instance;

- (void)connect:(NSString *)url ToRoom:(NSString *)room;
- (void)disconnect;
- (void)reconnect;

- (void)send:(NSString *)message;
- (void)sendData:(NSString *)data
        WithType:(NSString *)type
      ForSession:(int)session;
- (void)sendData:(NSString *)data
        WithType:(NSString *)type
      ForSession:(int)session
        WithMark:(int)mark;
- (void)sendObject:(NSDictionary *)data
          WithType:(NSString *)type
        ForSession:(int)session;
- (void)sendObject:(NSDictionary *)data
          WithType:(NSString *)type
        ForSession:(int)session
          WithMark:(int)mark;
- (void)sendAsync:(NSString *)message;
- (void)sendDataAsync:(NSString *)data
             WithType:(NSString *)type
           ForSession:(int)session;
- (void)sendDataAsync:(NSString *)data
             WithType:(NSString *)type
           ForSession:(int)session
             WithMark:(int)mark;
- (void)sendObjectAsync:(NSDictionary *)data
               WithType:(NSString *)type
             ForSession:(int)session;
- (void)sendObjectAsync:(NSDictionary *)data
               WithType:(NSString *)type
             ForSession:(int)session
               WithMark:(int)mark;

- (int)plug:(DebugRouterSlot *)slot;
- (void)pull:(int)sessionId;

#if defined(OS_IOS)
- (int)getSessionIdByView:(UIView *)view;
#elif defined(OS_OSX)
- (int)getSessionIdByView:(NSView *)view;
#endif

- (void)addGlobalHandler:(id<DebugRouterGlobalHandler>)handler;
- (void)addMessageHandler:(id<DebugRouterMessageHandler>)handler;

- (BOOL)isValidSchema:(NSString *)schema;
- (BOOL)handleSchema:(NSString *)schema;
- (void)addStateListener:(id<DebugRouterStateListener>)listener;

- (void)setConfig:(BOOL)value forKey:(NSString *)key;
- (BOOL)getConfig:(NSString *)configKey withDefaultValue:(BOOL)defaultValue;

@end

NS_ASSUME_NONNULL_END
