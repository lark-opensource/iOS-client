//
//  NSBundle+BTDAdditions.h
//  Pods
//
//  Created by yanglinfeng on 2019/7/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBundle (BTDAdditions)

+ (nullable NSString *)btd_appDisplayName;

+ (nullable NSString *)btd_versionName;

+ (nullable NSString *)btd_bundleIdentifier;

@end

NS_ASSUME_NONNULL_END
