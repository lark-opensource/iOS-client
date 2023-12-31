//
//  BDEventForwarder.h
//  BDFlutterPluginManager
//
//  Created by 林一一 on 2019/11/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDFLMessageChannelProtocol <NSObject>
- (void)sendMessage:(id _Nullable)message;
- (void)sendMessage:(id _Nullable)message reply:(id _Nullable)callback;
@end

@protocol BDFLMethodChannelProtocol <NSObject>
- (void)invokeMethod:(NSString*)method arguments:(id _Nullable)arguments;
- (void)invokeMethod:(NSString*)method arguments:(id _Nullable)arguments result:(id _Nullable)callback;
@end

typedef void (^BDFLEventSink)(id _Nullable event);

@interface BDFLEventForwarder : NSObject

- (void)setMessageChannel:(id)messageChannel WithName:(NSString *)name;
- (void)setMethodChannel:(id)methodChannel WithName:(NSString *)name;
- (void)setEventSink:(nullable BDFLEventSink)eventSink WithName:(NSString *)name;
- (id<BDFLMessageChannelProtocol>)getMessageChannelWithName:(NSString *)name;
- (id<BDFLMethodChannelProtocol>)getMethodChannelWithName:(NSString *)name;
- (BDFLEventSink)getEventSinkWithName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
