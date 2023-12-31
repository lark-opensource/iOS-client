//
//  IESEffectPlatformResponseModel.h
//  EffectPlatformSDK
//
//  Created by ziyu.li on 2018/2/24.
//

#import <Mantle/Mantle.h>
#import <Foundation/Foundation.h>
#import "IESEffectModel.h"
#import "IESCategoryModel.h"
#import "IESPlatformPanelModel.h"

NS_ASSUME_NONNULL_BEGIN
@interface IESEffectPlatformResponseModel : MTLModel<MTLJSONSerializing>
// 版本号
@property (nonatomic, copy, readonly) NSString *version;
// 默认前置滤镜
@property (nonatomic, copy, readonly) NSString *defaultFrontFilterID;
// 默认后置滤镜
@property (nonatomic, copy, readonly) NSString *defaultRearFilterID;
// 聚合的所有子特效
@property (nonatomic, copy, readonly) NSArray <IESEffectModel *> *collection;
// 总的特效列表
@property (nonatomic, copy, readonly) NSArray <IESEffectModel *> *effects;
// 带分类的特效列表
@property (nonatomic, copy, readonly) NSArray <IESCategoryModel *> *categories;
// 已下载的特效列表
@property (nonatomic, copy, readonly) NSArray *downloadedEffects;
// 面板信息
@property (nonatomic, readonly, strong) IESPlatformPanelModel *panel;

@property (nonatomic, copy, readonly) NSMutableDictionary <NSString *, IESEffectModel *> *effectsMap;

@property (nonatomic, copy, readonly) NSArray<NSString *> *urlPrefix;

@property (nonatomic, copy) NSString *requestID;

- (void)setPanelName:(NSString *)panelName;
- (void)preProcessEffects;

@end
NS_ASSUME_NONNULL_END
