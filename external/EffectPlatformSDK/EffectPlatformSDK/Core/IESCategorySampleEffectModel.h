//
//  IESCategoryEffectModel.h
//  EffectPlatformSDK
//
//  Created by Fengfanhua.byte on 2021/9/27.
//

#import <Mantle/Mantle.h>
#import "IESEffectModel.h"
#import "IESEffectSampleVideoModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESCategorySampleEffectModel : MTLModel<MTLJSONSerializing>

// 版本号
@property (nonatomic, copy, readonly) NSString *version;
// 分类key
@property (nonatomic, copy, readonly) NSString *categoryKey;

// 特效
@property (nonatomic, copy, readonly) IESEffectModel *effect;

// 视频信息
@property (nonatomic, copy, readonly) IESEffectSampleVideoModel *video;

@end

NS_ASSUME_NONNULL_END
