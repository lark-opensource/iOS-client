//
//  IESUserUsedStickerResponseModel.h
//  EffectPlatformSDK
//
//  Created by zhangchengtao on 2020/3/10.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>
#import <EffectPlatformSDK/IESEffectModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESUserUsedStickerResponseModel : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy) NSArray<IESEffectModel *> *effects;

@property (nonatomic, copy) NSArray<IESEffectModel *> *collection;

@end

NS_ASSUME_NONNULL_END
