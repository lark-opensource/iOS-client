//
//  ACCPOIServiceProtocol.h
//  Pods
//
//  Created by chengfei xiao on 2019/7/29.
//  POI相关协议

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCPOIInfoModelProtocol <NSObject>
@property (nonatomic, copy) NSString *poiId;
@property (nonatomic, copy) NSString *poiName;
@property (nonatomic, copy) NSString *poiAddress;
@property (nonatomic, copy) NSString *distance;
@end

@protocol ACCPOIServiceProtocol <NSObject>

- (void)searchPOIWithKeyword:(NSString *)keyword searchType:(NSInteger)searchType completion:(void(^)(NSArray<id<ACCPOIInfoModelProtocol>> *result, NSString *keyword, BOOL hasMore))completion;

- (void)loadMorePOIWithKeyword:(NSString *)keyword searchType:(NSInteger)searchType completion:(void(^)(NSArray<id<ACCPOIInfoModelProtocol>> *result, NSString *keyword, BOOL hasMore))completion;

@end

NS_ASSUME_NONNULL_END
