//
//  IESFalconFileInterceptor.h
//  Pods
//
//  Created by 陈煜钏 on 2019/9/19.
//

#import <Foundation/Foundation.h>

#import "IESFalconCustomInterceptor.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESFalconFileInterceptor : NSObject<IESFalconCustomInterceptor>

- (void)registerPattern:(NSString *)pattern forSearchPath:(NSString *)searchPath;

- (void)registerPatterns:(NSArray <NSString *> *)patterns forSearchPath:(NSString *)searchPath;

- (void)unregisterPatterns:(NSArray <NSString *> *)patterns;

@end

NS_ASSUME_NONNULL_END
