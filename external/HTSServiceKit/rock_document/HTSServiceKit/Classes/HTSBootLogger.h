//
//  HTSBootLogger.h
//  HTSBootLoader
//
//  Created by Huangwenchen on 2019/11/16.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTSBootNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface HTSBootLogger : NSObject

+ (instancetype)sharedLogger;

@property (readonly) NSArray * mainMetrics;
@property (readonly) NSArray * backgroundMetrics;

- (void)logName:(NSString *)name duration:(NSTimeInterval)duration;

@end

NS_ASSUME_NONNULL_END
