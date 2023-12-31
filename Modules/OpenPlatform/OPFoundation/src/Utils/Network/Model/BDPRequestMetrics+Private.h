//
//  BDPRequestMetrics+Private.h
//  Timor
//
//  Created by 傅翔 on 2019/7/30.
//

#import "BDPRequestMetrics.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPRequestMetrics ()

@property (nonatomic, assign) NSInteger dns;
@property (nonatomic, assign) NSInteger tcp;
@property (nonatomic, assign) NSInteger ssl;
@property (nonatomic, assign) NSInteger send;
@property (nonatomic, assign) NSInteger wait;
@property (nonatomic, assign) NSInteger receive;

@property (nonatomic, assign) BOOL reuseConnect;

@property (nonatomic, assign) NSInteger requestTime;

@end

NS_ASSUME_NONNULL_END
