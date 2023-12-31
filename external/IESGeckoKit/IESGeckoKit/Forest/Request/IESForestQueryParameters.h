// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESForestQueryParameters : NSObject

@property (nonatomic, strong) NSNumber *waitGeckoUpdate;
@property (nonatomic, strong) NSNumber *onlyOnline;
@property (nonatomic, strong) NSNumber *dynamic;

- (instancetype)initWithURLString:(NSString *)urlString;

@end

NS_ASSUME_NONNULL_END
