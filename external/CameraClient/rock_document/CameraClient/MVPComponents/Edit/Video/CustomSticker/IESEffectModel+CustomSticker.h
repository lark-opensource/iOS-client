//
//  IESEffectModel+CustomSticker.h
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/12/18.
//

#import <EffectPlatformSDK/IESEffectModel.h>
#import "AWECustomStickerLimitConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESEffectModel (CustomSticker)

- (AWECustomStickerLimitConfig *)limitConfig;

@end

NS_ASSUME_NONNULL_END
