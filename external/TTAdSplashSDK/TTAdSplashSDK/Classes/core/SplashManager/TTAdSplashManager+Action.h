//
//  TTAdSplashManager+Action.h
//  FLEX
//
//  Created by yin on 2018/5/6.
//

#import "TTAdSplashManager.h"
#import "TTAdSplashControllerView.h"

@interface TTAdSplashManager (Action)<TTAdSplashControllerViewDelegate>

+ (NSDictionary *)generateAdTrackExtraData:(TTAdSplashModel *)model extra:(NSDictionary *)extra;

+ (NSDictionary *)generateAdTrackExtraData:(TTAdSplashModel *)model adExtra:(NSDictionary *)adExtra;

+ (NSDictionary *)generateAdTrackExtraData:(TTAdSplashModel *)model extra:(NSDictionary *)extra adExtra:(NSDictionary *)adExtra;

/**
 * 判断非点击区域是否可点击：YES可以展示；NO不可以展示
 * @param adModel 广告model
 * @param clickCount 点击次数
 * @param displayTime 开屏已展示时间，单位为ms
 * @return 是否可点击
 */
- (BOOL)enableClickWithAdModel:(TTAdSplashModel *)adModel clickCount:(NSUInteger)clickCount displayTime:(NSTimeInterval)displayTime;

@end
