//
//  ACCMomentDebugViewController.m
//  Pods
//
//  Created by Pinka on 2020/6/17.
//

#if INHOUSE_TARGET

#import "ACCMomentDebugViewController.h"
#import <CreativeKit/ACCMacros.h>
#import "ACCMomentService.h"
#import "ACCMomentCIMManager.h"
#import "ACCMomentDebugMomentListViewController.h"
#import "ACCMomentDebugLogConsoleViewController.h"
#import "ACCMomentATIMManager.h"
#import <EffectPlatformSDK/EffectPlatform.h>
#import <EffectSDK_iOS/RequirementDefine.h>
#import <SSZipArchive/SSZipArchive.h>
#import <AWELazyRegister/AWELazyRegisterDebugTools.h>
#import <AWEDebugTools/AWEDebugToolsModuleInterface.h>
#import <AWERouter/AWERouter.h>

AWELazyRegisterDebugTools()
{
    AWEDebugBaseModel *model = [[AWEDebugBaseModel alloc] init];
    model.cellName = AWEDebugToolsDebugString(@"时光故事测试页面", @"Moment Test Page");
    model.cellType = AWEDebugCellTypeNormal;
    model.didSelectBlock = ^(UITableViewCell<AWEDebugTableViewCellProtocol> *cell) {
        ACCMomentDebugViewController *vc = [[ACCMomentDebugViewController alloc] init];
        [AWERouterTopViewController().navigationController pushViewController:vc animated:YES];
    };
    [GET_PROTOCOL(AWEDebugToolsModuleInterface) registerDebugToolsWithCategory:AWEDebugToolsCategoryCommonTools
                                                                         model:model];
}

@interface ACCMomentDebugViewController ()

@property (nonatomic, strong) VEAIMomentAlgorithm *aiAlgorithm;

@property (nonatomic, strong) ACCMomentCIMManager *cimManager;

@property (strong, nonatomic) UITextView *logTextView;

@property (nonatomic, strong) NSOperationQueue *calculateQueue;

@property (nonatomic, strong) UIDocumentInteractionController *exportController;

@end

@implementation ACCMomentDebugViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[ACCMomentService shareInstance] updateConfigModel];
    [[ACCMomentService shareInstance] cleanScanResultNotExistWithCompletion:^(ACCMomentMediaScanManagerCompleteState state, ACCMomentMediaAsset *lastAsset, NSError * _Nullable error) {
        ;
    }];
    
    self.title = @"Moment Test Page";
    self.view.backgroundColor = [UIColor whiteColor];
    
    _calculateQueue = [[NSOperationQueue alloc] init];
    _calculateQueue.maxConcurrentOperationCount = 1;
    
    CGFloat const perBtnHeight = 40, gap = 20;
    CGFloat const perBtnWidth = (self.view.frame.size.width - gap*4) / 3.0;
    CGFloat lastXOffset = 0.0, lastYOffset = 84 + 40;
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.backgroundColor = [UIColor lightGrayColor];
        btn.frame = CGRectMake(lastXOffset+gap, lastYOffset, perBtnWidth, perBtnHeight);
        [btn setTitle:@"扫描全部" forState:UIControlStateNormal];
        lastXOffset = CGRectGetMaxX(btn.frame);
        [btn addTarget:self
                action:@selector(onScanAction:)
      forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:btn];
    }
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.backgroundColor = [UIColor lightGrayColor];
        btn.frame = CGRectMake(lastXOffset+gap, lastYOffset, perBtnWidth, perBtnHeight);
        [btn setTitle:@"获取BIM" forState:UIControlStateNormal];
        lastXOffset = CGRectGetMaxX(btn.frame);
        [btn addTarget:self
                action:@selector(onImageBIMAction:)
      forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:btn];
    }
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.backgroundColor = [UIColor lightGrayColor];
        btn.frame = CGRectMake(lastXOffset+gap, lastYOffset, perBtnWidth, perBtnHeight);
        [btn setTitle:@"Moments" forState:UIControlStateNormal];
        lastXOffset = CGRectGetMaxX(btn.frame);
        lastYOffset = CGRectGetMaxY(btn.frame);
        [btn addTarget:self
                action:@selector(onJumpToAIMList:)
      forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:btn];
    }
    lastYOffset += gap;
    lastXOffset = 0.0;
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.backgroundColor = [UIColor lightGrayColor];
        btn.frame = CGRectMake(lastXOffset+gap, lastYOffset, perBtnWidth, perBtnHeight);
        [btn setTitle:@"清空数据库" forState:UIControlStateNormal];
        lastXOffset = CGRectGetMaxX(btn.frame);
        [btn addTarget:self
                action:@selector(onClearDatabaseAction:)
      forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:btn];
    }
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.backgroundColor = [UIColor lightGrayColor];
        btn.frame = CGRectMake(lastXOffset+gap, lastYOffset, perBtnWidth, perBtnHeight);
        [btn setTitle:@"People" forState:UIControlStateNormal];
        lastXOffset = CGRectGetMaxX(btn.frame);
        [btn addTarget:self
                action:@selector(onPeopleAction:)
      forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:btn];
    }
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.backgroundColor = [UIColor lightGrayColor];
        btn.frame = CGRectMake(lastXOffset+gap, lastYOffset, perBtnWidth, perBtnHeight);
        [btn setTitle:@"Tag" forState:UIControlStateNormal];
        lastXOffset = CGRectGetMaxX(btn.frame);
        lastYOffset = CGRectGetMaxY(btn.frame);
        [btn addTarget:self
                action:@selector(onTagAction:)
      forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:btn];
    }
    lastYOffset += gap;
    lastXOffset = 0.0;
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.backgroundColor = [UIColor lightGrayColor];
        btn.frame = CGRectMake(lastXOffset+gap, lastYOffset, perBtnWidth, perBtnHeight);
        [btn setTitle:@"检查视频打分" forState:UIControlStateNormal];
        lastXOffset = CGRectGetMaxX(btn.frame);
        [btn addTarget:self
                action:@selector(onCheckVideoScoresAction:)
      forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:btn];
    }
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.backgroundColor = [UIColor lightGrayColor];
        btn.frame = CGRectMake(lastXOffset+gap, lastYOffset, perBtnWidth, perBtnHeight);
        [btn setTitle:@"SimId" forState:UIControlStateNormal];
        lastXOffset = CGRectGetMaxX(btn.frame);
        [btn addTarget:self
                action:@selector(onSimIdAction:)
      forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:btn];
    }
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.backgroundColor = [UIColor lightGrayColor];
        btn.frame = CGRectMake(lastXOffset+gap, lastYOffset, perBtnWidth, perBtnHeight);
        [btn setTitle:@"CIM重扫" forState:UIControlStateNormal];
        lastXOffset = CGRectGetMaxX(btn.frame);
        lastYOffset = CGRectGetMaxY(btn.frame);
        [btn addTarget:self
                action:@selector(onCIMIdAction:)
      forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:btn];
    }
    lastYOffset += gap;
    lastXOffset = 0.0;
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.backgroundColor = [UIColor lightGrayColor];
        btn.frame = CGRectMake(lastXOffset+gap, lastYOffset, perBtnWidth, perBtnHeight);
        [btn setTitle:@"AIM JSON" forState:UIControlStateNormal];
        lastXOffset = CGRectGetMaxX(btn.frame);
        [btn addTarget:self
                action:@selector(onAIMJSONAction:)
      forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:btn];
    }
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.backgroundColor = [UIColor lightGrayColor];
        btn.frame = CGRectMake(lastXOffset+gap, lastYOffset, perBtnWidth, perBtnHeight);
        [btn setTitle:@"BAT模型检查" forState:UIControlStateNormal];
        lastXOffset = CGRectGetMaxX(btn.frame);
        [btn addTarget:self
                action:@selector(onBTChcekAction:)
      forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:btn];
    }
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.backgroundColor = [UIColor lightGrayColor];
        btn.frame = CGRectMake(lastXOffset+gap, lastYOffset, perBtnWidth, perBtnHeight);
        [btn setTitle:@"停止扫描" forState:UIControlStateNormal];
        lastXOffset = CGRectGetMaxX(btn.frame);
        lastYOffset = CGRectGetMaxY(btn.frame);
        [btn addTarget:self
                action:@selector(onStopScanAction:)
      forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:btn];
    }
    lastYOffset += gap;
    lastXOffset = 0.0;
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.backgroundColor = [UIColor lightGrayColor];
        btn.frame = CGRectMake(lastXOffset+gap, lastYOffset, perBtnWidth, perBtnHeight);
        [btn setTitle:@"后台扫描" forState:UIControlStateNormal];
        lastXOffset = CGRectGetMaxX(btn.frame);
        [btn addTarget:self
                action:@selector(onBackgroundScanAction:)
      forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:btn];
    }
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.backgroundColor = [UIColor lightGrayColor];
        btn.frame = CGRectMake(lastXOffset+gap, lastYOffset, perBtnWidth, perBtnHeight);
        [btn setTitle:@"导出DB" forState:UIControlStateNormal];
        lastXOffset = CGRectGetMaxX(btn.frame);
        lastYOffset = CGRectGetMaxY(btn.frame);
        [btn addTarget:self
                action:@selector(onExportDBAction:)
      forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:btn];
    }
    
    {
        self.logTextView = [[UITextView alloc] initWithFrame:CGRectMake(20, lastYOffset+20, self.view.frame.size.width - 40.0, self.view.frame.size.height - lastYOffset - 20 - 20)];
        self.logTextView.layer.borderWidth = 1.0;
        self.logTextView.layer.borderColor = [UIColor blackColor].CGColor;
        self.logTextView.editable = NO;
        
        [self.view addSubview:self.logTextView];
    }
    
    VEAlgorithmConfig *config = [VEAlgorithmConfig new];
    config.configPath = @"{}";
    config.tempRecPath = @"";
    config.superParams = 0b11111101111;
    config.resourceFinder = [IESMMParamModule getResourceFinder];
    config.initType = VEAlgorithmInitTypeMoment;
    config.serviceCount = 1;
    
    self.aiAlgorithm = [[VEAIMomentAlgorithm alloc] initWithConfig:config];
    self.cimManager = [[ACCMomentCIMManager alloc] initWithDataProvider:[ACCMomentMediaDataProvider normalProvider]];
    self.cimManager.aiAlgorithm = self.aiAlgorithm;
}

- (BOOL)btd_prefersNavigationBarHidden
{
    return NO;
}

#pragma mark - Actions
- (void)onImageBIMAction:(UIButton *)sender
{
    ACCMomentDebugMomentListViewController *vc = [[ACCMomentDebugMomentListViewController alloc] init];
    vc.vcType = ACCMomentDebugMomentListViewControllerType_BIMList;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onScanAction:(UIButton *)sender
{
    @weakify(self);
    static CFAbsoluteTime ctime;
    ctime = CFAbsoluteTimeGetCurrent();
    self.logTextView.text = @"开始扫描";
    [ACCMomentService shareInstance].multiThreadOptimize = YES;
    [ACCMomentService shareInstance].scanQueueOperationCount = 5;
    [[ACCMomentService shareInstance]
     startForegroundMediaScanWithPerCallbackCount:5
     completion:^(ACCMomentMediaScanManagerCompleteState state, ACCMomentMediaAsset *lastAsset, NSError * _Nullable error) {
        if (state == ACCMomentMediaScanManagerCompleteState_AllCompleted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                @strongify(self);
                CFAbsoluteTime gap = CFAbsoluteTimeGetCurrent() - ctime;
                self.logTextView.text = [NSString stringWithFormat:@"扫描成功, cost time %f", gap];
            });
        }
    }];
}

- (void)onJumpToAIMList:(UIButton *)sender
{
    ACCMomentDebugMomentListViewController *vc = [[ACCMomentDebugMomentListViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onClearDatabaseAction:(UIButton *)sender
{
    [[ACCMomentMediaScanManager shareInstance] clearDatas];
    self.logTextView.text = @"清空数据库成功";
}

- (void)onPeopleAction:(UIButton *)sender
{
    ACCMomentDebugMomentListViewController *vc = [[ACCMomentDebugMomentListViewController alloc] init];
    vc.vcType = ACCMomentDebugMomentListViewControllerType_PeopleList;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onTagAction:(UIButton *)sender
{
    ACCMomentDebugMomentListViewController *vc = [[ACCMomentDebugMomentListViewController alloc] init];
    vc.vcType = ACCMomentDebugMomentListViewControllerType_TagList;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onCheckVideoScoresAction:(UIButton *)sender
{
    @weakify(self);
    [[ACCMomentMediaDataProvider normalProvider]
     loadBIMResultWithLimit:10000000 pageIndex:0 resultBlock:^(NSArray<ACCMomentBIMResult *> * _Nullable result, BOOL endFlag, NSError * _Nullable error) {
        NSMutableString *str = [[NSMutableString alloc] init];
         [result enumerateObjectsUsingBlock:^(ACCMomentBIMResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
             if (obj.mediaType == PHAssetMediaTypeVideo) {
                 if (obj.scoreInfos.count != (NSInteger)ceil(obj.duration)) {
                     [str appendFormat:@"id: %@\nscoreInfos_count: %lu\nduration:%f\n\n", obj.localIdentifier, (unsigned long)obj.scoreInfos.count, obj.duration];
                 }
             }
         }];
         
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            self.logTextView.text = str;
        });
    }];
}

- (void)onSimIdAction:(UIButton *)sender
{
    ACCMomentDebugMomentListViewController *vc = [[ACCMomentDebugMomentListViewController alloc] init];
    vc.vcType = ACCMomentDebugMomentListViewControllerType_SimIdList;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onCIMIdAction:(UIButton *)sender
{
    @weakify(self);
    CFAbsoluteTime ctime = CFAbsoluteTimeGetCurrent();
    [self.cimManager calculateCIMResult:^(VEAIMomentCIMResult * _Nonnull cimResult, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            CFAbsoluteTime gap = CFAbsoluteTimeGetCurrent() - ctime;
            self.logTextView.text = [NSString stringWithFormat:@"CIM成功, cost time %f", gap];
        });
    }];
}

- (void)onAIMJSONAction:(UIButton *)sender
{
    ACCMomentDebugLogConsoleViewController *vc = [[ACCMomentDebugLogConsoleViewController alloc] init];
    vc.logText = [[NSString alloc] initWithContentsOfFile:ACCMomentATIMManagerAIMConfigPath(@"moment") encoding:NSUTF8StringEncoding error:nil];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onBTChcekAction:(UIButton *)sender
{
    BOOL bim = [EffectPlatform isRequirementsDownloaded:@[@REQUIREMENT_MOMENT_TAG]];
    self.logTextView.text = [NSString stringWithFormat:@"BIM Model: %@\nAIM Model: %@\nTIM Model: %@",
                             bim? @"ok": @"fail",
                             [ACCMomentATIMManager shareInstance].aimIsReady? @"ok": @"fail",
                             [ACCMomentATIMManager shareInstance].timIsReady? @"ok": @"fail"];
}

- (void)onStopScanAction:(UIButton *)sender
{
    [[ACCMomentService shareInstance] stopMediaScan];
    self.logTextView.text = @"已经停止扫描";
}

- (void)onBackgroundScanAction:(UIButton *)sender
{
    CFAbsoluteTime ctime = CFAbsoluteTimeGetCurrent();
    self.logTextView.text = @"开始后台扫描";
    @weakify(self);
    [[ACCMomentService shareInstance] startBackgroundMediaScanWithCompletion:^(ACCMomentMediaScanManagerCompleteState state, ACCMomentMediaAsset *lastAsset, NSError * _Nullable error) {
        if (state == ACCMomentMediaScanManagerCompleteState_AllCompleted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                @strongify(self);
                CFAbsoluteTime gap = CFAbsoluteTimeGetCurrent() - ctime;
                self.logTextView.text = [NSString stringWithFormat:@"扫描成功, cost time %f", gap];
            });
        }
    }];
}

- (void)onExportDBAction:(UIButton *)sender
{
    self.logTextView.text = @"导出中……";
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *dataDir = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"ACCMomentMedia"];
        NSString *zipFile = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"moment_export.zip"];
        
        [[NSFileManager defaultManager] removeItemAtPath:zipFile error:nil];
        BOOL flag = [SSZipArchive createZipFileAtPath:zipFile withContentsOfDirectory:dataDir];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.logTextView.text = flag? @"导出成功": @"导出失败";
            
            if (flag) {
                UIDocumentInteractionController *dc = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:zipFile]];
                self.exportController = dc;
                [dc presentOpenInMenuFromRect:self.navigationController.view.bounds inView:self.navigationController.view animated:YES];
            }
        });
    });
}

@end

#endif
