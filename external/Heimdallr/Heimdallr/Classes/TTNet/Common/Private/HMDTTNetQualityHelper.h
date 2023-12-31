//
//  HMDNetConnectionTypeWatch.h
//  Heimdallr
//
//  Created by zhangxiao on 2021/3/1.
//

#import "HeimdallrModule.h"
#import "HMDNetQualityProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDTTNetQualityHelper : NSObject

@property (nonatomic, weak) id<HMDNetQualityProtocol> delegate;

+ (instancetype)sharedInstance;

- (void)registerQualityDelegate:(id <HMDNetQualityProtocol>)delegate;

- (void)start;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
