//
//  BDTuringH5bridgeDebugFeed.m
//  BDTuring
//
//  Created by yanming.sysu on 2021/2/9.
//

#import "BDTuringH5bridgeDebugFeed.h"
#import "BDDebugFeedTuring.h"
#import "BDTuringH5bridgeViewController.h"
#import "BDTuringGlobalH5Bridge.h"

@interface BDTuringH5bridgeDebugFeed()

+ (NSArray<BDDebugSectionModel *> *)feeds;

@end

BDAppAddDebugFeedFunction() {
    [BDDebugFeedTuring sharedInstance].h5bridgeFeed = [BDTuringH5bridgeDebugFeed feeds];
}

@implementation BDTuringH5bridgeDebugFeed

+ (NSArray<BDDebugSectionModel *> *)feeds {
    
    [BDTuringGlobalH5Bridge registerAllBridges];
    
    NSMutableArray<BDDebugSectionModel *> *sections = [NSMutableArray new];
    
    [sections addObject:({
        BDDebugSectionModel *model = [BDDebugSectionModel new];
        model.title = @"h5 bridge测试";
        NSMutableArray<BDDebugFeedModel *> *feeds = [NSMutableArray new];
        
        [feeds addObject:({
            BDDebugFeedModel *model = [BDDebugFeedModel new];
            model.title = @"加载h5 bridge测试";
            model.navigateBlock = ^(BDDebugFeedModel * _Nonnull feed, UINavigationController * _Nonnull navigate) {
                BDTuringH5bridgeViewController *vc = [BDTuringH5bridgeViewController new];
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
