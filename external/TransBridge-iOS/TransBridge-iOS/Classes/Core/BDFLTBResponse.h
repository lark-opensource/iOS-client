//
//  TTRBridgeResponse.h
//  Runner
//
//  Copyright © 2020 Toutiao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDFLTBResponseProtocol.h"

/**
 * Bridge response，对齐 via v2 https://wiki.bytedance.net/pages/viewpage.action?pageId=177232834
 * 在 channel response 层兼容旧版
 */
@interface BDFLTBResponse : NSObject <FLTBResponseProtocol>

/**
 * 完整构造
 */
- (instancetype)initWithCode:(NSInteger)code message:(NSString *)message data:(id)data;

/**
* 判断是否失败 response
*/
- (BOOL)isError;

/**
* 判断是否未实现 response
*/
- (BOOL)isNotImplement;

/**
* 简易构造成功response
*/
+ (instancetype)successResponseWithData:(id)data;

/**
* 简易构造失败response
*/
+ (instancetype)errorResponseWithMessage:(NSString *)message;

/**
* 简易构造没权限response
*/
+ (instancetype)noPrivilegeResponseWithName:(NSString *)name;

/**
* 简易构造未实现response
*/
+ (instancetype)notImplementResponseWithName:(NSString *)name;

@end
