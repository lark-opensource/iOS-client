//
//  ADFGBridgeCommand.h
//  ADFGBridgeUnify
//
//  Modified from TTRexxar of muhuai.
//  Created by iCuiCui on 2020/04/30.
//

#import <Foundation/Foundation.h>
#import "ADFGBridgeDefines.h"
#import "ADFeelGoodWebHeader.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ADFGBridgeType) {
    ADFGBridgeTypeCall= 0,
    ADFGBridgeTypeOn,
};

@interface ADFGBridgeCommand : NSObject
/**
 前端传过来的方法名,
 */
@property(nonatomic, copy, nullable) ADFGBridgeName bridgeName;

/**
 调用方式：js调原生/原生调js，如果为on方式，固定为event
*/
@property(nonatomic, copy, nullable) NSString *messageType;

/**
 函数名称/事件名称
*/
@property(nonatomic, copy, nullable) NSString *callbackID;

/**
 扩展参数
*/
@property(nonatomic, copy, nullable) NSDictionary *params;

/**
 JSSDK版本号
 */
@property(nonatomic, copy, nullable) NSString *JSSDKVersion;

/**
 调用方式的类型：call/on
*/
@property (nonatomic, assign) ADFGBridgeType bridgeType;


@property(nonatomic, assign) ADFGBridgeMsg bridgeMsg;

/**
 格式："Class.method"
 */
@property(nonatomic, copy, nullable) NSString *pluginName;

/**
 plugin的 类名
 */
@property(nonatomic, copy, nullable) NSString *className;

/**
 plugin的 方法名
 */
@property(nonatomic, copy, nullable) NSString *methodName;


@property(nonatomic, strong, readonly) NSString *wrappedParamsString;


- (instancetype)initWithDictonary:(NSDictionary *)dic;


@end

NS_ASSUME_NONNULL_END
