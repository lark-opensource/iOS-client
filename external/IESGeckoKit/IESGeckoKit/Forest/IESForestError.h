// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, IESForestErrorCode) {
    IESForestErrorWorkflowCancel = 1,
    IESForestErrorWorkflowNoFetchers = 2,

    IESForestErrorMemoryCacheKeyError = 10,
    IESForestErrorMemoryNoCache = 20,
    IESForestErrorMemoryCacheExpired = 30,

    IESForestErrorGeckoAccessKeyEmpty = 100,
    IESForestErrorGeckoChannelBundleEmpty = 200,
    IESForestErrorGeckoChannelBundleInvalid = 300,
    IESForestErrorGeckoLocalFileNotFound = 400,
    IESForestErrorGeckoUpdateFailed = 500,
    IESForestErrorGeckoUpdatedButLocalFileNotFound = 600,
    IESForestErrorGeckoDisabled = 700,

    IESForestErrorBuiltinParameterInvalid = 1000,
    IESForestErrorBuiltinPathInvalid = 2000,
    IESForestErrorBuiltinFileNotFound = 3000,

    IESForestErrorCDNURLEmpty = 10000,
    IESForestErrorCDNURLInvalid = 20000,
    IESForestErrorCDNNetworkError = 30000,
    IESForestErrorCDNDataEmpty = 40000,

    IESForestErrorCustomFetcherError = 100000
};

@interface IESForestError : NSObject

+ (NSError *)errorWithCode:(IESForestErrorCode)code message:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
