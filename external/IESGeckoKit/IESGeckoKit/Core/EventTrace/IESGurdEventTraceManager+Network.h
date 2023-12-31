//
//  IESGurdEventTraceManager+Network.h
//  BDAssert
//
//  Created by 陈煜钏 on 2020/7/28.
//

#import "IESGurdEventTraceManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdTraceNetworkInfo : NSObject

@property (nonatomic, copy) NSString *method;

@property (nonatomic, copy) NSString *URLString;

@property (nonatomic, copy) NSDictionary *params;

@property (nonatomic, strong) id responseObject;

@property (nonatomic, strong) NSError *error;

@property (nonatomic, strong) NSDate *startDate;

@property (nonatomic, strong) NSDate *endDate;

+ (instancetype)infoWithMethod:(NSString *)method
                     URLString:(NSString *)URLString
                        params:(NSDictionary *)params;

@end

@interface IESGurdEventTraceManager (Network)

+ (void)traceNetworkWithInfo:(IESGurdTraceNetworkInfo *)networkInfo;

+ (NSArray<IESGurdTraceNetworkInfo *> *)allNetworkInfos;

@end

NS_ASSUME_NONNULL_END
