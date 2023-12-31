//
//  BDNativeWebBridgeManager.h
//  AFgzipRequestSerializer
//
//  Created by liuyunxuan on 2019/7/8.
//

#import <Foundation/Foundation.h>

typedef enum : NSInteger {
    BDNativeBridgeMsgSuccess = 1,
    BDNativeBridgeMsgFailed = 0,
    BDNativeBridgeMsgParamError = -3,
    BDNativeBridgeMsgNoHandler = -2,
    BDNativeBridgeMsgNoPermission = -1
} BDNativeBridgeMsg;

typedef void(^BDNativeBridgeCallback)(BDNativeBridgeMsg msg, NSDictionary *params, void(^resultBlock)(NSString *result));

typedef void(^BDNativeBridgeHandler)(NSDictionary *params, BDNativeBridgeCallback callback);

@protocol BDNativeWebBridgeManagerDelegate <NSObject>

- (void)bdNativeBridge_nativeMangerEvaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)( id, NSError *error))completionHandler;

@end

@interface BDNativeWebBridgeManager : NSObject

- (void)handleMixRenderMessage:(NSString *)message;

- (void)registerHandler:(BDNativeBridgeHandler)handler bridgeName:(NSString *)bridgeName;

@property (nonatomic, weak) id<BDNativeWebBridgeManagerDelegate>delegate;

@end
