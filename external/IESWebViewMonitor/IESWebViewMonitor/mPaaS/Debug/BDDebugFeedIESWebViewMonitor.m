//
//  BDDebugFeedIESWebViewMonitor.m
//  IESWebViewMonitor
//
//  Created on 2020/4/10.
//

#import "BDDebugFeedIESWebViewMonitor.h"
#import "BDDebugTestWebView.h"
#import "BDDebugIESWebViewMonitorViewController.h"
#import "IESLiveWebViewMonitor.h"
#import "IESLiveDefaultSettingModel.h"
#import <BDDebugTool/BDDebugFeedLoader.h>
#import <BDStartUp/BDStartUpGaia.h>

BDAppAddDebugFeedFunction() {
    [BDDebugFeedLoader addDebugFeed:[BDDebugFeedIESWebViewMonitor new]];
    
    [IESLiveWebViewMonitor startWithClasses:[NSSet setWithObject:[BDDebugTestWebView class]]
                                       settings:[[IESLiveDefaultSettingModel defaultModel] toDic]];
}

@implementation BDDebugFeedIESWebViewMonitor

- (instancetype)init {
    self = [super init];
    if (self) {
        self.title = @"IESWebViewMonitor示例";
        self.navigateBlock = ^(BDDebugFeedModel *feed, UINavigationController *navigate) {
            BDDebugIESWebViewMonitorViewController *vc  = [BDDebugIESWebViewMonitorViewController new];
            [navigate pushViewController:vc animated:YES];
        };
    }
    
    return self;
}

@end

