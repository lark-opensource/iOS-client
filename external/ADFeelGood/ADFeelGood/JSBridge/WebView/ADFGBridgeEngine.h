//
//  ADFGBridgeEngine
//  ADFGBridgeUnify
//
//  Modified from TTRexxar of muhuai.
//  Created by iCuiCui on 2020/04/30.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ADFGBridgeDefines.h"

NS_ASSUME_NONNULL_BEGIN

@class ADFGBridgeRegister;

@protocol ADFGBridgeEngine <NSObject>

@required

/**
 engine所在的ViewController, 提供Bridge更多的上下文. 可为空.
 */
@property (nonatomic, weak, nullable) UIViewController *sourceController;

/**
 engine当前页面地址
 */
@property (nonatomic, strong, readonly, nullable) NSURL *sourceURL;

/**
 engine挂载的对象，当前为wkWebView
 */
@property (nonatomic, weak, readonly) NSObject *sourceObject;

/**
 局部 register, 仅在当前 engine 生效，同名 bridge 优先执行局部 register 下注册的
 */
@property(nonatomic, strong, readonly) ADFGBridgeRegister *bridgeRegister;

@optional

- (BOOL)respondsToBridge:(ADFGBridgeName)bridgeName;

@end
NS_ASSUME_NONNULL_END
