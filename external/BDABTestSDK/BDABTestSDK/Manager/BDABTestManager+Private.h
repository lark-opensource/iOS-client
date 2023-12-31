//
//  BDABTestManager.h
//  ABSDKDemo
//
//  Created by bytedance on 2018/7/24.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "BDABTestManager.h"

@interface BDABTestManager (PrivateEX)

/**
 BDABTestManager单例

 @return BDABTestManager单例
 */
+ (instancetype)sharedManager;

- (void)doLog:(NSString *)log;

@end
