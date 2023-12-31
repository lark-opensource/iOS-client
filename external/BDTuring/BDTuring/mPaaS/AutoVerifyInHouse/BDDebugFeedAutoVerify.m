//
//  BDDebugFeedAutoVerify.m
//  BDTuring
//
//  Created by yanming.sysu on 2020/9/10.
//

#import "BDDebugFeedAutoVerify.h"
#import "BDDebugFeedTuring.h"
#import "BDTuringConfig.h"
#import "BDTuring.h"
#import "BDTNetworkManager.h"
#import "NSData+BDTuring.h"
#import "NSDictionary+BDTuring.h"
#import "NSString+BDTuring.h"
#import "BDTuringUtility.h"
#import "BDAutoVerifyViewController.h"
#import "BDFullAutoVerifyViewController.h"
#import <BDDebugTool/BDDebugFeedModel.h>

@interface BDDebugFeedAutoVerify()

+ (NSArray<BDDebugSectionModel *> *)feeds;

@end

BDAppAddDebugFeedFunction() {
    [BDDebugFeedTuring sharedInstance].autoverifyFeed = [BDDebugFeedAutoVerify feeds];
}

@implementation BDDebugFeedAutoVerify

+ (NSArray<BDDebugSectionModel *> *)feeds {
    NSMutableArray<BDDebugSectionModel *> *sections = [NSMutableArray new];
    
    [sections addObject:({
        BDDebugSectionModel *model = [BDDebugSectionModel new];
        model.title = @"无感验证测试";
        NSMutableArray<BDDebugFeedModel *> *feeds = [NSMutableArray new];
        
        [feeds addObject:({
            BDDebugFeedModel *model = [BDDebugFeedModel new];
            model.title = @"加载无感验证页面";
            model.navigateBlock = ^(BDDebugFeedModel * _Nonnull feed, UINavigationController * _Nonnull navigate) {
                BDAutoVerifyViewController *vc = [BDAutoVerifyViewController new];
                [navigate pushViewController:vc animated:YES];
            };
            model;
        })];
        
        [feeds addObject:({
            BDDebugFeedModel *model = [BDDebugFeedModel new];
            model.title = @"加载完全无感验证页面";
            model.navigateBlock = ^(BDDebugFeedModel * _Nonnull feed, UINavigationController * _Nonnull navigate) {
                BDFullAutoVerifyViewController *vc = [BDFullAutoVerifyViewController new];
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
