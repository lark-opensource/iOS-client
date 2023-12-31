//
//  HMDConfigFetcher.h
//  Heimdallr
//
//  Created by Nickyo on 2023/5/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class HMDNetworkReqModel;
@class HMDConfigFetchRequest;
@class HMDConfigFetcher;

@protocol HMDConfigFetchDelegate <NSObject>

@required
- (BOOL)configFetcher:(HMDConfigFetcher *)fetcher finishRequestSuccess:(NSDictionary *)jsonDict penetrateParams:(id _Nullable)penetrateParams forAppID:(NSString *)appID;

@end

@protocol HMDConfigFetchDataSource <NSObject>

@required
- (BOOL)checkConfigIsOutOfDate;

- (NSArray<NSString *> * _Nullable)fetchRequestAppIDList;

- (HMDConfigFetchRequest * _Nullable)fetchRequestForAppID:(NSString *)appID atIndex:(NSUInteger)index;

- (NSUInteger)maxRetryCountForAppID:(NSString *)appID;

@end

@interface HMDConfigFetchRequest: NSObject

@property (nonnull,  nonatomic, strong) HMDNetworkReqModel *request;
@property (nullable, nonatomic, strong) id penetrateParams;

@end

@interface HMDConfigFetcher : NSObject

@property (nullable, nonatomic, weak) id<HMDConfigFetchDelegate> delegate;
@property (nullable, nonatomic, weak) id<HMDConfigFetchDataSource> dataSource;

- (void)asyncFetchRemoteConfig:(BOOL)force;

- (void)setAutoUpdateInterval:(NSTimeInterval)timeInterval forAppID:(NSString *)appID;

@end

NS_ASSUME_NONNULL_END
