// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDWebForestUtil : NSObject

+ (NSURL *)urlWithURLString:(NSString *)urlString queryParameters:(NSDictionary *)params;

@end

NS_ASSUME_NONNULL_END
