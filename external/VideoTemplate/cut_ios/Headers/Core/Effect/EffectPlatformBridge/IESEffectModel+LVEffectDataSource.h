//
//  IESEffectModel+IESEffectDataSource.h
//  ArtistOpenPlatformSDK
//
//  Created by wuweixin on 2020/10/21.
//

#import <EffectPlatformSDK/IESEffectModel.h>
#import "LVEffectDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESEffectModel (EffectPrototype)<LVEffectPrototype>
@end

@interface IESEffectModel (LVEffectDataSource)<LVEffectDataSource>

@end

NS_ASSUME_NONNULL_END
