//
//  BDFlutterProtocal.h
//  Pods
//
//  Created by 刘丰恺 on 7/4/2020.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol FLTBMethodCall;

typedef void (^FLTBinaryReply)(NSData * _Nullable reply);
typedef void (^FLTBResponseCallback)(id _Nullable responseData);
typedef void (^FLTBMethodCallHandler)(id<FLTBMethodCall> _Nullable data, FLTBResponseCallback _Nullable );

@protocol FLTBMethodCall <NSObject>

- (NSString *_Nonnull)method;

- (id _Nullable)arguments;

@end


@protocol FLTBMethodChannel <NSObject>

- (void)invokeMethod:(NSString * _Nonnull)name arguments:(nullable id)arguments;

- (void)invokeMethod:(NSString * _Nonnull)name
           arguments:(nullable id)arguments
          completion:(nullable FLTBResponseCallback)callback;

- (void)setMethodCallHandler:(FLTBMethodCallHandler _Nullable )handler;

@end


@protocol FLTBinaryMessenger

- (void)sendOnChannel:(NSString *_Nonnull)channel message:(NSData * _Nullable)message;

- (void)sendOnChannel:(NSString *_Nonnull)channel
              message:(NSData *_Nullable)message
          binaryReply:(FLTBinaryReply _Nullable)callback;

- (void)setMessageHandlerOnChannel:(NSString*_Nullable)channel
              binaryMessageHandler:(FLTBMethodCallHandler _Nullable)handler;
@end


@protocol FLTBMethodChannelCreator <NSObject>

- (id<FLTBMethodChannel>_Nullable)createMethodChannel:(NSString *_Nonnull)name
                                         forMessenger:(NSObject *_Nonnull)messenger;

@end
