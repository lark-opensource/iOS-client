//
//  HMDWeakProxy.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#import <Foundation/Foundation.h>

@interface HMDWeakProxy : NSProxy
@property (nonatomic, weak, readonly) id target;
+ (instancetype)proxyWithTarget:(id)target;
- (void)retainTarget;
- (void)releaseTarget;

@end

