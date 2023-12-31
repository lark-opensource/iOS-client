//
//  ZimGatewayForPop.h
//  AliyunIdentityManager
//
//  Created by sanyuan.he on 2020/3/31.
//  Copyright © 2020 Alipay. All rights reserved.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@class ZimInitRequest;
@class ZimValidateRequest;
/**
 *  rpc结果回调
 *
 *  @param success 网络交互是否成功(不代表服务端返回的结果)
 *  @param result  服务端返回的结果
 */
typedef void (^rpcCompletionBlock)(BOOL success, NSObject *result);



@interface ZimGatewayForPop : NSObject

/**
 初始化函数
 */

- (void)doInitRequest:(ZimInitRequest * )request withcompletionBlock:(rpcCompletionBlock)blk;

/**
 认证请求
 */
- (void)doValidateRequest:(ZimValidateRequest *)request bioMeta:(NSString *)bioMeta zimVer:(NSString *)zimVer withcompletionBlock:(rpcCompletionBlock)blk;


/**
OCR请求
*/

- (void) startSendOCRContent:(NSString*)certifyId certifyData:(NSString*)side withImage:(NSData*)imageData withcompletionBlock:(rpcCompletionBlock)blk;

@end

NS_ASSUME_NONNULL_END

