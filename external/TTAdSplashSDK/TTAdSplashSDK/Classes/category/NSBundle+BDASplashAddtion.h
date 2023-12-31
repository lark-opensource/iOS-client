//
//  NSBundle+BDASplashAddtion.h
//  ABRInterface
//
//  Created by YangFani on 2020/5/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBundle (BDASplashAddtion)

+ (NSBundle *)bdaSplashBundle;

+ (NSBundle *)bdaSplashCoreBundle;

+ (UIImage *)bdaSplashImageNamed:(NSString *)name;

+ (UIImage *)bdaSplashCoreImageNamed:(NSString *)name;

+ (NSString *)bdaCoreBundlePathWithFileName:(NSString *)fileName;

@end

NS_ASSUME_NONNULL_END
