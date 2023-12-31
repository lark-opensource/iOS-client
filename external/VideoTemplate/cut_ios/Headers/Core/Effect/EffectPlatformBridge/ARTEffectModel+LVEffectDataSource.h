//
//  ARTEffectModel+LVEffectDataSource.h
//  VideoTemplate
//
//  Created by wuweixin on 2020/11/10.
//

#import <ArtistOpenPlatformSDK/ARTEffectHeader.h>
#import "LVEffectDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTEffectModel (EffectPrototype)<LVEffectPrototype>
@end

@interface ARTEffectModel (LVEffectDataSource)<LVEffectDataSource>

@end

NS_ASSUME_NONNULL_END
