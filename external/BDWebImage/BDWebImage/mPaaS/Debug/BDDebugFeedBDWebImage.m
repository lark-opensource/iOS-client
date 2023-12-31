//
//  BDDebugFeedBDWebImage.m
//  BDWebImage
//
//  Created on 2020/4/10.
//

#import "BDDebugFeedBDWebImage.h"
#import "BDWebImageStartUpTask.h"
#import <BDDebugTool/BDDebugFeedLoader.h>
#import <BDStartUp/BDStartUpGaia.h>
#import "BDRootViewController.h"

BDAppAddDebugFeedFunction() {
    if (![BDWebImageStartUpTask sharedInstance].enabled) {
        return;
    }
    [BDDebugFeedLoader addDebugFeed:[BDDebugFeedBDWebImage new]];
    
}

@implementation BDDebugFeedBDWebImage

- (instancetype)init {
    self = [super init];
    if (self) {
        self.title = @"图片库BDWebImage示例";
        self.navigateBlock = ^(BDDebugFeedModel *feed, UINavigationController *navigate) {
            BDRootViewController *result = [BDRootViewController new];
            [navigate pushViewController:result animated:YES];
        };
    }
    
    return self;
}


@end

