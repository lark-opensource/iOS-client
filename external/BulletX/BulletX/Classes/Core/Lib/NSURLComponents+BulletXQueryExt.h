//
//  NSURLComponents+BulletXQueryExt.h
//  AAWELaunchOptimization
//
//  Created by duanefaith on 2019/10/12.
//

NS_ASSUME_NONNULL_BEGIN

@interface NSURLComponents (BulletXQueryExt)

- (void)bullet_appendQueryItem:(nonnull NSURLQueryItem *)queryItem;
- (void)bullet_prependQueryItem:(nonnull NSURLQueryItem *)queryItem;

@end

NS_ASSUME_NONNULL_END
