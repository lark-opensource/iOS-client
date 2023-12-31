//
//  NSString+EffectPlatformUtils.h
//  EffectPlatformSDK
//
//  Created by 赖霄冰 on 2019/8/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (EffectPlatformUtils)

- (nonnull NSString *)ep_md5String;
- (nonnull NSString *)ep_generateMD5Key;
@end

NS_ASSUME_NONNULL_END
