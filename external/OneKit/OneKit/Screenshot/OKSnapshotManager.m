//
//  OKSnapshotManager.m
//  OKSnapshotScrollDemo
//
//  Created by TonyReet on 2020/4/30.
//  Copyright © 2020 TonyReet. All rights reserved.
//

#import "OKSnapshotManager.h"
@implementation OKSnapshotManager

static OKSnapshotManager *_manager = nil;

+ (OKSnapshotManager *)defaultManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[OKSnapshotManager alloc]init];

        [_manager initData];
    });
    return _manager;
}

- (void )initData{
    self.maxScreenCount = 50;
    self.maxImageSize = 4096 * 4096;
    self.delayTime = 0.3;
}

@end
