//
//  TTAdSplashManager+Request.h
//  FLEX
//
//  Created by yin on 2018/5/6.
//

#import "TTAdSplashManager.h"
#import "BDASplashControlModel.h"

@interface TTAdSplashManager (Request)

//请求开屏接口
- (void)fetchADControlInfo;

/// 外部设置实时的开屏控制信息，（通常是长连接）
/// @param controlInfo 控制信息
- (void)setRealTimeControlInfo:(NSDictionary *)controlInfo;

- (void)setRealTimeControlModel:(BDASplashControlModel *)controlMode fromUDP:(BOOL)fromUDP;

/**
 更新本地缓存广告model array
 
 @param models 广告model array
 */
- (void)updateADControlInfoForSplashModels:(NSArray *)models;

/**
 * 确认广告展示成功
 * @param model 当前正在展示的广告模型
 */
- (void)sendACK:(TTAdSplashModel *)model;

/*
 更新本地首刷广告缓存 model, 缓存广告单独存储了一个队列, 用于回捞

 @param models 首刷广告 array
 */
- (void)updateADControlInfoForFirstLaunchSplashModels:(NSArray *)models;

+ (void)updateADControlInfoModels:(NSArray *)models modelSaveKey:(NSString *)key;

/**
  下次展现的models
 @return 广告models
 */
+ (NSArray *)getSplashModelsInCache;

+ (NSArray *)getFristLaunchModels;

+ (void)cleanFirstLaunchModels;
@end
