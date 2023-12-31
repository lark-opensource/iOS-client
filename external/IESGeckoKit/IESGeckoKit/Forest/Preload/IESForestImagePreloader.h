//
//  IESForestImagePreloader.h
//  IESGeckoKit-c0aad4e9
//
//  Created by ruichao xue on 2022/9/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESForestImagePreloader : NSObject

+ (void)preloadWithURLString:(NSString * _Nonnull)urlString
                enableMemory:(BOOL)enableMemory;

+ (BOOL)hasCacheImageForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
