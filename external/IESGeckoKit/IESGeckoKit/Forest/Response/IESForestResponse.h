// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import "IESForestResponseProtocol.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, IESForestDataSourceType);
@class IESForestRequest;
@class IESForestEventTrackData;

@interface IESForestResponse : NSObject <IESForestResponseProtocol>

- (instancetype)initWithRequest:(IESForestRequest *)request;
+ (instancetype)responseWithResponse:(id<IESForestResponseProtocol>)response;
@property (nonatomic, strong) IESForestRequest *request;

@property (nonatomic, copy) NSString *accessKey;
@property (nonatomic, copy) NSString *channel;
@property (nonatomic, copy) NSString *bundle;
@property (nonatomic, assign) uint64_t version;

// use atomic to prevent crash when set in different threads
@property (atomic, copy) NSData *data;
@property (nonatomic, assign) IESForestDataSourceType sourceType;

/// the url passed to forest
@property (nonatomic, copy) NSString *sourceUrl;
/// the local absolute path
@property (nonatomic, copy) NSString *absolutePath;
/// local path exist => absolutePath
/// local path NOT exist but not disableCDN => sourceURL
/// local path NOT exist and disableCDN => nil
@property (nonatomic, copy, readonly, nullable) NSString *resolvedURL;

@property (nonatomic, strong) NSDate *expiredDate;

@property (nonatomic, copy) NSString *fetcher;
@property (nonatomic, copy) NSString *debugInfo;
@property (nonatomic, copy) NSString *cacheKey;
@property (nonatomic, strong, readonly) IESForestEventTrackData *eventTrackData;

- (NSString *)sourceTypeDescription;
- (BOOL)isSuccess;

@end

NS_ASSUME_NONNULL_END
