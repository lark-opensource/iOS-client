//
//  HMDUIFrozenTracker.h
//  AWECloudCommand
//
//  Created by 白昆仑 on 2020/3/23.
//

#import "HMDTracker.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDUIFrozenTracker : HMDTracker

- (void)didDetectUIFrozenWithData:(NSDictionary *)data;

@end

NS_ASSUME_NONNULL_END
