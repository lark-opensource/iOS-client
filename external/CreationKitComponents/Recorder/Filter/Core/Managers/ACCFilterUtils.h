//
//  ACCFilterUtils.h
//  CameraClient
//
//  Created by Me55a on 2020/2/11.
//

#import <Foundation/Foundation.h>
#import <EffectPlatformSDK/EffectPlatform.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCFilterUtils : NSObject

+ (IESEffectModel *)prevFilterOfFilter:(IESEffectModel *)filter filterArray:(NSArray *)filterArray;
+ (IESEffectModel *)nextFilterOfFilter:(IESEffectModel *)filter filterArray:(NSArray *)filterArray;

@end

NS_ASSUME_NONNULL_END
