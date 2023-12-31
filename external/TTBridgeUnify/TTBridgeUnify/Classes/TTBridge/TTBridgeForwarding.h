//
//  TTBridgeForwarding.h
//  TTBridgeUnify
//
//  Modified from TTRexxar of muhuai.
//  Created by lizhuopeng on 2018/10/30.
//


#import <Foundation/Foundation.h>
#import "TTBridgeCommand.h"
#import "TTBridgeEngine.h"
#import "TTBridgeDefines.h"

@interface TTBridgeForwarding : NSObject

+ (instancetype)sharedInstance;


/**
 Forward  the command to the plugin.

 @param command bridge command
 @param engine Hybrid container. It can be the webview, RNView or weex, which should implement  the TTBridgeEngine protocol.
 @param completion callback block
 */
- (void)forwardWithCommand:(TTBridgeCommand *)command weakEngine:(id<TTBridgeEngine>)engine completion:(TTBridgeCallback)completion;

/**
 Register a plugin name for a bridge name.
 
 @param plugin plugin name
 @param bridgeName bridge name
 */
- (void)registerPlugin:(NSString *)plugin forBridge:(TTBridgeName)bridgeName;
- (void)unregisterPluginForBridge:(TTBridgeName)bridgeName;


/**
 original name -> alias

 @param orig original name
 @return alias
 */
- (NSString *)aliasForOrig:(NSString *)orig;
@end

