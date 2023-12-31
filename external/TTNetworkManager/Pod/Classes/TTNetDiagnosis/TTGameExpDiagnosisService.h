//
//  TTGameExpDiagnosisService.h
//  TTNetworkManager
//
//  Created by zhangzeming on 2021/6/28.
//  Copyright © 2021 bytedance. All rights reserved.
//

#ifndef TTGameExpDiagnosisService_h
#define TTGameExpDiagnosisService_h

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface TTGameExpDiagnosisService : NSObject

/**
 *  生成TTGameExpDiagnosisService单例
 *
 *  @return TTGameExpDiagnosisService单例
 */
+ (instancetype)shareInstance;

/**
 * 游戏对局开始时调用。
 * @param target 诊断目的地址。当内部检测到网络跳变，或者业务外部触发诊断时，会对
 *               该目标地址路径上的关键节点发起ping测速。
 * @param extraInfo 关于此次检测任务的辅助描述信息。例如第三方公司可传入player ID等标识用户的信息，后续
 *                  日志上报时会带上。如无需要，可传入null。
 */
- (void)monitorBegin:(NSString*)target extraInfo:(nullable NSString*)extraInfo;

/**
 * 游戏对局结束时调用。网络检测日志以及对局中产生的诊断日志会上报到云端。
 */
- (void)monitorEnd;

/**
 * 游戏对局结束时调用。网络检测日志以及对局中产生的诊断日志会上报到云端。
 * @param extraInfo 关于此次检测任务的辅助描述信息。例如第三方公司可传入player ID等标识用户的信息，后续
 *                  日志上报时会带上。如无需要，可传入null。
 */
- (void)monitorEnd:(nullable NSString*)extraInfo;

/**
 * 游戏对局过程中调用。例如业务检测到游戏帧卡顿，可调用此接口发起诊断。
 * @param extraMessage 附加在诊断结果中的信息，可以是发起此次诊断的原因。字符串长度有限，超过的部分会被
 *                     截掉。该限制可由TNC云控配置，但是建议不要超过10个字符。
 */
- (void)doDiagnosisDuringGaming:(NSString*)extraMessage;

@end
NS_ASSUME_NONNULL_END
#endif /* TTGameExpDiagnosisService */
