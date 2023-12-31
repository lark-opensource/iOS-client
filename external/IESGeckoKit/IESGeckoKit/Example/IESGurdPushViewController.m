#import "IESGurdPushViewController.h"
#import "IESGurdByteSyncMessageManager.h"

extern NSString *kIESGurdAccessKeyDebug;

@interface IESGurdPushViewController ()

@property (nonatomic, copy) NSArray<UIButton *> *buttons;

@end

@implementation IESGurdPushViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *testClearButton = [self buttonWithTitle:@"Push Clear" action:@selector(testClear)];
    UIButton *testDownloadButton = [self buttonWithTitle:@"Push Download" action:@selector(testDownload)];
    UIButton *testSyncButton = [self buttonWithTitle:@"Push Sync" action:@selector(testSync)];

    self.buttons = @[
        testClearButton,
        testDownloadButton,
        testSyncButton
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

- (void)testClear
{
    
}

- (void)testDownload
{
    NSMutableDictionary *model = [NSMutableDictionary dictionary];
    model[@"channel"] = @"yhw_test";
    model[@"version"] = @(267118);
    model[@"id"] = @(267118);
    model[@"md5"] = @"6027a14408ebd2038986d4b62712b253";
    model[@"package_type"] = 0;
    NSMutableDictionary *url = [NSMutableDictionary dictionary];
    model[@"url"] = url;
    url[@"scheme"] = @"http";
    url[@"uri"] = @"/obj/ies-fe-gecko-cn/1f23376be60570a03a3fb95bcddb5c8f_zstd";
    url[@"domains"] = @[@"tosv.boe.byted.org"];
    
    [IESGurdByteSyncMessageManager handleMessageDictionary:@{
        @"sync_task_id": @(1),
        @"msg_type": @(3),
        @"timestamp": @([[NSDate date] timeIntervalSince1970] * 1000),
        @"data": @{
            @"download_info": @{kIESGurdAccessKeyDebug: @[model]}
        }
    }];
}

- (void)testSync
{
    NSMutableDictionary *config = [NSMutableDictionary dictionary];
    config[@"target_chs"] = @[@"yhw_test"];
    config[@"group"] = @"";
    config[@"custom_keys"] = @[];
    
    [IESGurdByteSyncMessageManager handleMessageDictionary:@{
        @"sync_task_id": @(1),
        @"msg_type": @(1),
        @"timestamp": @([[NSDate date] timeIntervalSince1970] * 1000),
        @"data": @{
            @"check_update_info": @{
                @"config":@{kIESGurdAccessKeyDebug: config}
            }
        }
    }];
}

@end
