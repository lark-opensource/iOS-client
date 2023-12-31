//
//  HMDEvilMethodServiceProtocol.h
//  Heimdallr-a8835012
//
//  Created by bytedance on 2022/9/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HMDEvilMethodServiceProtocol <NSObject>

@required
- (BOOL)enableCollectFrameDrop;
- (void)startCollectFrameDrop;
- (void)endCollectFrameDropWithHitch:(NSTimeInterval)hitch isScrolling:(BOOL)isScrolling;

@end

NS_ASSUME_NONNULL_END
