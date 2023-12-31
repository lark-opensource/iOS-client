//
//  IESEffectTopListResponseModel.h
//  EffectPlatformSDK
//
//  Created by pengzhenhuan on 2021/10/18.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>
#import "IESEffectModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESEffectTopListResponseModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) int cursor;

@property (nonatomic, assign) int lastUpdatedTime;

@property (nonatomic, copy) NSArray<IESEffectModel *> *effects;

@property (nonatomic, copy) NSArray<IESEffectModel *> *bindEffects;

- (void)updateEffects;

@end

NS_ASSUME_NONNULL_END
