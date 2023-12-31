//
//  IESGeckoDemoViewController.m
//  IESGeckoKit_Example
//
//  Created by 陈煜钏 on 2020/7/16.
//  Copyright © 2020 Fang Wei. All rights reserved.
//

#import "IESGeckoDemoViewController.h"
#import "IESForestViewController.h"
#import "IESGeckoFileMD5Hash.h"
#import "IESGurdKitUtil.h"
#import "IESGurdPushViewController.h"

#import <IESGeckoKit/IESGeckoKit.h>
#import <IESGeckoKit/IESGurdKit+Experiment.h>
#import <IESGeckoKit/IESGeckoKit+Private.h>
#import <IESGeckoKit/IESGurdPatch.h>

#import <Gaia/GAIAEngine.h>

static NSString * const kIESGurdAccessKeyAwemeBoe = @"37d5588e463f49ff4c69f54280b99b95";
static NSString * const kIESGurdAccessKeyAwemeTest = @"2d15e0aa4fe4a5c91eb47210a6ddf467";
static NSString * const kIESGurdAccessKeyAwemeProd = @"2373bbcf94c1b893dad48961d0a2d086";
static NSString * const kIESGeckoAnotherDemoAceessKey = @"41b29fed859bc76f8cea9bccb4f7b808";

NSString *kIESGurdAccessKeyDebug = kIESGurdAccessKeyAwemeTest;

typedef NS_ENUM(NSInteger, IESGurdDebugEnv) {
    IESGurdDebugEnvBoe = 0,
    IESGurdDebugEnvPpe = 1,
    IESGurdDebugEnvTest = 2,
    IESGurdDebugEnvProd = 3,
};

static NSInteger kDebugEnv = IESGurdDebugEnvTest;

IESGurdKitRegisterAccesskeyFunction() {
    [IESGurdKit registerAccessKey:kIESGeckoAnotherDemoAceessKey SDKVersion:@"1.0.0"];
}

@interface IESGeckoDemoViewController ()

@property (nonatomic, copy) NSArray<UIButton *> *buttons;

@end

@implementation IESGeckoDemoViewController

+(void)testGaia {
    IESGurdKitRegisterAccesskeyMethod;
    [IESGurdKit addCustomParamsForAccessKey:kIESGeckoAnotherDemoAceessKey
                               customParams:@{@"test_key": @"test_value"}];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initEnv];
    
    [IESGurdKit registerAccessKey:kIESGeckoAnotherDemoAceessKey SDKVersion:@"1.0.0"];
    [IESGurdKit fetchSettings];
    [IESGurdKit registerAccessKey:kIESGurdAccessKeyDebug];
    
    [self setupSubviews];
    
    [IESGurdKit addCacheWhitelistWithAccessKey:kIESGurdAccessKeyDebug channels:@[@"appcard"]];

    [IESGurdKit lockChannel:@"test" channel:@"test"];
    [IESGurdKit unlockChannel:@"test" channel:@"test"];
    
//    IESGurdKit.availableStorageFull = 1000 * 1000;
//    IESGeckoKit.availableStoragePatch = 1000 * 1000;
//    [IESGurdKit addLowStorageWhiteList:kIESGeckoDemoAccessKey groups:nil channels:nil];
//    [IESGurdKit addLowStorageWhiteList:kIESGeckoDemoAccessKey groups:@[@"high_priority"] channels:@[@"gln_test"]];
}

- (void)initEnv {
    if (kDebugEnv == IESGurdDebugEnvBoe) {
        kIESGurdAccessKeyDebug = kIESGurdAccessKeyAwemeBoe;
        IESGurdKitInstance.requestHeaderFieldBlock = ^() {
            return @{
                @"X-Use-Boe": @"1",
                @"X-Tt-Env": @"boe_gecko_query_v6",
            };
        };
        IESGurdKitInstance.domain = @"gecko3.zijieapi.com.boe-gateway.byted.org";
        IESGurdKitInstance.schema = @"http";
    } else if (kDebugEnv == IESGurdDebugEnvPpe) {
        IESGurdKitInstance.requestHeaderFieldBlock = ^() {
            return @{
                @"X-Use-Ppe": @"1",
                @"X-Tt-Env": @"",
            };
        };
    } else if (kDebugEnv == IESGurdDebugEnvProd) {
        kIESGurdAccessKeyDebug = kIESGurdAccessKeyAwemeProd;
    }
}

- (void)setupSubviews
{
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *syncResourcesButton = [self buttonWithTitle:@"Sync Resources" action:@selector(syncResources)];
    UIButton *applyResourcesButton = [self buttonWithTitle:@"Apply Resources" action:@selector(applyResources)];
    UIButton *cleanCacheButton = [self buttonWithTitle:@"Clean cache" action:@selector(cleanCache)];
    UIButton *showDebugPageButton = [self buttonWithTitle:@"Show Debug Page" action:@selector(showDebugPage)];
    UIButton *showAquamanPageButton = [self buttonWithTitle:@"Show Aquaman Page" action:@selector(showAquamanPage)];
    UIButton *showGDMPageButton = [self buttonWithTitle:@"Show GDM Page" action:@selector(showGDMPage)];
    UIButton *testExpiredClean = [self buttonWithTitle:@"Test expired clean" action:@selector(testExpiredClean)];
    UIButton *testBytePatchButton = [self buttonWithTitle:@"Test BytePatch" action:@selector(testBytePatch)];
    UIButton *testForestButton = [self buttonWithTitle:@"Test Forest" action:@selector(testForest)];
    UIButton *testPushButton = [self buttonWithTitle:@"Test Push" action:@selector(testPush)];
    
    self.buttons = @[ syncResourcesButton,
                      applyResourcesButton,
                      cleanCacheButton,
                      showDebugPageButton,
                      showAquamanPageButton,
                      showGDMPageButton,
                      testExpiredClean,
                      testBytePatchButton,
                      testForestButton,
                      testPushButton
    ];
    for (UIButton *button in self.buttons) {
        [self.view addSubview:button];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGFloat buttonWidth = 200.f;
    CGFloat buttonHeight = 44.f;
    CGFloat buttonVerticalMargin = 20.f;
    
    NSInteger buttonCount = self.buttons.count;
    CGFloat buttonOriginX = (CGRectGetWidth(self.view.frame) - buttonWidth) / 2;
    CGFloat buttonOriginY = (CGRectGetHeight(self.view.frame) - buttonCount * buttonHeight - (buttonCount - 1) * buttonVerticalMargin) / 2;
    for (UIButton *button in self.buttons) {
        button.frame = CGRectMake(buttonOriginX, buttonOriginY, buttonWidth, buttonHeight);
        buttonOriginY += (buttonVerticalMargin + buttonHeight);
    }
}

- (UIButton *)buttonWithTitle:(NSString *)title action:(SEL)action
{
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectZero];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    button.layer.borderWidth = 1.f;
    button.layer.cornerRadius = 4.f;
    button.titleLabel.font = [UIFont systemFontOfSize:15];
    return button;
}

- (void)showToast:(NSString *)toast succeed:(BOOL)succeed
{
    UIView *view = self.view;
    
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectZero];
    containerView.backgroundColor = succeed ?
    [UIColor colorWithRed:60.f / 255.f green:179.f / 255.f blue:113.f / 255.f alpha:1.f] :
    [UIColor colorWithRed:240.f / 255.f green:128.f / 255.f blue:128.f / 255.f alpha:1.f];
    [view addSubview:containerView];
    
    UILabel *toastLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    toastLabel.text = toast;
    toastLabel.font = [UIFont systemFontOfSize:14];
    toastLabel.textColor = [UIColor whiteColor];
    toastLabel.textAlignment = NSTextAlignmentCenter;
    toastLabel.numberOfLines = 0;
    [containerView addSubview:toastLabel];
    
    CGFloat containerWidth = CGRectGetWidth(self.view.frame);
    CGFloat toastLabelMargin = 12.f;
    CGFloat maxWidth = containerWidth - toastLabelMargin * 2;
    CGSize fitSize = [toastLabel sizeThatFits:CGSizeMake(maxWidth, CGFLOAT_MAX)];
    
    toastLabel.frame = CGRectMake(toastLabelMargin, toastLabelMargin, maxWidth, fitSize.height);
    containerView.frame = CGRectMake(0, 0, containerWidth, fitSize.height + toastLabelMargin * 2);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [containerView removeFromSuperview];
    });
}

#pragma mark - Feature

- (void)syncResources
{
    IESGurdSyncStatusDictionaryBlock completion = ^(BOOL succeed, IESGurdSyncStatusDict dict) {
        NSLog(@"syncResources");
        [self showToast:[NSString stringWithFormat:@"Sync Resources %@", succeed ? @"Successfully" : @"Failed"]
                succeed:succeed];
    };
//    [IESGurdKit syncResourcesWithParamsBlock:^(IESGurdFetchResourcesParams * _Nonnull params) {
//        params.accessKey = kIESGurdAccessKeyDebug;
//        params.groupName = @"gecko_test";
//        params.forceRequest = YES;
//        params.disableThrottle = YES;
//        params.retryDownload = YES;
//        params.pollingPriority = IESGurdPollingPriorityLevel1;
//    } completion:completion];
//
//    [IESGurdKit syncResourcesWithParamsBlock:^(IESGurdFetchResourcesParams * _Nonnull params) {
//        params.accessKey = kIESGurdAccessKeyDebug;
//        params.channels = @[ @"webcast_douyin" ];
//        params.downloadPriority = IESGurdDownloadPriorityHigh;
//        params.retryDownload = NO;
//    } completion:nil];
    
    [IESGurdKit syncResourcesWithParamsBlock:^(IESGurdFetchResourcesParams * _Nonnull params) {
        params.accessKey = kIESGurdAccessKeyDebug;
        params.channels = @[ @"yhw_test" ];
        params.downloadPriority = IESGurdDownloadPriorityHigh;
        params.retryDownload = NO;
        params.modelActivePolicy = IESGurdPackageModelActivePolicyMatchLazy;
//        params.requestWhenHasLocalVersion = YES;
    } completion:completion];
    
    [IESGurdKit dataForPath:@"test_path" accessKey:kIESGurdAccessKeyDebug channel:@"yhw_test"];
}

- (void)applyResources
{
    [IESGurdKit applyInactivePackages:^(BOOL succeed, IESGurdSyncStatus status) {
        NSLog(@"applyResources");
        [self showToast:[NSString stringWithFormat:@"Apply Resources %@ (%zd)", succeed ? @"Successfully" : @"Failed", status]
                succeed:succeed];
    }];
}

- (void)cleanCache
{
    [IESGurdKit clearCacheExceptWhitelist];
}

- (void)testExpiredClean
{
    IESGurdKit.clearExpiredCacheEnabled = YES;
    IESGurdKit.expiredTargetGroups = @{kIESGurdAccessKeyDebug: @"normal"};
    [IESGurdKit clearExpiredCache:0 cleanType:0 completion:nil];
}

- (void)showDebugPage
{
    if ([self.delegate respondsToSelector:@selector(showDebugPageWithNavigationController:)]) {
        [self.delegate showDebugPageWithNavigationController:self.navigationController];
    }
}

- (void)showAquamanPage
{
    if ([self.delegate respondsToSelector:@selector(showAquamanPageWithNavigationController:)]) {
        [self.delegate showAquamanPageWithNavigationController:self.navigationController];
    }
}

- (void)showGDMPage
{
    if ([self.delegate respondsToSelector:@selector(showGDMPage)]) {
        [self.delegate showGDMPage];
    }
}

- (void)testBytePatch
{
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *root = [bundlePath stringByAppendingPathComponent:@"bytepatch_test"];
    NSString *patchDir = [root stringByAppendingPathComponent:@"patchs_dir_old2"];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:patchDir error:nil];
//    NSArray *files = @[@"appcard.zst", @"aweme_welfare_tos.zst"];
    for (NSString *file in files) {
        NSString *fullpath = [patchDir stringByAppendingPathComponent:file];
        if (![file hasSuffix:@".zst"]) {
            NSLog(@"file name error");
            continue;
        }
        NSString *channel = [file substringToIndex:[file length] - 4];
        NSLog(@"start patch channel:%@", channel);
        
        NSString *src = [NSString pathWithComponents:@[root, @"dirs_old2", channel, channel]];
        NSString *realDir = [NSString pathWithComponents:@[root, @"dirs_new", channel, channel]];
        NSString *dest = [NSTemporaryDirectory() stringByAppendingPathComponent:@"bytepatch_test"];
        NSString *patch = [NSTemporaryDirectory() stringByAppendingPathComponent:@"bytepatch_test_patch.zip"];
        
        NSString *msg = nil;
        if (!decompressFile(fullpath, patch, &msg)) {
            IESGurdPatch *bytepatch = [[IESGurdPatch alloc] init];
            NSError *error = nil;
            if (![bytepatch patch:src dest:dest patch:patch error:&error]) {
                NSLog(@"bytepatch error: %@", error);
            }
            if (![IESGurdPatch checkFileMD5InDirs:dest dir2:realDir]) {
                NSLog(@"check md5 failed, channel:%@", channel);
            };
        } else {
            NSLog(@"zstd decompress error: %@", msg);
        }
    }
}

- (void)testForest
{
    IESForestViewController *controller = [[IESForestViewController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)testPush
{
    IESGurdPushViewController *controller = [[IESGurdPushViewController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
}

@end
