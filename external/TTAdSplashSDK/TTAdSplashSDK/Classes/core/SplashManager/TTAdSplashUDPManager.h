//
//  TTAdSplashUDPManager.h
//  TTAdSplashSDK
//
//  Created by resober on 2018/12/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class TTAdSplashUDPManager;
typedef void(^TTAdSplashUDPManagerFinishBlock)(__weak TTAdSplashUDPManager *udpManager);
@interface TTAdSplashUDPManager : NSObject
/** 请求的udp地址列表 */
@property (nonatomic, strong) NSArray<NSString *> *ipList;
/** 所有请求完成（或者超时）并且上报埋点后调用此回调 */
@property (nonatomic, copy) TTAdSplashUDPManagerFinishBlock finishblock;
/** UDP请求是否正常的返回了结果来决定是否展示广告 */
@property (nonatomic, assign, readonly) BOOL UDPRequestSuccessfully;
/** UDP请求成功的前提下，决定是否展示开屏广告 */
@property (nonatomic, assign, readonly) BOOL UDPDecideToShowSplash;
/// 数据请求成功时的时间戳
@property (nonatomic, assign, readonly) NSTimeInterval timestamp;

- (void)startFetchSwitchCommand:(BOOL)ht;

/**
 *  @brief 根据当前udp请求的状态或者结果决定是否可以展示Ad，如果当前请求结束则根据解析的结果返回，如果当前请求未结束，则返回YES。
 *  @return defaults to YES，else according to data returned.
 */
- (BOOL)shouldShowAdWithUDPResult;
@end

NS_ASSUME_NONNULL_END
