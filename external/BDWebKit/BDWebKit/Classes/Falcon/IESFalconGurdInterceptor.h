//
//  IESFalconGurdInterceptor.h
//  Pods
//
//  Created by 陈煜钏 on 2019/9/19.
//

#if __has_include(<IESGeckoKit/IESGeckoKit.h>)

#import <Foundation/Foundation.h>

#import "IESFalconCustomInterceptor.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESFalconGurdInterceptor : NSObject<IESFalconCustomInterceptor>

- (void)registerPattern:(NSString *)pattern forGurdAccessKey:(NSString *)accessKey;

- (void)registerPatterns:(NSArray <NSString *> *)patterns forGurdAccessKey:(NSString *)accessKey;

- (void)unregisterPatterns:(NSArray <NSString *> *)patterns;

@end

NS_ASSUME_NONNULL_END

#endif
