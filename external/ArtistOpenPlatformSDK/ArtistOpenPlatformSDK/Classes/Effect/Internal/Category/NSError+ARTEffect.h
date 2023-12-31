//
//  NSError+ARTEffect.h
//  ArtistOpenPlatformSDK
//
//  Created by wuweixin on 2020/10/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSError (ARTEffect)

+ (NSError *)arteffect_errorWithCode:(NSInteger)code description:(NSString *)description;

@end

NS_ASSUME_NONNULL_END
