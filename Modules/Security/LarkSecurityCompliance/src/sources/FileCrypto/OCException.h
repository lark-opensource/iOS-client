//
//  OCException.h
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/7/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OCException : NSObject

+ (BOOL)catch:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error;

@end

NS_ASSUME_NONNULL_END
