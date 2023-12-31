//
//  BDAutoTrackABConfig.h
//  RangersAppLog
//
//  Created by bob on 2019/9/12.
//

#import "BDAutoTrackService.h"

NS_ASSUME_NONNULL_BEGIN

@class BDAutoTrack;
@interface BDAutoTrackABConfig : BDAutoTrackService

@property (nonatomic, weak) BDAutoTrack *tracker;

- (void)setExternalVersions:(NSString *)versions;

- (NSString *)externalVersions;

@property (nonatomic, nullable) NSString * alinkABVersions;
@property (nonatomic, nullable) NSString * testerABVersions;

- (NSString *)allExposedABVersions;

- (void)clearAll;


@property (nonatomic, assign) BOOL localTesterEnabled;
@property (nonatomic, assign) BOOL remoteTesterEnabled;

@property (nonatomic, assign) NSTimeInterval fetchInterval;

- (instancetype)initWithAppID:(NSString *)appID;

- (nullable id)getConfig:(NSString *)key defaultValue:(nullable id)defaultValue;
- (nullable NSString *)allABVersions;
/// key - value
- (NSDictionary *)allABTestConfigs;
/// `allABTestConfigs` version 2. Align with web and Android.
/// return raw key-value in server response.
- (NSDictionary *)allABTestConfigs2;

- (void)start;

- (void)fetchABTestingManually:(NSTimeInterval)timeout
                    completion:(void (^)(BOOL success, NSError * _Nullable error))completionHandler;


@end

NS_ASSUME_NONNULL_END
