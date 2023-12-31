//
//  BDAutoTrackInspector.m
//  RangersAppLog
//
//  Created by bytedance on 6/28/22.
//

#import "BDAutoTrackInspector.h"

#import "BDAutoTrackDevEnv.h"
#import "BDAutoTrackInspector.h"
#import "BDAutoTrackDevLogger.h"
#import "BDAutoTrackDevEventController.h"
#import "BDAutoTrackUtilities.h"
#import "BDAutoTrack+Private.h"
#import "BDAutoTrackFileLogger.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrack+DevTools.h"
#import "BDAutoTrackABConfig.h"
#import "BDAutoTrackDevToolsHolder.h"

@interface BDAutoTrackInspector ()<UITabBarControllerDelegate> {
    
    UIView *trackTitleView;
    UILabel *labelAppId;
    UILabel *labelAppName;
    
}

@property (nonatomic, weak) BDAutoTrack *currentTracker;

@property (nonatomic, strong) BDAutoTrackDevLogger *logViewController;
@property (nonatomic, strong) BDAutoTrackDevEnv *envViewController;
@property (nonatomic, strong) BDAutoTrackDevEventController *eventViewController;

@end



@implementation BDAutoTrackInspector

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
        
    [self initNavigationItem];
    [self initNavigationTitleView];
    
    if (!self.currentTracker) {
        BDAutoTrack *sharedTracker = [BDAutoTrack sharedTrack];
        if (sharedTracker.config.devToolsEnabled) {
            self.currentTracker = sharedTracker;
            [[BDAutoTrackDevToolsHolder shared] updateTracker:self.currentTracker];
        }
    }
    
    self.logViewController = [BDAutoTrackDevLogger new];
    self.envViewController = [BDAutoTrackDevEnv new];
    self.eventViewController = [BDAutoTrackDevEventController new];
    
    self.delegate = self;
    
}


- (void)initTabBarItem
{
    BDAutoTrackDevEnv *env = self.envViewController;
    env.inspector = self;
    env.tabBarItem.title = @"基本信息";
    UIImage *envUnselectedImg = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"tab-env-unselected" ofType:@"png" inDirectory:@"RangersAppLogDevTools.bundle"]];
    UIImage *envImg = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"tab-env" ofType:@"png" inDirectory:@"RangersAppLogDevTools.bundle"]];
    env.tabBarItem.image = [[BDAutoTrackUtilities imageWithImage:envUnselectedImg scaledToSize:CGSizeMake(26.0f, 26.0f)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    env.tabBarItem.selectedImage = [[BDAutoTrackUtilities imageWithImage:envImg scaledToSize:CGSizeMake(26.0f, 26.0f)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    BDAutoTrackDevEventController *event = self.eventViewController;
    event.tabBarItem.title = @"事件";
    UIImage *eventUnselectedImg = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"tab-event-unselected" ofType:@"png" inDirectory:@"RangersAppLogDevTools.bundle"]];
    UIImage *eventImg = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"tab-event" ofType:@"png" inDirectory:@"RangersAppLogDevTools.bundle"]];
    event.tabBarItem.image = [[BDAutoTrackUtilities imageWithImage:eventUnselectedImg scaledToSize:CGSizeMake(26.0f, 26.0f)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    event.tabBarItem.selectedImage = [[BDAutoTrackUtilities imageWithImage:eventImg scaledToSize:CGSizeMake(26.0f, 26.0f)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    BDAutoTrackDevLogger *log = self.logViewController;
    log.inspector = self;
    log.tabBarItem.title = @"日志";
    UIImage *logUnselectedImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"tab-log-unselected" ofType:@"png" inDirectory:@"RangersAppLogDevTools.bundle"]];
    UIImage *logImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"tab-log" ofType:@"png" inDirectory:@"RangersAppLogDevTools.bundle"]];
    log.tabBarItem.image = [[BDAutoTrackUtilities imageWithImage:logUnselectedImage scaledToSize:CGSizeMake(26.0f, 26.0f)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    log.tabBarItem.selectedImage = [[BDAutoTrackUtilities imageWithImage:logImage scaledToSize:CGSizeMake(26.0f, 26.0f)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    NSArray *tabs = @[event, env, log];
    
    self.viewControllers = tabs;
    
//    [self.tabBar.items enumerateObjectsUsingBlock:^(UITabBarItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
//        UIViewController *controller = [tabs objectAtIndex:idx];
//        item.title = controller.tabBarItem.title;
//        item.image = controller.tabBarItem.image;
//    }];
    
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
//    NSLog(@">>> %@", item.title);
    BDAutoTrackDevToolsMonitor *monitor = [BDAutoTrackDevToolsHolder shared].monitor;
    if (self.envViewController.tabBarItem == item) {
        [monitor track:kBDAutoTrackDevToolsTabInfo];
    } else if (self.eventViewController.tabBarItem == item) {
        [monitor track:kBDAutoTrackDevToolsTabEvent];
    } else if (self.logViewController.tabBarItem == item) {
        [monitor track:kBDAutoTrackDevToolsTabLog];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateTitleView];
    [self initTabBarItem];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    BDAutoTrackDevToolsMonitor *monitor = [BDAutoTrackDevToolsHolder shared].monitor;
    [monitor track:kBDAutoTrackDevToolsOpen];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    BDAutoTrackDevToolsMonitor *monitor = [BDAutoTrackDevToolsHolder shared].monitor;
    [monitor track:kBDAutoTrackDevToolsClose];
}

- (void)updateTitleView
{
    labelAppId.text = self.currentTracker.config.appID;
    labelAppName.text = self.currentTracker.config.appName;
}


- (void)initNavigationItem
{
    // Do any additional setup after loading the view.
    UIView *leftItemView = [[UIView alloc] init];
    leftItemView.frame = CGRectMake(0, 0, 24.0f, 24.0f);
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"close" ofType:@"png" inDirectory:@"RangersAppLogDevTools.bundle"]] forState:UIControlStateNormal];
    button.frame = leftItemView.bounds;
    [leftItemView addSubview:button];
    [button addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:leftItemView];
    
    UIView *rightItemView = [[UIView alloc] init];
    rightItemView.frame = CGRectMake(0, 0, 24.0f, 24.0f);
    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [rightButton setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"send" ofType:@"png" inDirectory:@"RangersAppLogDevTools.bundle"]] forState:UIControlStateNormal];
    rightButton.frame = leftItemView.bounds;
    [rightItemView addSubview:rightButton];
    [rightButton addTarget:self action:@selector(share) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightItemView];
    
//    [[UIBarButtonItem alloc] initWithImage:closeImage style:(UIBarButtonItemStylePlain) target:self action:@selector(dismiss)];
//    UIImage *addImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"plus" ofType:@"png" inDirectory:@"RangersAppLogDevTools.bundle"]];
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:addImage style:(UIBarButtonItemStylePlain) target:self action:@selector(addBDTrackInstance)];
    
    [BDAutoTrackUtilities ignoreAutoTrack:button];
    [BDAutoTrackUtilities ignoreAutoTrack:rightButton];
}

- (void)initNavigationTitleView
{
    labelAppId = [[UILabel alloc] init];
    labelAppId.textAlignment = NSTextAlignmentCenter;
    labelAppId.font = [UIFont systemFontOfSize:16.0f weight:UIFontWeightBold];
    labelAppName = [[UILabel alloc] init];
    labelAppName.textAlignment = NSTextAlignmentCenter;
    labelAppName.font = [UIFont systemFontOfSize:14.0f weight:UIFontWeightRegular];
    trackTitleView = [[UIView alloc] init];
    
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"arrow-down" ofType:@"png" inDirectory:@"RangersAppLogDevTools.bundle"];
    UIButton *arrow = [UIButton buttonWithType:UIButtonTypeCustom];
    [arrow setImage:[UIImage imageWithContentsOfFile:path] forState:UIControlStateNormal];
    
    [trackTitleView addSubview:labelAppId];
    [trackTitleView addSubview:labelAppName];
    [trackTitleView addSubview:arrow];
    [arrow addTarget:self action:@selector(selectTrackers) forControlEvents:UIControlEventTouchUpInside];
    
    labelAppId.translatesAutoresizingMaskIntoConstraints = NO;
    labelAppName.translatesAutoresizingMaskIntoConstraints = NO;
    arrow.translatesAutoresizingMaskIntoConstraints = NO;
    
    [trackTitleView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[appId]-[arrow(20)]-0-|" options:0 metrics:@{} views:@{@"appId":labelAppId,@"arrow":arrow}]];
    [trackTitleView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[appName]-[arrow(20)]-0-|" options:0 metrics:@{} views:@{@"appName":labelAppName,@"arrow":arrow}]];
    [trackTitleView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[appId(22)]-0-[appName(14)]-0-|" options:0 metrics:@{} views:@{@"appName":labelAppName,@"appId":labelAppId}]];
    [trackTitleView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[arrow(20)]-|" options:0 metrics:@{} views:@{@"arrow":arrow}]];
    self.navigationItem.titleView = trackTitleView;
//    self.navigationItem.titleView.intrinsicContentSize = CGSizeMake(200, 40);
    
    [BDAutoTrackUtilities ignoreAutoTrack:arrow];

}

#pragma mark - action

- (void)selectTrackers
{
    UIAlertController *actionSheet =[UIAlertController alertControllerWithTitle:@"请选择 BDAutoTrack 实例" message:nil preferredStyle:(UIAlertControllerStyleActionSheet)];
    NSArray<BDAutoTrack *> *trackers = [BDAutoTrack allTrackers];
    [trackers enumerateObjectsUsingBlock:^(BDAutoTrack * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!obj.config.devToolsEnabled) {
            return;
        }
        
        NSString *selectItem = [NSString stringWithFormat:@"%@-%@",obj.config.appID, obj.config.appName];
        UIAlertAction *action = [UIAlertAction actionWithTitle:selectItem style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            self.currentTracker = obj;
            [self updateTitleView];
            [[BDAutoTrackDevToolsHolder shared] updateTracker:self.currentTracker];
        }];
        [actionSheet addAction:action];
    }];
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }]];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
    
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)share
{
    //TODO make file zip
    
    UIAlertController *sheet =[UIAlertController alertControllerWithTitle:@"Sharing Information" message:nil preferredStyle:(UIAlertControllerStyleActionSheet)];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Enviroment" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
    
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            NSString *path = [self.envViewController dump];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (path.length > 0) {
                    [self shareFile:[NSURL fileURLWithPath:path]];
                }
            });
        });
        
        
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Logs" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            [[BDAutoTrackDevToolsHolder shared].monitor track:kBDAutoTrackDevToolsShareLog];
            
            __block BDAutoTrackFileLogger* logger;
            BDAutoTrack *track = self.currentTracker;
            [[track.logger loggers] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:BDAutoTrackFileLogger.class]) {
                    logger = obj;
                    *stop = YES;
                }
            }];
            
            NSString *path = [logger dump];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (path.length > 0) {
                    [self shareFile:[NSURL fileURLWithPath:path]];
                }
            });
            
        });
    }]];
    
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:(UIAlertActionStyleCancel) handler:^(UIAlertAction * _Nonnull action) {

    }]];
    [self.navigationController presentViewController:sheet animated:YES completion:nil];
    
}

- (void)shareFile:(NSURL *)filePath
{
    NSURL *fileUrl = filePath;
    NSArray*activityItems = @[fileUrl];
    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activity.completionWithItemsHandler = ^(UIActivityType _Nullable activityType,BOOL completed,NSArray*_Nullable returnedItems,NSError*_Nullable activityError) {
        [[NSFileManager defaultManager] removeItemAtURL:filePath error:nil];
    };
    [self.navigationController presentViewController:activity animated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
