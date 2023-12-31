//
//  TTAdSplashTracker.h
//  FLEX
//
//  Created by yin on 2018/5/4.
//

#import <Foundation/Foundation.h>
#import "TTAdSplashHeader.h"
#define TrackerInstance [TTAdSplashTracker shareInstance]

@class TTAdSplashModel;
@class TTAdSplashRealTimeFetchModelItem;

@interface TTAdSplashTracker : NSObject

+ (instancetype)shareInstance;

/**
 *  通过该埋点统计停投命令的请求状态，状态标识为成功、失败
 *  通过该埋点统计停投的请求成功时长，单位 ms
 *  增加参数表示
 *  因为每次开屏均有停投请求，所以每次开屏均上报该埋点。
 */
- (void)trackUDPStopShowingMonitorWithExtraData:(NSDictionary *)extraData;

/**
 *  遍历所有udp请求的时间，上报
 */
- (void)trackAllUDPMonitorWithExtraData:(NSDictionary *)extraData;

/**
 *  @brief 上报冷启动的开屏SDK初始化时间~开屏广告展示时间，即请求可利用时间
 *  在 ad_extra_data 里增加 duration 字段来表示时长，单位ms
 *  固定 cid 84378473382
 */
- (void)trackSdkInitialTimeCost;

/**
 预加载图片资源成功与否的打点

 @param splashModel 广告model
 @param success 是否成功
 @param isEncrypted 是否加密
 */
- (void)imagePreload:(TTAdSplashModel *)splashModel success:(BOOL)success isEncrypted:(BOOL)isEncrypted;

/**
 预加载视频资源成功与否的打点
 
 @param splashModel 广告model
 @param success 是否成功
 */
- (void)videoPreload:(TTAdSplashModel *)splashModel success:(BOOL)success;

/**
 应该展示:满足首刷、展示开始结束时间因素  表征服务端投放量是否合理

 @param splashModel 广告model
 */
- (void)splashShouldShow:(TTAdSplashModel *)splashModel;

/**
 是否展示:should_show场景下,cause by展示间隔、后台时长、预加载不成功

 @param splashModel 广告model
 @param type 不展示原因
 */
- (void)splashNotShow:(TTAdSplashModel *)splashModel type:(TTAdSplashReadyType)type;

- (void)newSplashNotShow:(TTAdSplashModel *)splashModel type:(TTAdSplashReadyType)type;

- (void)splashDidShow:(BOOL)didShow model:(TTAdSplashModel *)splashModel type:(TTAdSplashReadyType)type;

/**
  检测当前请求到广告队列首位覆盖前一缓存队列首位埋点

 @param array 当前请求到广告队列
 @param originModels 前一轮缓存队列
 */
- (void)checkCoverModels:(NSArray<TTAdSplashModel *>*)array originModels:(NSArray<TTAdSplashModel *>*)originModels;

- (void)checkFristLaunchCoveredWithLocalModels:(NSArray *)localModels;

/**
 检测下发数据中是否有 top view，无论是否处于第一位，都会上报。

 @param models 本次下发的 model, 类型为 TTAdSplashModel
 */
- (void)trackTopViewModels:(NSArray <TTAdSplashModel *> *)models;

/**
 检测实时开屏下发数据中是否有 top view，无论是否处于第一位，都会上报。

 @param models 本次下发的 model, 类型为 TTAdSplashRealTimeFetchModelItem
 */
- (void)trackTopViewRealTimeModels:(NSArray<TTAdSplashRealTimeFetchModelItem *> *)models;

/**
 事件上报，label 默认为 splash_ad

 @param label 事件 label
 @param adModel 广告 model
 */
- (void)trackEventWithLabel:(NSString *)label adModel:(TTAdSplashModel *)adModel;


/**
 事件上报，label 默认为 splash_ad
 
 @param label 事件 label
 @param adModel 广告 model
 @param adExtra 广告里面额外带的信息，最终会以 json 字符串的形式加到 extra 中
 */
- (void)trackEventWithLabel:(NSString *)label adModel:(TTAdSplashModel *)adModel extra:(NSDictionary *)extra adExtra:(NSDictionary *)adExtra;

/**
 事件上报

 @param tag 上报事件的 tag
 @param label 上报事件的 label
 @param adId 广告 ID
 @param logExtra 广告信息
 */
- (void)trackEventWithTag:(NSString *)tag
                    label:(NSString *)label
                     adId:(NSString *)adId
                 logExtra:(NSString *)logExtra;

/**
 事件上报
 
 @param tag 上报事件的 tag
 @param label 上报事件的 label
 @param adId 广告 ID
 @param logExtra 广告信息
 @param extra 额外信息
 */
- (void)trackEventWithTag:(NSString *)tag
                    label:(NSString *)label
                     adId:(NSString *)adId
                 logExtra:(NSString *)logExtra
                    extra:(NSDictionary *)extra;

/**
 事件上报
 
 @param tag 上报事件的 tag
 @param label 上报事件的 label
 @param adId 广告 ID
 @param logExtra 广告信息
 @param extra 额外信息
 @param adExtra 广告里面额外带的信息，最终会以 json 字符串的形式加到 extra 中。
 */
- (void)trackEventWithTag:(NSString *)tag
                    label:(NSString *)label
                     adId:(NSString *)adId
                 logExtra:(NSString *)logExtra
                    extra:(NSDictionary *)extra
                  adExtra:(NSDictionary *)adExtra;

- (void)trackV3Event:(NSString *)event extra:(NSDictionary *)extra adExtra:(NSDictionary *)adExtra;

@end
