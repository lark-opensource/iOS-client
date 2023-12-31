//
//  HMDWebViewMonitor.h
//  Heimdallr
//
//  Created by zhangyuzhong on 2021/12/2.
//

#import <Foundation/Foundation.h>



@interface HMDWebViewMonitor : NSObject

+ (nonnull instancetype)sharedMonitor;

- (void)start;
- (void)stop;

@end


