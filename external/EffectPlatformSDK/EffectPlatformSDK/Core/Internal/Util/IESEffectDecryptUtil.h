//
//  IESEffectDecryptUtil.h
//  AAWELaunchOptimization-Pods
//
//  Created by pengzhenhuan on 2020/8/31.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESEffectDecryptUtil : NSObject

+ (NSString *)decryptString:(NSString *)encryptString;
+ (NSArray<NSString *> *)decryptArray:(NSArray<NSString *> *)encryptArray;

@end

NS_ASSUME_NONNULL_END
