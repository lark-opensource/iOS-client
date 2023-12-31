//
//  CADisplayLink+ACCBlock.h
//  Pods
//
//  Created by xuzichao on 2019/2/18.
//

#import <QuartzCore/QuartzCore.h>

@interface CADisplayLink (ACCBlock)

+ (CADisplayLink *)acc_displayLinkWithBlock:(void (^)(CADisplayLink *dispLink))block;

@end
