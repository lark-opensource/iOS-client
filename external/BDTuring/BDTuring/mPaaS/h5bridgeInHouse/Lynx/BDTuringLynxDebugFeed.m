//
//  BDTuringLynxDebugFeed.m
//  BDTuring
//
//  Created by yanming.sysu on 2021/2/8.
//

#import "BDTuringLynxDebugFeed.h"
#import "BDDebugFeedTuring.h"
#import "BDTuringLynxViewController.h"
#import "BDTuringLynxPlugin.h"

@interface BDTuringLynxDebugFeed()

+ (NSArray<BDDebugSectionModel *> *)feeds;

@end

BDAppAddDebugFeedFunction() {
    [BDDebugFeedTuring sharedInstance].lynxFeed = [BDTuringLynxDebugFeed feeds];
}

@implementation BDTuringLynxDebugFeed

+ (NSArray<BDDebugSectionModel *> *)feeds {
    
    [BDTuringLynxPlugin registerAllBDTuringBridge];
    
    NSMutableArray<BDDebugSectionModel *> *sections = [NSMutableArray new];
    
    [sections addObject:({
        BDDebugSectionModel *model = [BDDebugSectionModel new];
        model.title = @"LynxBridge测试";
        NSMutableArray<BDDebugFeedModel *> *feeds = [NSMutableArray new];
        
        [feeds addObject:({
            BDDebugFeedModel *model = [BDDebugFeedModel new];
            model.title = @"加载LynxBridge测试";
            model.navigateBlock = ^(BDDebugFeedModel * _Nonnull feed, UINavigationController * _Nonnull navigate) {
                BDTuringLynxViewController *vc = [BDTuringLynxViewController new];
                [navigate pushViewController:vc animated:YES];
            };
            model;
        })];

        model.feeds = feeds;
        model;
    })];
    
    return sections;
}

@end
