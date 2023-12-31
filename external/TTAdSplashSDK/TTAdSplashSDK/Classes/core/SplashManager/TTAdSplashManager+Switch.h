//
//  TTAdSplashManager+Switch.h
//  TTAdSplashSDK
//
//  Created by bytedance on 2018/9/17.
//

#import "TTAdSplashManager.h"


// 开屏广告 停投逻辑
@interface TTAdSplashManager (Switch)
/** 请求的udp地址列表 */
@property (nonatomic, strong) NSArray<NSString *> *ipList;

- (void)startFetchSwitchCommand:(BOOL)ht;

/**
 *  @brief 根据当前udp请求的状态或者结果决定是否可以展示Ad，如果当前请求结束则根据解析的结果返回，如果当前请求未结束，则返回YES。
 *  @return defaults to YES，else according to data returned.
 */
- (BOOL)shouldShowAdWithUDPResult;

/**
 *  @brief udp是否请求求成功
 *  @return udp请求成功 YES，否则NO
 */
- (BOOL)UDPRequestSuccessfully;

/// 返回UDP请求返回的服务器时间
- (NSTimeInterval)UDPTimestamp;

@end
