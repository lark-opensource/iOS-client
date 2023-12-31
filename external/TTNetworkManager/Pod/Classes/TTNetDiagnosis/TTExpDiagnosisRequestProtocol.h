//
//  TTExpDiagosisRequestProtocol.h
//  TTNetworkManager
//
//  Created by zhangzeming on 2021/6/14.
//  Copyright © 2021 bytedance. All rights reserved.
//

#ifndef TTExpDiagosisRequestProtocol_h
#define TTExpDiagosisRequestProtocol_h

#import <Foundation/Foundation.h>

@protocol TTExpDiagnosisRequestProtocol <NSObject>

@required

/**
 * 开始执行请求
 */
- (void)start;

/**
 * 取消请求，将不会有回调。
 */
- (void)cancel;


/**
 * 在请求执行工程中触发额外命令。
 * 该接口目前只对Poll类型的请求有效。
 * @param command 命令名称。目前仅支持"diagnosis"，即polling过程中发起诊断。
 * @param extraMessage 执行command的时候需要传递的额外信息或参数，可以是发起诊断的原因描述。
 *                     长度可通过TNC云控，超出的部分会被截断。
 */
- (void)doExtraCommand:(NSString*)command
          extraMessage:(NSString*)extraMessage;


/**
 * 设置此次检测任务的辅助描述信息。例如第三方公司可传入player ID等标识用户的信息，后续
 * 日志上报时会带上"user_extra_info"字段。
 * @param extraInfo 辅助描述信息。如果多次调用，则只保留最近一次设置的结果。
 */
- (void)setUserExtraInfo:(NSString*)extraInfo;

@end

#endif /* TTExpDiagosisRequestProtocol_h */
