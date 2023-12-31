//
//  BDDebugFeedTTKitchen.m
//  BDStartUp
//
//  Created by bob on 2020/3/30.
//

#import "BDDebugFeedTTKitchen.h"

#import <BDDebugTool/BDDebugTextResultViewController.h>
#import <BDDebugTool/BDDebugFeedLoader.h>
#import <BDStartUp/BDDebugStartUpTask.h>

#import "TTKitchenStartUpTask.h"
#import "TTKitchen.h"
#import "TTKitchenBrowserViewController.h"

static NSString * const kTTBDStartUpMPaasTest = @"bus_inhouse_test";

TTRegisterKitchenFunction() {
    TTKitchenRegisterBlock(^{
        TTKConfigInt(kTTBDStartUpMPaasTest, @"test", -1);
    });
}

BDAppAddDebugFeedFunction() {
    if (![TTKitchenStartUpTask sharedInstance].enabled) {
        return;
    }
    [BDDebugFeedLoader addDebugFeed:[BDDebugFeedTTKitchen new]];
    [[BDDebugStartUpTask sharedInstance] addCheckBlock:^NSString * {
        if ([TTKitchenStartUpTask sharedInstance].settingsHost == nil) {
            return @"TTKitchen";
        }
        
        return nil;
    }];
}

@implementation BDDebugFeedTTKitchen

- (instancetype)init {
    self = [super init];
    if (self) {
        self.title = @"TTKitchen内测功能";
        self.navigateBlock = ^(BDDebugFeedModel *feed, UINavigationController *navigate) {
            [TTKitchenBrowserViewController showInViewController:navigate];
        };
    }
    
    return self;
}

@end
