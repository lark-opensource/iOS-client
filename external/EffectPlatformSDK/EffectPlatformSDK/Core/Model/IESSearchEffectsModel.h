//
//  IESSearchEffectsModel.h
//  EffectPlatformSDK
//
//  Created by pengzhenhuan on 2021/5/31.
//

#import "IESEffectModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESSearchEffectsModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy) NSString *searchTips;//无结果时返回

@property (nonatomic, copy) NSString *searchID;

@property (nonatomic, assign) NSInteger cursor;

@property (nonatomic, assign) BOOL hasMore;

@property (nonatomic, assign) BOOL isUseHot;//是否空搜

@property (nonatomic, strong) NSArray<IESEffectModel *> *effects;

@property (nonatomic, strong) NSArray<IESEffectModel *> *collection;

@property (nonatomic, strong) NSArray<IESEffectModel *> *bindEffects;

- (void)updateEffects;

@end

NS_ASSUME_NONNULL_END
