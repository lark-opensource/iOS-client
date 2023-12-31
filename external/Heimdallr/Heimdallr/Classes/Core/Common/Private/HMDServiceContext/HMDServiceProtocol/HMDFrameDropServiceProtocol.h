//
//  HMDFrameDropServiceProtocol.h
//  Heimdallr-a8835012
//
//  Created by bytedance on 2022/9/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HMDFrameDropServiceProtocol <NSObject>

@required
- (BOOL)enableFrameDropService;
- (nullable NSDictionary *)getCustomFilterTag;

@end

NS_ASSUME_NONNULL_END
