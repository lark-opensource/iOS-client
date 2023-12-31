//
//  HMDNetworkProvider.h
//  Heimdallr
//
//  Created by 王佳乐 on 2019/1/21.
//

NS_ASSUME_NONNULL_BEGIN

@protocol HMDNetworkProvider <NSObject>

- (NSDictionary *)reportHeaderParams;
- (nullable NSDictionary *)reportCommonParams;
- (BOOL)enableBackgroundUpload;

@optional
- (nullable NSString *)reportPerformanceURL;
- (nullable NSString *)reportPerformancePath;
- (nullable NSString *)reportPerformanceURLPath;
- (nullable NSString *)transformedURLStringFrom:(nullable NSString *)original;

@end

NS_ASSUME_NONNULL_END
