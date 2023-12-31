//
//  TTAdSplashLogModule.h
//  Pods-TTAdSplashSDK_Example
//
//  Created by yin on 2017/11/28.
//

#import <Foundation/Foundation.h>
#import "TTAdSplashHeader.h"

@class TTAdSplashModel;
typedef NS_ENUM(NSUInteger, TTAdSplashLogShowType) {
    TTAdSplashLogShowType_Show,
    TTAdSplashLogShowType_Skip,
};

@interface TTAdSplashLogModule : NSObject

+ (instancetype) sharedInstance;

/**
  因为推送、open_url等不出
 */
- (void)splashIgnoreWithLaunch;

/**
 因为超过show_limit、横屏不出

 @param remainCount 是否有剩余展示次数
 @param landscape 是否横屏
 */
- (void)splashIgnoreWithRemainCount:(BOOL)remainCount landscape:(BOOL)landscape;

/**
  因为首刷不出

 @param splashModel 广告model
 */
- (void)splashIgnoreWithFirstSplash:(TTAdSplashModel *)splashModel;

/**
  因为不符合条件model不被选中

 @param reasonType 原因
 @param splashModel 广告model
 */
- (void)splashIgnoreWithReasonType:(TTAdSplashReadyType)reasonType splashModel:(TTAdSplashModel *)splashModel;

/**
  请求到无广告
 */
- (void)splashIgnoreWithRequestEmptyModels;

/**
  本地广告数据为空
 */
- (void)splashIgnoreWithLocalEmptyModels;

/**
 展示

 @param splashModel 广告model
 */
- (void)splashShowWithModel:(TTAdSplashModel *)splashModel;

/**
  请求到图片异常 白屏
 
 @param splashModel 广告model
 */
- (void)splashRequestImageEmptyWithModel:(TTAdSplashModel *)splashModel;

/**
  展示时图片异常 白屏
 
 @param splashModel 广告model
 */
- (void)splashShowImageEmptyWithModel:(TTAdSplashModel *)splashModel;

/**
  写本地日志

 @param showType 是否展示
 @param reasonType  不展示的原因
 @param splashModel 广告model
 */
- (void)logWithShowType:(TTAdSplashLogShowType)showType reasonType:(TTAdSplashReadyType)reasonType splashModel:(TTAdSplashModel *)splashModel;

/**
 开屏请求日志
 
 @param dict 返回广告数据
 */
- (void)splashLogWithRequstDict:(NSDictionary *)dict;

@end
