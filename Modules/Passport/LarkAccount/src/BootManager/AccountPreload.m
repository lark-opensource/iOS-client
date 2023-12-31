//
//  AccountPreload.m
//  LarkAccount
//
//  Created by ZhaoKejie on 2022/12/6.
//

#import <Foundation/Foundation.h>
#import <LarkAccount-Swift.h>
#import "AccountPreload.h"

@implementation AccountPreload

+ (void)load {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [LKAccountPreload preload];
    });
}

@end
