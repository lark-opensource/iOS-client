//
//  ADFGBridgeForwarding.h
//  ADFGBridgeUnify
//
//  Modified from TTRexxar of muhuai.
//  Created by iCuiCui on 2020/04/30.
//


#import <Foundation/Foundation.h>
#import "ADFGBridgeCommand.h"
#import "ADFGBridgeEngine.h"
#import "ADFGBridgeDefines.h"

@interface ADFGBridgeForwarding : NSObject

+ (instancetype)sharedInstance;


/**
 转发到对应的插件

 @param command bridge命令
 @param engine Hybrid容器, 可是webview, RNView, weex. 实现此协议即可
 @param completion 完成回调
 */
- (void)forwardWithCommand:(ADFGBridgeCommand *)command weakEngine:(id<ADFGBridgeEngine>)engine completion:(ADFGBridgeCallback)completion;

/**
 注册bridge别名
 
 @param plugin 插件名
 @param bridgeName bridge 名
 */
- (void)registerPlugin:(NSString *)plugin forBridge:(ADFGBridgeName)bridgeName;
- (void)unregisterPluginForBridge:(ADFGBridgeName)bridgeName;


/**
 原名 -> 别名

 @param orig 原名
 @return 别名
 */
- (NSString *)aliasForOrig:(NSString *)orig;

@end

