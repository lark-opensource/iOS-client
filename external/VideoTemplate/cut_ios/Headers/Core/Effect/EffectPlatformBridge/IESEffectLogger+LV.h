//
//  IESEffectLogger+LV.h
//  VideoTemplate
//
//  Created by Nemo on 2021/1/24.
//

#import <EffectPlatformSDK/IESEffectLogger.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESEffectLogger (LV)
/// EffectPlatform 的 logger 单例 Swift 中会识别成 .init()，包一层
@property(nonatomic, strong, class) IESEffectLogger *defaultLogger;

@end

NS_ASSUME_NONNULL_END
