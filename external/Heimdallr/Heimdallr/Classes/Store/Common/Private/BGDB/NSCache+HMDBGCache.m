//
//  NSCache+HMDBGCache.m
//  BGFMDB
//
//  Created by biao on 2017/10/17.
//  Copyright © 2017年 Biao. All rights reserved.
//

#import "NSCache+HMDBGCache.h"

static NSCache* keyCaches;
@implementation NSCache (HMDBGCache)

+(instancetype)hmdbg_cache{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keyCaches = [NSCache new];
    });
    return keyCaches;
}

@end
