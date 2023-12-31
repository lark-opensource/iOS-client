// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESForestPreloadSubResourceConfig : NSObject

@property (nonatomic, copy) NSString *url;
@property (nonatomic, assign) BOOL enableMemory;

+ (instancetype)configWithDictionary:(NSDictionary *)dictionary;

@end

@interface IESForestPreloadConfig : NSObject

@property (nonatomic, copy) NSString *mainUrl;
@property (nonatomic, copy) NSDictionary *subResources;

- (NSArray<IESForestPreloadSubResourceConfig *> *)otherResources;

- (NSArray<IESForestPreloadSubResourceConfig *> *)imageResources;

@end

NS_ASSUME_NONNULL_END
