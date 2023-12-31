//
//  BDPJSSDKForceUpdateManager.h
//  TTMicroApp
//
//  Created by Nicholas Tau on 2021/2/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
//强制JSSDK版本更新管理器
extern NSString * const BDPJSSDKSyncForceUpdateBeginNoti;
extern NSString * const BDPJSSDKSyncForceUpdateFinishNoti;
@interface BDPJSSDKForceUpdateManager : NSObject
+ (instancetype)sharedInstance;
/// 强制JSSDK更新，同步返回结果
///ATTENTION：forceJSSDKUpdateWaitUntilCompeteOrTimeout 强制触发jssdk同步更新流程
/// 若收到更新完成通知返回 YES
/// 若超时返回 NO
-(BOOL)forceJSSDKUpdateWaitUntilCompeteOrTimeout;
@end

NS_ASSUME_NONNULL_END
