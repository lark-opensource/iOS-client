//
//  HMDClassCoverageChecker.h
//  Pods
//
//  Created by kilroy on 2020/6/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDClassCoverageChecker : NSObject

- (void)activateByConfig:(NSTimeInterval)checkInterval;

- (void)invalidate;

@end

NS_ASSUME_NONNULL_END
