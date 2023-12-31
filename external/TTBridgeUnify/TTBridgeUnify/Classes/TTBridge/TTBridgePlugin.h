//
//  TTBridgePlugin.h
//  TTBridgeUnify
//
//  Modified from TTRexxar of muhuai.
//  Created by lizhuopeng on 2018/10/30.
//

#import <Foundation/Foundation.h>
#import "TTBridgeDefines.h"
#import "TTBridgeEngine.h"

/**
This Macro can be used to ensure the existence of the native method when register a JSB.

Example：
TTBridgeSEL(TTAppBridge, appInfo) is equal to @selector(appInfoWithParam:callback:engine:controller:)

When the method does not exist, the compiler will prompt an error!
 */
#define TTBridgeSEL(CLASS, METHOD) \
((void)(NO && ((void)[((CLASS *)(nil)) METHOD##WithParam:nil callback:nil engine:nil controller:nil], NO)), @selector(METHOD##WithParam:callback:engine:controller:))


@interface TTBridgePlugin : NSObject

/**
 The engine which the plugin is executed by.
 */
@property (nonatomic, weak) id<TTBridgeEngine> engine;


/**
 When JSB's type is TTBridgeInstanceTypeGlobal, this method should be implemented. This method is not commonly recommended.

 @return singleton plugin
 */
+ (instancetype)sharedPlugin;

+ (TTBridgeInstanceType)instanceType;


#pragma mark - deprecated, The API that is no longer recommended for local bridge.
+ (void)registerHandlerBlock:(TTBridgePluginHandler)handler forEngine:(id<TTBridgeEngine>)engine selector:(SEL)selector __deprecated_msg("Use -[TTBridgeRegister registerBridge:]");

- (BOOL)hasExternalHandleForMethod:(NSString *)method params:(NSDictionary *)params callback:(TTBridgeCallback)callback __deprecated_msg("The API that is no longer recommended for local bridge.");

@end
