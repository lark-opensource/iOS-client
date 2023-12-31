//
//  TTBridgeAuthorization.h
//  TTBridgeUnify
//
//  Modified from TTRexxar of muhuai.
//  Created by lizhuopeng on 2018/10/30.
//

#import <Foundation/Foundation.h>
#import "TTBridgeDefines.h"
#import "TTBridgeCommand.h"
#import "TTBridgeEngine.h"

@protocol TTBridgeAuthorization <NSObject>


/**
 Verify the permission of an engine to call a bridge.

 @param engine engine of the current webView
 @param command Command
 @param domain host of the current webView
 @return authorization result
 */
- (BOOL)engine:(id<TTBridgeEngine>)engine isAuthorizedBridge:(TTBridgeCommand *)command domain:(NSString *)domain;

- (void)engine:(id<TTBridgeEngine>)engine isAuthorizedBridge:(TTBridgeCommand *)command domain:(NSString *)domain completion:(void (^)(BOOL success))completion;

- (BOOL)engine:(id<TTBridgeEngine>)engine isAuthorizedMeta:(NSString *)meta domain:(NSString *)domain;

- (BOOL)engine:(id<TTBridgeEngine>)engine isAuthorizedBridge:(TTBridgeCommand *)command URL:(NSURL *)URL;

@optional
- (BOOL)engine:(id<TTBridgeEngine>)engine isAuthorizedEvent:(NSString *)eventName domain:(NSString *)domain __deprecated_msg("Event no longer requires authorization. This method is no longer needed.");

@end
