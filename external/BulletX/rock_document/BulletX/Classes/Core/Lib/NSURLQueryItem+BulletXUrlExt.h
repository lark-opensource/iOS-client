//
//  NSURLQueryItem+BulletUrlExt.h
//  AAWELaunchOptimization
//
//  Created by duanefaith on 2019/10/12.
//

NS_ASSUME_NONNULL_BEGIN

@interface NSURLQueryItem (BulletXUrlExt)

+ (instancetype)bullet_queryItemWithName:(NSString *)name unencodedValue:(nullable NSString *)unencodedValue;

@end

NS_ASSUME_NONNULL_END
